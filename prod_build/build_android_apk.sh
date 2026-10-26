#!/bin/bash
# Native Qt/C++ Android build. No PySide/buildozer application sources.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:-debug}"
case "$MODE" in
    -h|--help)
        echo 'Usage: bash prod_build/build_android_apk.sh [debug|release]'
        echo 'Qt/C++ mobile APK. Release keys: ../workorder-signing/key.properties.'
        echo 'Overrides: QT_ROOT, QT_ANDROID_PATH, QT_HOST_PATH, ANDROID_SDK_ROOT, ANDROID_NDK_ROOT, ANDROID_BUILD_TOOLS_VERSION, SIGNING_DIR, BUILD_DIR.'
        exit 0 ;;
    debug) CONFIG=Debug ;;
    release) CONFIG=Release ;;
    *) echo "ERROR: Unknown mode: $MODE" >&2; exit 1 ;;
esac
[ $# -le 1 ] || { echo 'ERROR: Too many arguments' >&2; exit 1; }
QT_ROOT="${QT_ROOT:-$HOME/Qt/${QT_VERSION:-6.8.3}}"
QT_ANDROID_PATH="${QT_ANDROID_PATH:-$QT_ROOT/android_arm64_v8a}"
case "$(uname -s)" in
    Darwin) HOST=macos; SDK_DEFAULT="$HOME/Library/Android/sdk" ;;
    *) HOST=gcc_64; SDK_DEFAULT="$HOME/Android/Sdk" ;;
esac
QT_HOST_PATH="${QT_HOST_PATH:-$QT_ROOT/$HOST}"
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$SDK_DEFAULT}"
: "${ANDROID_NDK_ROOT:?Set ANDROID_NDK_ROOT to the NDK supported by your Qt version}"
BUILD_DIR="${BUILD_DIR:-$ROOT/build/android-cpp-$MODE}"
TOOLCHAIN="$QT_ANDROID_PATH/lib/cmake/Qt6/qt.toolchain.cmake"
[ -f "$TOOLCHAIN" ] || { echo "ERROR: Missing Qt toolchain: $TOOLCHAIN" >&2; exit 1; }
for tool in cmake ninja; do
    command -v "$tool" >/dev/null || { echo "ERROR: Missing $tool" >&2; exit 1; }
done
if [ "$MODE" = release ]; then
    SIGNING_DIR="${SIGNING_DIR:-$ROOT/../workorder-signing}"
    PROPERTIES="$SIGNING_DIR/key.properties"
    [ -f "$PROPERTIES" ] || { echo "ERROR: Missing $PROPERTIES" >&2; exit 1; }
    STORE_FILE= STORE_PASSWORD= KEY_ALIAS= KEY_PASSWORD=
    while IFS='=' read -r key value || [ -n "$key" ]; do
        value="${value%$'\r'}"
        case "$key" in
            storeFile) STORE_FILE="$value" ;;
            storePassword) STORE_PASSWORD="$value" ;;
            keyAlias) KEY_ALIAS="$value" ;;
            keyPassword) KEY_PASSWORD="$value" ;;
        esac
    done < "$PROPERTIES"
    [ -n "$STORE_FILE" ] && [ -n "$STORE_PASSWORD" ] && [ -n "$KEY_ALIAS" ] && [ -n "$KEY_PASSWORD" ] || {
        echo 'ERROR: key.properties requires storeFile, storePassword, keyAlias, keyPassword (key=value)' >&2; exit 1;
    }
    case "$STORE_FILE" in /*) ;; *) STORE_FILE="$SIGNING_DIR/$STORE_FILE" ;; esac
    [ -f "$STORE_FILE" ] || { echo "ERROR: Missing keystore: $STORE_FILE" >&2; exit 1; }
    : "${ANDROID_BUILD_TOOLS_VERSION:?Set ANDROID_BUILD_TOOLS_VERSION for release signing}"
    TOOLS="$ANDROID_SDK_ROOT/build-tools/$ANDROID_BUILD_TOOLS_VERSION"
    [ -x "$TOOLS/apksigner" ] && [ -x "$TOOLS/zipalign" ] || { echo "ERROR: Missing Android build tools: $TOOLS" >&2; exit 1; }
fi
cmake -S "$ROOT/cpp" -B "$BUILD_DIR" -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" -DQT_HOST_PATH="$QT_HOST_PATH" \
    -DANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" -DANDROID_NDK_ROOT="$ANDROID_NDK_ROOT" \
    -DCMAKE_ANDROID_NDK="$ANDROID_NDK_ROOT" -DANDROID_ABI=arm64-v8a \
    -DCMAKE_BUILD_TYPE="$CONFIG" -DType=mobile -DQT_ANDROID_SIGN_APK=OFF
cmake --build "$BUILD_DIR" --target WorkOrder_make_apk
APK_DIR="$BUILD_DIR/android-build/build/outputs/apk/$MODE"
shopt -s nullglob
APKS=("$APK_DIR/"*.apk)
[ "${#APKS[@]}" -eq 1 ] || { echo "ERROR: Expected one APK in $APK_DIR" >&2; exit 1; }
OUTPUT="$BUILD_DIR/WorkOrder-$MODE.apk"
if [ "$MODE" = release ]; then
    "$TOOLS/zipalign" -f -p 4 "${APKS[0]}" "$BUILD_DIR/aligned.apk"
    export WORKORDER_STORE_PASSWORD="$STORE_PASSWORD" WORKORDER_KEY_PASSWORD="$KEY_PASSWORD"
    "$TOOLS/apksigner" sign --ks "$STORE_FILE" --ks-key-alias "$KEY_ALIAS" \
        --ks-pass env:WORKORDER_STORE_PASSWORD --key-pass env:WORKORDER_KEY_PASSWORD \
        --out "$OUTPUT" "$BUILD_DIR/aligned.apk"
    "$TOOLS/apksigner" verify --verbose "$OUTPUT"
else
    cp "${APKS[0]}" "$OUTPUT"
fi
echo "APK: $OUTPUT"
