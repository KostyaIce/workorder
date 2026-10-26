#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$1"
BUILD_DIR="$2"
APP_TYPE="$3"
PYTHON="$4"
BUNDLE_NAME="${5:-WorkOrder}"

resolve_python()
{
    local candidate
    for candidate in \
        "${PYTHON}" \
        "${SOURCE_DIR}/.venv/bin/python3" \
        "${SOURCE_DIR}/.venv/bin/python" \
        "${SOURCE_DIR}/.venv/bin/python3.12" \
        "${SOURCE_DIR}/.venv/bin/python3.11"
    do
        if [[ -n "${candidate}" && -f "${candidate}" ]] \
            && "${candidate}" -c "import PyQt6" >/dev/null 2>&1
        then
            echo "${candidate}"
            return 0
        fi
    done

    if command -v python3 >/dev/null 2>&1 \
        && python3 -c "import PyQt6" >/dev/null 2>&1
    then
        command -v python3
        return 0
    fi

    echo "Error: PyQt6 is not installed." >&2
    echo "Run: cmake --build ${BUILD_DIR} --target install-deps" >&2
    exit 1
}

PYTHON="$(resolve_python)"

BUNDLE="${BUILD_DIR}/${BUNDLE_NAME}.app"
CONTENTS="${BUNDLE}/Contents"
MACOS_DIR="${CONTENTS}/MacOS"
RESOURCES_DIR="${CONTENTS}/Resources"
LAUNCHER="${MACOS_DIR}/${BUNDLE_NAME}"

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
export WORKORDER_APP_TYPE="\${APP_TYPE}"
printf "APP_TYPE = '%s'\\n" "\${APP_TYPE}" > "\${BUILD_DIR}/workorder_config.py"
export PYTHONPATH="\${BUILD_DIR}:\${ROOT}/src"
export QML_IMPORT_PATH="\${ROOT}/resources/qml:\${ROOT}/resources/qml/\${APP_TYPE}"
export QT_QUICK_CONTROLS_STYLE=Basic

cd "\${ROOT}"
exec "\${PYTHON}" "\${ROOT}/src/main.py" --type "\${APP_TYPE}" "\$@"
EOF

chmod +x "${LAUNCHER}"
