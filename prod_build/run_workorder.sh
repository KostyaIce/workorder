#!/usr/bin/env bash
# Launch WorkOrder via Python with PyQt6 (Linux / generic non-macOS dev run).
set -euo pipefail

APP_TYPE="${1:?Usage: run_workorder.sh desktop|mobile [build_dir]}"
BUILD_DIR="${2:-${WORKORDER_BUILD_DIR:-}}"

if [[ $# -ge 2 ]]
then
    shift 2
elif [[ $# -ge 1 ]]
then
    shift 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ "${APP_TYPE}" != "desktop" && "${APP_TYPE}" != "mobile" ]]
then
    echo "Error: app type must be 'desktop' or 'mobile', got '${APP_TYPE}'." >&2
    exit 1
fi

resolve_python()
{
    local candidate
    for candidate in \
        "${ROOT}/.venv/bin/python3" \
        "${ROOT}/.venv/bin/python" \
        "${ROOT}/.venv/bin/python3.12" \
        "${ROOT}/.venv/bin/python3.11" \
        "${ROOT}/.venv/bin/python3.10"
    do
        if [[ -f "${candidate}" ]] \
            && PYTHONPATH="${ROOT}/src" "${candidate}" -c "import qt_compat; import reportlab; import openpyxl" >/dev/null 2>&1
        then
            echo "${candidate}"
            return 0
        fi
    done

    if command -v python3 >/dev/null 2>&1 \
        && PYTHONPATH="${ROOT}/src" python3 -c "import qt_compat; import reportlab; import openpyxl" >/dev/null 2>&1
    then
        command -v python3
        return 0
    fi

    return 1
}

PYTHON="$(resolve_python || true)"
if [[ -z "${PYTHON}" ]]
then
    echo "Error: Qt bindings or app deps missing (PyQt6/PySide6, reportlab, openpyxl)." >&2
    echo "Run in Qt Creator: Build target 'install-deps', then Run CMake." >&2
    echo "Or manually:" >&2
    echo "  cd ${ROOT}" >&2
    echo "  python3 -m venv .venv && .venv/bin/pip install -r requirements.txt" >&2
    exit 1
fi

if [[ -z "${BUILD_DIR}" ]]
then
    echo "Error: build directory is not set (WORKORDER_BUILD_DIR)." >&2
    exit 1
fi

export WORKORDER_BUILD_DIR="${BUILD_DIR}"
export WORKORDER_APP_TYPE="${APP_TYPE}"
printf "APP_TYPE = '%s'\n" "${APP_TYPE}" > "${BUILD_DIR}/workorder_config.py"
export PYTHONPATH="${BUILD_DIR}:${ROOT}/src"
export QML_IMPORT_PATH="${ROOT}/resources/qml:${ROOT}/resources/qml/${APP_TYPE}"
export QT_QUICK_CONTROLS_STYLE=Basic

cd "${ROOT}"
exec "${PYTHON}" "${ROOT}/src/main.py" --type "${APP_TYPE}" "$@"
