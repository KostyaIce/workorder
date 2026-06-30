#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$1"
BUILD_DIR="$2"
APP_TYPE="$3"
PYTHON="$4"

BUNDLE="${BUILD_DIR}/WorkOrder.app"
CONTENTS="${BUNDLE}/Contents"
MACOS_DIR="${CONTENTS}/MacOS"
RESOURCES_DIR="${CONTENTS}/Resources"
LAUNCHER="${MACOS_DIR}/WorkOrder"

rm -rf "${BUNDLE}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

cp "${SOURCE_DIR}/resources/icons/appIcons/icon_macos.icns" "${RESOURCES_DIR}/icon_macos.icns"
cp "${BUILD_DIR}/macos/Info.plist" "${CONTENTS}/Info.plist"

cat > "${LAUNCHER}" <<EOF
#!/usr/bin/env bash
set -euo pipefail

ROOT="${SOURCE_DIR}"
BUILD_DIR="${BUILD_DIR}"
APP_TYPE="${APP_TYPE}"
PYTHON="${PYTHON}"

export WORKORDER_BUILD_DIR="\${BUILD_DIR}"
export PYTHONPATH="\${BUILD_DIR}:\${ROOT}/src"
export QML_IMPORT_PATH="\${ROOT}/resources/qml:\${ROOT}/resources/qml/\${APP_TYPE}"
export QT_QUICK_CONTROLS_STYLE=Basic

cd "\${ROOT}"
exec "\${PYTHON}" "\${ROOT}/src/main.py" --type "\${APP_TYPE}" "\$@"
EOF

chmod +x "${LAUNCHER}"
