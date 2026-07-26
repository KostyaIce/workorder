#!/usr/bin/env bash
# Build WorkOrder.app with PyInstaller (macOS only). Run pack.sh after this.
#
# Usage:
#   ./prod_build/mac/build.sh [desktop|mobile] [version]
#
# Output:
#   prod_build/mac/dist/WorkOrder.app
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

APP_TYPE="${1:-desktop}"
VERSION="${2:-}"
DIST_DIR="${SCRIPT_DIR}/dist"
WORK_DIR="${SCRIPT_DIR}/work"
BUILD_DIR="${SCRIPT_DIR}/build"
APP_BUNDLE="${DIST_DIR}/WorkOrder.app"

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

if [[ -z "${VERSION}" ]]
then
    VERSION="$(read_version)"
fi

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

rm -rf "${DIST_DIR}" "${WORK_DIR}" "${BUILD_DIR}"
mkdir -p "${DIST_DIR}" "${WORK_DIR}" "${BUILD_DIR}"

cat > "${SCRIPT_DIR}/build.env" <<EOF
WORKORDER_APP_TYPE=${APP_TYPE}
WORKORDER_VERSION=${VERSION}
EOF

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

echo "==> Build done"
echo "App: ${APP_BUNDLE}"
echo "Next: ./prod_build/mac/pack.sh"
