#!/usr/bin/env bash
# Pack WorkOrder.app into a DMG (macOS only). Requires a prior build.sh run.
#
# Usage:
#   ./prod_build/mac/pack.sh
#   ./prod_build/mac/pack.sh [desktop|mobile] [version]
#
# Output:
#   prod_build/mac/WorkOrder.app
#   prod_build/mac/WorkOrder-<type>-<version>.dmg
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

APP_TYPE="${1:-}"
VERSION="${2:-}"
DIST_DIR="${SCRIPT_DIR}/dist"
DMG_STAGE_DIR="${SCRIPT_DIR}/dmg_staging"
SRC_BUNDLE="${DIST_DIR}/WorkOrder.app"
OUT_BUNDLE="${SCRIPT_DIR}/WorkOrder.app"

read_version() {
    local major=1 minor=0 patch=0
    while IFS= read -r line; do
        case "$line" in
            VERSION_MAJOR=*) major="${line#VERSION_MAJOR=}" ;;
            VERSION_MINOR=*) minor="${line#VERSION_MINOR=}" ;;
            VERSION_PATCH=*) patch="${line#VERSION_PATCH=}" ;;
        esac
    done < "${PROJECT_ROOT}/version.mk"
    echo "${major}.${minor}.${patch}"
}

if [[ -f "${SCRIPT_DIR}/build.env" ]]
then
    # shellcheck disable=SC1091
    source "${SCRIPT_DIR}/build.env"
fi

if [[ -z "${APP_TYPE}" ]]
then
    APP_TYPE="${WORKORDER_APP_TYPE:-desktop}"
fi
if [[ -z "${VERSION}" ]]
then
    VERSION="${WORKORDER_VERSION:-$(read_version)}"
fi

if [[ "$(uname -s)" != "Darwin" ]]
then
    echo "Error: this script supports macOS only." >&2
    exit 1
fi

if [[ ! -d "${SRC_BUNDLE}" ]]
then
    echo "Error: no build found: ${SRC_BUNDLE}" >&2
    echo "Run ./prod_build/mac/build.sh first" >&2
    exit 1
fi

DMG_NAME="WorkOrder-${APP_TYPE}-${VERSION}.dmg"
DMG_PATH="${SCRIPT_DIR}/${DMG_NAME}"

echo "==> Type:    ${APP_TYPE}"
echo "==> Version: ${VERSION}"
echo "==> Source:  ${SRC_BUNDLE}"

echo "==> Copy app to mac/"
rm -rf "${OUT_BUNDLE}"
cp -R "${SRC_BUNDLE}" "${OUT_BUNDLE}"

echo "==> Creating DMG"
rm -rf "${DMG_STAGE_DIR}"
mkdir -p "${DMG_STAGE_DIR}"
cp -R "${OUT_BUNDLE}" "${DMG_STAGE_DIR}/"
ln -s /Applications "${DMG_STAGE_DIR}/Applications"

rm -f "${DMG_PATH}"
hdiutil create \
    -volname "WorkOrder" \
    -srcfolder "${DMG_STAGE_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}" >/dev/null

rm -rf "${DMG_STAGE_DIR}"

echo "==> Pack done"
echo "App: ${OUT_BUNDLE}"
echo "DMG: ${DMG_PATH}"
