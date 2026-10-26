#!/bin/bash
set -euo pipefail

# Local device build. Same signing path as Planer's prod_build/build_ios.sh:
# the team is stored in the Xcode project and signing is automatic.
# The app installs only on devices registered for that team.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
QT_VERSION="${QT_VERSION:-6.8.3}"
QT_ROOT="${QT_ROOT:-$HOME/Qt/$QT_VERSION}"
QT_IOS_PATH="${QT_IOS_PATH:-$QT_ROOT/ios}"
QT_HOST_PATH="${QT_HOST_PATH:-$QT_ROOT/macos}"
BUNDLE_ID="${BUNDLE_ID:-com.workorder}"
# Same developer team as Planer's local iOS script. Override with TEAM_ID.
TEAM_ID="${TEAM_ID:-74FAM6RATH}"
BUILD_DIR="${BUILD_DIR:-$PROJECT_ROOT/build/ios-local}"
ARCHIVE_PATH="$BUILD_DIR/WorkOrder.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
EXPORT_METHOD="${1:-development}"

usage()
{
    cat <<EOF
Usage: bash prod_build/build_ios.sh [development|ad-hoc]

Local install on registered devices. This does not make an App Store build.

  development   Apple Development signature (default)
  ad-hoc        Apple Distribution signature, still only registered devices

The team is ${TEAM_ID}, the same value Planer stores in its Xcode project.
Override it with TEAM_ID=XXXXXXXXXX.
A connected iPhone is added to the development profile when Xcode can sign in.
Without a connected phone, the IPA installs only on devices already registered.
EOF
}

case "$EXPORT_METHOD" in
    -h|--help)
        usage
        exit 0
        ;;
    development|debugging)
        EXPORT_METHOD="debugging"
        OUTPUT_IPA="$BUILD_DIR/WorkOrder-development.ipa"
        ;;
    ad-hoc|release-testing)
        EXPORT_METHOD="release-testing"
        OUTPUT_IPA="$BUILD_DIR/WorkOrder-ad-hoc.ipa"
        ;;
    *)
        echo "ERROR: Unsupported export method: $EXPORT_METHOD" >&2
        usage >&2
        exit 1
        ;;
esac

if ! [[ "$TEAM_ID" =~ ^[A-Z0-9]{10}$ ]]; then
    echo "ERROR: TEAM_ID must be 10 characters, got '$TEAM_ID'" >&2
    exit 1
fi

for tool in cmake xcodebuild python3; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "ERROR: $tool is required" >&2
        exit 1
    }
done

TOOLCHAIN="$QT_IOS_PATH/lib/cmake/Qt6/qt.toolchain.cmake"
if [ ! -f "$TOOLCHAIN" ]; then
    echo "ERROR: Qt iOS toolchain not found: $TOOLCHAIN" >&2
    exit 1
fi
if [ ! -d "$QT_HOST_PATH" ]; then
    echo "ERROR: Qt host tools not found: $QT_HOST_PATH" >&2
    exit 1
fi

connected_ios_udid()
{
    python3 - <<'PY'
import json
import os
import subprocess
import sys
import tempfile

output = tempfile.NamedTemporaryFile(delete=False, suffix=".json")
output.close()
try:
    subprocess.check_call(
        ["xcrun", "devicectl", "list", "devices", "--json-output", output.name],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    with open(output.name, encoding="utf-8") as source:
        data = json.load(source)
except Exception:
    sys.exit(0)
finally:
    try:
        os.unlink(output.name)
    except Exception:
        pass

for device in data.get("result", {}).get("devices", []):
    connection = device.get("connectionProperties") or {}
    hardware = device.get("hardwareProperties") or {}
    if connection.get("tunnelState") != "connected":
        continue
    udid = hardware.get("udid")
    if udid:
        print(udid)
        break
PY
}

echo "Local iOS build"
echo "Bundle ID: $BUNDLE_ID"
echo "Team ID: $TEAM_ID"
echo "Export method: $EXPORT_METHOD"

cmake \
    -S "$PROJECT_ROOT/cpp" \
    -B "$BUILD_DIR" \
    -G Xcode \
    -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
    -DQT_HOST_PATH="$QT_HOST_PATH" \
    -DType=mobile \
    -DWORKORDER_IOS_TEAM_ID="$TEAM_ID" \
    -DWORKORDER_IOS_BUNDLE_ID="$BUNDLE_ID" \
    -DCMAKE_BUILD_TYPE=Release

# A previous archive leaves WorkOrder.app as a symlink into DerivedData.
# mkdir then fails because that symlink target no longer exists.
rm -rf "$ARCHIVE_PATH" "$EXPORT_DIR" "$OUTPUT_IPA" "$BUILD_DIR/Release-iphoneos"
mkdir -p "$BUILD_DIR"

DEVICE_UDID="$(connected_ios_udid || true)"
if [ -n "$DEVICE_UDID" ]; then
    echo "Connected iPhone UDID: $DEVICE_UDID"
    echo "Registering the connected device in the provisioning profile"
    xcodebuild \
        -project "$BUILD_DIR/WorkOrder.xcodeproj" \
        -scheme WorkOrder \
        -configuration Release \
        -destination "id=$DEVICE_UDID" \
        DEVELOPMENT_TEAM="$TEAM_ID" \
        CODE_SIGN_STYLE=Automatic \
        TARGETED_DEVICE_FAMILY=1 \
        PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
        -allowProvisioningUpdates \
        -allowProvisioningDeviceRegistration \
        build
else
    echo "No connected iPhone found. The IPA will install only on devices already in the profile."
fi

echo "Creating signed archive"
xcodebuild \
    -project "$BUILD_DIR/WorkOrder.xcodeproj" \
    -scheme WorkOrder \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    CODE_SIGN_STYLE=Automatic \
    TARGETED_DEVICE_FAMILY=1 \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
    -allowProvisioningUpdates \
    -allowProvisioningDeviceRegistration \
    archive

EXPORT_OPTIONS="$BUILD_DIR/ExportOptions.plist"
cat >"$EXPORT_OPTIONS" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$EXPORT_METHOD</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>destination</key>
    <string>export</string>
</dict>
</plist>
EOF

echo "Exporting IPA"
mkdir -p "$EXPORT_DIR"
xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -allowProvisioningUpdates \
    -allowProvisioningDeviceRegistration

IPA="$(find "$EXPORT_DIR" -maxdepth 1 -name '*.ipa' -print -quit)"
if [ -z "$IPA" ]; then
    echo "ERROR: Xcode did not create an IPA" >&2
    exit 1
fi
cp "$IPA" "$OUTPUT_IPA"

echo "Local IPA created"
echo "File: $OUTPUT_IPA"
echo "Install it through Xcode: Window > Devices and Simulators"
