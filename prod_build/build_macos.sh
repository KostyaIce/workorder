#!/usr/bin/env bash
# Build WorkOrder.app with PyInstaller and wrap it in a DMG (macOS only).
#
# Usage:
#   ./prod_build/build_macos.sh [desktop|mobile] [version]
#
# Examples:
#   ./prod_build/build_macos.sh
#   ./prod_build/build_macos.sh desktop 1.0.0
#   ./prod_build/build_macos.sh mobile 1.0.0
#
# Output:
#   prod_build/dist/WorkOrder.app
#   prod_build/dist/WorkOrder-<type>-<version>.dmg
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

APP_TYPE="${1:-desktop}"
VERSION="${2:-1.0.0}"
DIST_DIR="${SCRIPT_DIR}/dist"
WORK_DIR="${SCRIPT_DIR}/work"
DMG_STAGE_DIR="${SCRIPT_DIR}/dmg_staging"
APP_BUNDLE="${DIST_DIR}/WorkOrder.app"
DMG_NAME="WorkOrder-${APP_TYPE}-${VERSION}.dmg"
DMG_PATH="${DIST_DIR}/${DMG_NAME}"

if [[ "$(uname -s)" != "Darwin" ]]
then
    echo "Error: this script supports macOS only." >&2
    exit 1
fi

if [[ "${APP_TYPE}" != "desktop" && "${APP_TYPE}" != "mobile" ]]
then
    echo "Error: app type must be 'desktop' or 'mobile', got '${APP_TYPE}'." >&2
    exit 1
fi

if [[ -x "${PROJECT_ROOT}/.venv/bin/python" ]]
then
    PYTHON="${PROJECT_ROOT}/.venv/bin/python"
elif command -v python3 >/dev/null 2>&1
then
    PYTHON="$(command -v python3)"
else
    echo "Error: python3 not found." >&2
    exit 1
fi

echo "==> Project: ${PROJECT_ROOT}"
echo "==> Python:  ${PYTHON}"
echo "==> Type:    ${APP_TYPE}"
echo "==> Version: ${VERSION}"

echo "==> Installing build dependencies"
"${PYTHON}" -m pip install -q -r "${PROJECT_ROOT}/requirements.txt"
"${PYTHON}" -m pip install -q -r "${SCRIPT_DIR}/requirements-build.txt"

echo "==> Building WorkOrder.app"
export WORKORDER_APP_TYPE="${APP_TYPE}"
export WORKORDER_VERSION="${VERSION}"

"${PYTHON}" -m PyInstaller \
    --noconfirm \
    --clean \
    --distpath "${DIST_DIR}" \
    --workpath "${WORK_DIR}" \
    "${SCRIPT_DIR}/workorder.spec"

if [[ ! -d "${APP_BUNDLE}" ]]
then
    echo "Error: app bundle was not created at ${APP_BUNDLE}" >&2
    exit 1
fi

echo "==> Creating DMG"
rm -rf "${DMG_STAGE_DIR}"
mkdir -p "${DMG_STAGE_DIR}"
cp -R "${APP_BUNDLE}" "${DMG_STAGE_DIR}/"
ln -s /Applications "${DMG_STAGE_DIR}/Applications"

rm -f "${DMG_PATH}"
hdiutil create \
    -volname "WorkOrder" \
    -srcfolder "${DMG_STAGE_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}" >/dev/null

rm -rf "${DMG_STAGE_DIR}"

echo "==> Done"
echo "App: ${APP_BUNDLE}"
echo "DMG: ${DMG_PATH}"
