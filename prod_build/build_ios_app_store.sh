#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SIGNING_DIR="${SIGNING_DIR:-$PROJECT_ROOT/../workorder-signing}"
IOS_CERT_DIR="${IOS_CERT_DIR:-$SIGNING_DIR/ios}"
PROFILE="${IOS_PROFILE:-$IOS_CERT_DIR/WorkOrder_AppStore.mobileprovision}"
BUNDLE_ID="${BUNDLE_ID:-com.workorder}"
BUILD_DIR="${BUILD_DIR:-$PROJECT_ROOT/build/ios-app-store}"
QT_ROOT="${QT_ROOT:-$HOME/Qt/${QT_VERSION:-6.8.3}}"
QT_IOS_PATH="${QT_IOS_PATH:-$QT_ROOT/ios}"
QT_HOST_PATH="${QT_HOST_PATH:-$QT_ROOT/macos}"
case "${1:-}" in
    -h|--help)
        echo 'Usage: bash prod_build/build_ios_app_store.sh [--check]'
        echo 'App Store / TestFlight IPA. Signing: ../workorder-signing/ios.'
        echo 'Overrides: SIGNING_DIR, IOS_CERT_DIR, IOS_PROFILE, SIGN_IDENTITY (SHA-1), BUNDLE_ID, TEAM_ID, BUILD_DIR, QT_ROOT.'
        exit 0 ;;
    ''|--check) ;;
    *) echo "ERROR: Unknown argument: $1" >&2; exit 1 ;;
esac
[ $# -le 1 ] || { echo 'ERROR: Too many arguments' >&2; exit 1; }
for tool in cmake xcodebuild xcrun security python3; do
    command -v "$tool" >/dev/null || { echo "ERROR: Missing $tool" >&2; exit 1; }
done
xcrun --sdk iphoneos --show-sdk-version >/dev/null
TOOLCHAIN="$QT_IOS_PATH/lib/cmake/Qt6/qt.toolchain.cmake"
[ -f "$TOOLCHAIN" ] && [ -d "$QT_HOST_PATH" ] || { echo 'ERROR: Qt iOS/host tools missing' >&2; exit 1; }
[ -f "$PROFILE" ] || { echo "ERROR: Profile missing: $PROFILE. Import $IOS_CERT_DIR/distribution.p12 into Keychain too." >&2; exit 1; }
OPTIONS="$BUILD_DIR/ExportOptions.plist"
SIGNING="$(python3 "$SCRIPT_DIR/ios_signing.py" "$PROFILE" "$BUNDLE_ID" "$OPTIONS")"
read -r TEAM UUID IDENTITY <<<"$SIGNING"
echo "Signing prerequisites OK: team $TEAM, bundle $BUNDLE_ID"
[ "${1:-}" != --check ] || exit 0
cmake -S "$PROJECT_ROOT/cpp" -B "$BUILD_DIR" -G Xcode \
    -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" -DQT_HOST_PATH="$QT_HOST_PATH" \
    -DType=mobile -DWORKORDER_IOS_TEAM_ID="$TEAM" -DWORKORDER_IOS_BUNDLE_ID="$BUNDLE_ID"
ARCHIVE="$BUILD_DIR/WorkOrder.xcarchive"
EXPORT="$BUILD_DIR/export"
rm -rf "$ARCHIVE" "$EXPORT" "$BUILD_DIR/Release-iphoneos" "$BUILD_DIR/WorkOrder.ipa"
xcodebuild -project "$BUILD_DIR/WorkOrder.xcodeproj" -scheme WorkOrder \
    -configuration Release -destination 'generic/platform=iOS' -archivePath "$ARCHIVE" \
    DEVELOPMENT_TEAM="$TEAM" PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
    TARGETED_DEVICE_FAMILY=1 \
    CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="$IDENTITY" PROVISIONING_PROFILE_SPECIFIER="$UUID" archive
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath "$EXPORT" -exportOptionsPlist "$OPTIONS"
IPAS=("$EXPORT/"*.ipa)
[ -f "${IPAS[0]}" ] || { echo 'ERROR: Xcode did not create an IPA' >&2; exit 1; }
cp "${IPAS[0]}" "$BUILD_DIR/WorkOrder.ipa"
echo "IPA: $BUILD_DIR/WorkOrder.ipa"
echo 'Upload with Transporter for TestFlight / App Store.'
