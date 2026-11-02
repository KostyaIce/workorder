#!/bin/bash
# Native Qt/C++ Android build. No PySide/buildozer application sources.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:-debug}"
BUILD_AAB=0
BUILD_STARTED_AT="$(date '+%Y-%m-%d %H:%M:%S %Z')"
BUILD_STARTED_EPOCH="$(date +%s)"
case "$MODE" in
    -h|--help)
        echo 'Usage: bash prod_build/build_android_apk.sh [debug|release|aab]'
        echo 'Qt/C++ mobile APK or AAB. SDK, NDK and build-tools are auto-detected.'
        echo 'Release keys: ../workorder-signing/key.properties.'
        echo 'Overrides: QT_ROOT, QT_ANDROID_PATH, QT_HOST_PATH, ANDROID_SDK_ROOT, ANDROID_NDK_ROOT, ANDROID_BUILD_TOOLS_VERSION, SIGNING_DIR, BUILD_DIR.'
        exit 0 ;;
    debug) CONFIG=Debug ;;
    release) CONFIG=Release ;;
    aab|release-aab) MODE=release; CONFIG=Release; BUILD_AAB=1 ;;
    *) echo "ERROR: Unknown mode: $MODE" >&2; exit 1 ;;
esac
[ $# -le 1 ] || { echo 'ERROR: Too many arguments' >&2; exit 1; }

OS="$(uname -s)"
case "$OS" in
    Darwin)
        HOST=macos
        SDK_CANDIDATES=("$HOME/Library/Android/sdk")
        ;;
    Linux)
        HOST=gcc_64
        SDK_CANDIDATES=("$HOME/Android/Sdk" "$HOME/Android/sdk")
        ;;
    *)
        echo "ERROR: Unsupported OS: $OS" >&2
        exit 1
        ;;
esac

QT_ROOT="${QT_ROOT:-$HOME/Qt/${QT_VERSION:-6.8.3}}"
QT_ANDROID_PATH="${QT_ANDROID_PATH:-$QT_ROOT/android_arm64_v8a}"
QT_HOST_PATH="${QT_HOST_PATH:-$QT_ROOT/$HOST}"
TOOLCHAIN="$QT_ANDROID_PATH/lib/cmake/Qt6/qt.toolchain.cmake"
[ -f "$TOOLCHAIN" ] || { echo "ERROR: Missing Qt toolchain: $TOOLCHAIN" >&2; exit 1; }
[ -d "$QT_HOST_PATH" ] || { echo "ERROR: Missing Qt host tools: $QT_HOST_PATH" >&2; exit 1; }

for openssl_lib in libssl_3.so libcrypto_3.so; do
    [ -f "$ROOT/cpp/android/libs/arm64-v8a/$openssl_lib" ] || {
        echo "ERROR: Missing Android OpenSSL library: cpp/android/libs/arm64-v8a/$openssl_lib" >&2
        exit 1
    }
done

CMAKE_BIN="$(command -v cmake || true)"
NINJA_BIN="$(command -v ninja || true)"
[ -n "$CMAKE_BIN" ] || { echo 'ERROR: Missing cmake' >&2; exit 1; }
[ -n "$NINJA_BIN" ] || { echo 'ERROR: Missing ninja' >&2; exit 1; }

java_major()
{
    "$1/bin/java" -version 2>&1 \
        | awk -F'"' '/version/ { split($2, parts, "."); if (parts[1] == "1") print parts[2]; else print parts[1]; exit }'
}

is_compatible_java_home()
{
    [ -n "${1:-}" ] && [ -x "$1/bin/java" ] || return 1
    local major
    major="$(java_major "$1")"
    [ -n "$major" ] && [ "$major" -ge 17 ] && [ "$major" -le 21 ]
}

find_java_home()
{
    local candidate
    local candidates=()
    [ -n "${JAVA_HOME:-}" ] && candidates+=("$JAVA_HOME")
    if [ "$OS" = "Darwin" ]; then
        for version in 17 21; do
            candidate="$(/usr/libexec/java_home -v "$version" 2>/dev/null || true)"
            [ -n "$candidate" ] && candidates+=("$candidate")
        done
        candidates+=("/opt/homebrew/opt/openjdk@17" "/opt/homebrew/opt/openjdk@21")
    else
        candidates+=(
            "/usr/lib/jvm/java-17-openjdk-amd64"
            "/usr/lib/jvm/java-17-openjdk"
            "/usr/lib/jvm/java-21-openjdk-amd64"
            "/usr/lib/jvm/java-21-openjdk"
        )
    fi
    for candidate in "${candidates[@]}"; do
        if is_compatible_java_home "$candidate"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

if DETECTED_JAVA_HOME="$(find_java_home)"; then
    export JAVA_HOME="$DETECTED_JAVA_HOME"
    export PATH="$JAVA_HOME/bin:$PATH"
else
    echo "WARNING: JDK 17/21 not found; the Android Gradle build may fail with a newer JDK" >&2
fi

is_valid_sdk()
{
    [ -n "${1:-}" ] && { [ -d "$1/ndk" ] || [ -x "$1/platform-tools/adb" ]; }
}

find_sdk()
{
    local candidate
    for candidate in "${ANDROID_SDK_ROOT:-}" "${ANDROID_HOME:-}" "${SDK_CANDIDATES[@]}"; do
        if is_valid_sdk "$candidate"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
if ! is_valid_sdk "$ANDROID_SDK_ROOT"; then
    ANDROID_SDK_ROOT="$(find_sdk)" || {
        echo 'ERROR: Android SDK not found. Set ANDROID_SDK_ROOT.' >&2
        exit 1
    }
fi
export ANDROID_SDK_ROOT

is_valid_ndk()
{
    [ -n "${1:-}" ] && [ -f "$1/build/cmake/android.toolchain.cmake" ]
}

find_ndk()
{
    local sdk="$1"
    local dir
    local candidates=()
    for dir in "$sdk"/ndk/* "$sdk"/ndk-bundle; do
        if is_valid_ndk "$dir"; then
            candidates+=("$dir")
        fi
    done
    [ "${#candidates[@]}" -gt 0 ] || return 1
    printf '%s\n' "${candidates[@]}" | sort -V 2>/dev/null | tail -n 1
}

ANDROID_NDK_ROOT="${ANDROID_NDK_ROOT:-}"
if ! is_valid_ndk "$ANDROID_NDK_ROOT"; then
    if [ -n "$ANDROID_NDK_ROOT" ]; then
        echo "WARNING: ignoring invalid ANDROID_NDK_ROOT=$ANDROID_NDK_ROOT" >&2
    fi
    ANDROID_NDK_ROOT="$(find_ndk "$ANDROID_SDK_ROOT")" || {
        echo 'ERROR: Android NDK not found. Set ANDROID_NDK_ROOT.' >&2
        exit 1
    }
fi
export ANDROID_NDK_ROOT
NDK_TOOLCHAIN="$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake"

is_valid_build_tools()
{
    [ -n "${1:-}" ] && [ -x "$1/apksigner" ] && [ -x "$1/zipalign" ]
}

find_build_tools()
{
    local sdk="$1"
    local dir
    local candidates=()
    for dir in "$sdk"/build-tools/*; do
        if is_valid_build_tools "$dir"; then
            candidates+=("$dir")
        fi
    done
    [ "${#candidates[@]}" -gt 0 ] || return 1
    printf '%s\n' "${candidates[@]}" | sort -V 2>/dev/null | tail -n 1
}

BUILD_TOOLS_DIR=""
if [ -n "${ANDROID_BUILD_TOOLS_VERSION:-}" ]; then
    candidate="$ANDROID_SDK_ROOT/build-tools/$ANDROID_BUILD_TOOLS_VERSION"
    if is_valid_build_tools "$candidate"; then
        BUILD_TOOLS_DIR="$candidate"
    else
        echo "WARNING: Android build-tools $ANDROID_BUILD_TOOLS_VERSION not found, auto-detecting" >&2
    fi
fi
if [ -z "$BUILD_TOOLS_DIR" ]; then
    BUILD_TOOLS_DIR="$(find_build_tools "$ANDROID_SDK_ROOT")" || {
        echo 'ERROR: Android build-tools with apksigner/zipalign not found' >&2
        exit 1
    }
fi
ANDROID_BUILD_TOOLS_VERSION="$(basename "$BUILD_TOOLS_DIR")"
export ANDROID_BUILD_TOOLS_VERSION

BUILD_DIR="${BUILD_DIR:-$ROOT/build/android-cpp-$MODE}"

if [ -f "$BUILD_DIR/CMakeCache.txt" ]; then
    cached_ndk="$(grep -m1 '^ANDROID_NDK_ROOT:' "$BUILD_DIR/CMakeCache.txt" | cut -d= -f2- || true)"
    if [ -n "$cached_ndk" ] && [ "$cached_ndk" != "$ANDROID_NDK_ROOT" ]; then
        echo "Detected stale NDK in CMake cache: $cached_ndk"
        echo "Removing stale build directory: $BUILD_DIR"
        rm -rf "$BUILD_DIR"
    fi
fi

ANDROID_SDK_FOR_BUILD="$ANDROID_SDK_ROOT"
if [ -d "$ANDROID_SDK_ROOT/platforms" ]; then
    has_preview=false
    for platform_dir in "$ANDROID_SDK_ROOT"/platforms/*; do
        [ -e "$platform_dir" ] || continue
        platform_name="$(basename "$platform_dir")"
        if ! [[ "$platform_name" =~ ^android-[0-9]+$ ]]; then
            has_preview=true
        fi
    done
    if $has_preview; then
        SAFE_SDK="$BUILD_DIR/_android_sdk"
        rm -rf "$SAFE_SDK"
        mkdir -p "$SAFE_SDK/platforms"
        for entry in "$ANDROID_SDK_ROOT"/*; do
            [ -e "$entry" ] || continue
            [ "$(basename "$entry")" = "platforms" ] && continue
            ln -s "$entry" "$SAFE_SDK/$(basename "$entry")"
        done
        stable_platforms=0
        for platform_dir in "$ANDROID_SDK_ROOT"/platforms/*; do
            [ -e "$platform_dir" ] || continue
            platform_name="$(basename "$platform_dir")"
            if [[ "$platform_name" =~ ^android-[0-9]+$ ]] && [ -f "$platform_dir/android.jar" ]; then
                ln -s "$platform_dir" "$SAFE_SDK/platforms/$platform_name"
                stable_platforms=$((stable_platforms + 1))
            fi
        done
        if [ "$stable_platforms" -gt 0 ]; then
            ANDROID_SDK_FOR_BUILD="$SAFE_SDK"
            echo "Using stable Android platforms only: $ANDROID_SDK_FOR_BUILD"
        else
            echo "WARNING: no stable Android platform found, using original SDK" >&2
            rm -rf "$SAFE_SDK"
        fi
    fi
fi

TOOLS="$BUILD_TOOLS_DIR"
SIGNING_CERT_SHA256=""
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
    [ -x "$TOOLS/apksigner" ] && [ -x "$TOOLS/zipalign" ] || { echo "ERROR: Missing Android build tools: $TOOLS" >&2; exit 1; }
    command -v jarsigner >/dev/null || { echo 'ERROR: Missing jarsigner' >&2; exit 1; }
fi

echo "Build started: $BUILD_STARTED_AT"
echo "OS: $OS"
echo "Android SDK: $ANDROID_SDK_ROOT"
if [ "$ANDROID_SDK_FOR_BUILD" != "$ANDROID_SDK_ROOT" ]; then
    echo "Android SDK for build: $ANDROID_SDK_FOR_BUILD"
fi
echo "Android NDK: $ANDROID_NDK_ROOT"
echo "Build tools: $ANDROID_BUILD_TOOLS_VERSION"
if [ -n "${JAVA_HOME:-}" ]; then
    echo "Java: $JAVA_HOME"
fi
echo "Qt Android: $QT_ANDROID_PATH"
echo "Qt host: $QT_HOST_PATH"

"$CMAKE_BIN" -S "$ROOT/cpp" -B "$BUILD_DIR" -G Ninja \
    -DCMAKE_MAKE_PROGRAM="$NINJA_BIN" \
    -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
    -DQT_CHAINLOAD_TOOLCHAIN_FILE="$NDK_TOOLCHAIN" \
    -DQT_HOST_PATH="$QT_HOST_PATH" \
    -DANDROID_SDK_ROOT="$ANDROID_SDK_FOR_BUILD" \
    -DANDROID_NDK_ROOT="$ANDROID_NDK_ROOT" \
    -DANDROID_NDK="$ANDROID_NDK_ROOT" \
    -DCMAKE_ANDROID_NDK="$ANDROID_NDK_ROOT" \
    -DANDROID_ABI=arm64-v8a \
    -DCMAKE_BUILD_TYPE="$CONFIG" -DType=mobile -DQT_ANDROID_SIGN_APK=OFF
if [ "$BUILD_AAB" = 1 ]; then
    "$CMAKE_BIN" --build "$BUILD_DIR" --target WorkOrder_make_aab
    AAB_DIR="$BUILD_DIR/android-build/build/outputs/bundle/release"
    shopt -s nullglob
    AABS=("$AAB_DIR/"*.aab)
    [ "${#AABS[@]}" -eq 1 ] || { echo "ERROR: Expected one AAB in $AAB_DIR" >&2; exit 1; }
    OUTPUT="$BUILD_DIR/WorkOrder.aab"
    jarsigner -keystore "$STORE_FILE" -storepass "$STORE_PASSWORD" \
        -keypass "$KEY_PASSWORD" -signedjar "$OUTPUT" "${AABS[0]}" "$KEY_ALIAS"
    jarsigner -verify "$OUTPUT" >/dev/null
    SIGNING_CERT_SHA256="$(keytool -printcert -jarfile "$OUTPUT" 2>/dev/null \
        | awk -F': ' '/SHA256:/ { print $2; exit }')"
else
    "$CMAKE_BIN" --build "$BUILD_DIR" --target WorkOrder_make_apk
    APK_DIR="$BUILD_DIR/android-build/build/outputs/apk/$MODE"
    shopt -s nullglob
    APKS=("$APK_DIR/"*.apk)
    [ "${#APKS[@]}" -eq 1 ] || { echo "ERROR: Expected one APK in $APK_DIR" >&2; exit 1; }
    if [ "$MODE" = release ]; then
        OUTPUT="$BUILD_DIR/WorkOrder.apk"
    else
        OUTPUT="$BUILD_DIR/WorkOrder-debug.apk"
    fi
    if [ "$MODE" = release ]; then
        "$TOOLS/zipalign" -f -p 4 "${APKS[0]}" "$BUILD_DIR/aligned.apk"
        export WORKORDER_STORE_PASSWORD="$STORE_PASSWORD" WORKORDER_KEY_PASSWORD="$KEY_PASSWORD"
        "$TOOLS/apksigner" sign --ks "$STORE_FILE" --ks-key-alias "$KEY_ALIAS" \
            --ks-pass env:WORKORDER_STORE_PASSWORD --key-pass env:WORKORDER_KEY_PASSWORD \
            --out "$OUTPUT" "$BUILD_DIR/aligned.apk"
        "$TOOLS/apksigner" verify --verbose "$OUTPUT"
        SIGNING_CERT_SHA256="$("$TOOLS/apksigner" verify --print-certs "$OUTPUT" 2>/dev/null \
            | awk -F': ' '/certificate SHA-256 digest/ { print $2; exit }')"
    else
        cp "${APKS[0]}" "$OUTPUT"
    fi
fi

PACKAGE_NAME="$(awk -F'"' '/package="/ { print $2; exit }' "$ROOT/cpp/android/AndroidManifest.xml")"
[ -n "$PACKAGE_NAME" ] || PACKAGE_NAME="com.konstantin.workorder"
ADB_CMD="$ANDROID_SDK_ROOT/platform-tools/adb"
[ -x "$ADB_CMD" ] || ADB_CMD="adb"
BUILD_FINISHED_AT="$(date '+%Y-%m-%d %H:%M:%S %Z')"
BUILD_SECONDS=$(( $(date +%s) - BUILD_STARTED_EPOCH ))
ARTIFACT_SIZE="$(du -h "$OUTPUT" | awk '{ print $1 }')"

echo
echo "============================================================"
echo " СБОРКА ЗАВЕРШЕНА: $BUILD_FINISHED_AT"
echo " Старт: $BUILD_STARTED_AT"
echo " Длительность: ${BUILD_SECONDS}s"
if [ "$BUILD_AAB" = 1 ]; then
    echo " AAB: $OUTPUT ($ARTIFACT_SIZE)"
else
    echo " APK: $OUTPUT ($ARTIFACT_SIZE)"
fi
echo " Пакет: $PACKAGE_NAME"
if [ -n "$SIGNING_CERT_SHA256" ]; then
    echo " Подпись: release"
    echo " Сертификат SHA-256: $SIGNING_CERT_SHA256"
fi
echo
if [ "$BUILD_AAB" = 1 ]; then
    echo " Загрузите AAB в Google Play Console:"
    echo "   $OUTPUT"
else
    echo " Установить на устройство:"
    echo "   \"$ADB_CMD\" install -r \"$OUTPUT\""
    echo " Если Huawei пишет INSTALL_FAILED_ABORTED: User rejected permissions —"
    echo " разблокируйте экран, включите Developer options -> Install via USB"
    echo " и подтвердите установку на устройстве."
    echo " Запустить:"
    echo "   \"$ADB_CMD\" shell monkey -p $PACKAGE_NAME 1"
    echo " Проверить подключение:"
    echo "   \"$ADB_CMD\" devices"
    echo " Смотреть логи:"
    echo "   bash prod_build/android/logcat_workorder.sh"
fi
echo "============================================================"
