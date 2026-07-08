#!/usr/bin/env bash
# Build WorkOrder debug APK with pyside6-android-deploy (requires Python 3.11).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "$SCRIPT_DIR/env.sh"

resolve_python311()
{
    local candidate user_set=false
    if [[ -n "${PYTHON311:-}" ]]; then
        user_set=true
        if [[ -x "$PYTHON311" ]]; then
            return 0
        fi
        echo "Warning: PYTHON311=$PYTHON311 not found, trying fallbacks..." >&2
    fi
    for candidate in \
        "$(command -v python3.11 2>/dev/null || true)" \
        "$HOME/.local/python311/bin/python3.11"
    do
        if [[ -n "$candidate" && -x "$candidate" ]]; then
            PYTHON311="$candidate"
            if $user_set; then
                echo "Using $PYTHON311" >&2
            fi
            return 0
        fi
    done
    return 1
}

resolve_android_deploy()
{
    local bin_dir
    bin_dir="$(dirname "$PYTHON311")"
    ANDROID_DEPLOY="$bin_dir/pyside6-android-deploy"
    if [[ ! -x "$ANDROID_DEPLOY" ]]; then
        echo "Error: pyside6-android-deploy not found in $bin_dir" >&2
        exit 1
    fi
}

ensure_android_sdk_layout()
{
    local legacy_sdkmanager="$ANDROID_SDK_ROOT/tools/bin/sdkmanager"
    local modern_sdkmanager="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"

    if [[ -x "$legacy_sdkmanager" ]]; then
        return 0
    fi
    if [[ -x "$modern_sdkmanager" ]]; then
        mkdir -p "$ANDROID_SDK_ROOT/tools/bin"
        ln -sf "../../cmdline-tools/latest/bin/sdkmanager" "$legacy_sdkmanager"
        echo "Linked sdkmanager for buildozer: $legacy_sdkmanager" >&2
    fi
}

ensure_buildozer_ant()
{
    local ant_dir="$HOME/.buildozer/android/platform/apache-ant-1.9.4"
    local system_ant="/usr/share/ant"

    if [[ -x "$ant_dir/bin/ant" ]]; then
        return 0
    fi

    if [[ -x "$system_ant/bin/ant" ]]; then
        echo "Using system Ant at $system_ant (buildozer ignores apt ant in PATH)" >&2
        rm -rf "$ant_dir"
        ln -s "$system_ant" "$ant_dir"
        return 0
    fi

    echo "Warning: Ant not found; buildozer will download apache-ant-1.9.4" >&2
}

clean_stale_p4a_python()
{
    if [[ "${P4A_CLEAN:-0}" == "1" ]]; then
        echo "P4A_CLEAN=1: removing android/.buildozer..." >&2
        rm -rf "$WORKORDER_ROOT/android/.buildozer"
        return 0
    fi
    local build_root="$WORKORDER_ROOT/android/.buildozer/android/platform/build-arm64-v8a/build/other_builds"
    local py_install="$WORKORDER_ROOT/android/.buildozer/android/platform/build-arm64-v8a/build/python-installs/WorkOrder/arm64-v8a"
    if [[ -d "$build_root/reportlab" ]]; then
        echo "Removing stale reportlab p4a build (switching to pure-Python recipe)..." >&2
        rm -rf "$build_root/reportlab"
    fi
    if [[ -d "$py_install" ]]; then
        rm -rf "$py_install"/reportlab "$py_install"/reportlab-*.dist-info
    fi
    if [[ ! -d "$build_root" ]]; then
        return 0
    fi
    if find "$build_root" -path '*python3.14*' -print -quit 2>/dev/null | grep -q .; then
        echo "Removing stale Python 3.14 p4a build cache..." >&2
        rm -rf "$build_root/python3" "$build_root/hostpython3"
    fi
}

ensure_p4a_recipes()
{
    local src="$SCRIPT_DIR/p4a_recipes"
    local dst="$WORKORDER_ROOT/android/deployment/recipes"
    if [[ ! -d "$src" ]]; then
        return 0
    fi
    mkdir -p "$dst"
    for recipe in "$src"/*; do
        [[ -d "$recipe" ]] || continue
        rm -rf "$dst/$(basename "$recipe")"
        cp -a "$recipe" "$dst/"
    done
}

ensure_android_packaging_layout()
{
    local ad="$WORKORDER_ROOT/android"
    ln -sfn ../src "$ad/src"
    ln -sfn ../resources "$ad/resources"
}

ensure_buildozer_spec()
{
    local root_spec="$WORKORDER_ROOT/buildozer.spec"
    local android_spec="$WORKORDER_ROOT/android/buildozer.spec"

    if [[ -f "$android_spec" && ! -f "$root_spec" ]]; then
        mv "$android_spec" "$root_spec"
    fi
    if [[ ! -f "$root_spec" ]]; then
        echo "Creating buildozer.spec in project root..." >&2
        (cd "$WORKORDER_ROOT" && "$PYTHON311" -m buildozer init)
    fi

    # pyside6-android-deploy expects buildozer.spec in project_dir (repo root),
    # but buildozer android runs from android/.
    ln -sf ../buildozer.spec "$android_spec"

    if ! grep -q '^source\.dir = \.$' "$root_spec"; then
        sed -i 's|^source\.dir = .*|source.dir = .|' "$root_spec"
    fi
    sed -i '/^source\.include_patterns =/d' "$root_spec"
}

ensure_android_deploy_deps()
{
    if ! "$PYTHON311" -c "import jinja2, pkginfo, tqdm" 2>/dev/null; then
        echo "Installing android-deploy deps for Python 3.11..." >&2
        "$PYTHON311" -m pip install -q PySide6
        local req
        req="$("$PYTHON311" -c "import PySide6; import os; print(os.path.join(os.path.dirname(PySide6.__file__), 'scripts', 'requirements-android.txt'))")"
        "$PYTHON311" -m pip install -q -r "$req"
    fi
    if ! "$PYTHON311" -c "import buildozer" 2>/dev/null; then
        echo "Installing buildozer for Python 3.11..." >&2
        "$PYTHON311" -m pip install -q "buildozer==1.5.0" "cython==0.29.33"
    fi
    resolve_android_deploy
}

if ! resolve_python311; then
    echo "Error: Python 3.11 required for pyside6-android-deploy (buildozer limit)." >&2
    exit 1
fi

ensure_android_deploy_deps

ensure_buildozer_spec

ensure_p4a_recipes

ensure_android_packaging_layout

ensure_buildozer_ant
ensure_android_sdk_layout
clean_stale_p4a_python

WHEEL_PYSIDE="${WHEEL_PYSIDE:-}"
WHEEL_SHIBOKEN="${WHEEL_SHIBOKEN:-}"

if [[ -z "$WHEEL_PYSIDE" || -z "$WHEEL_SHIBOKEN" ]]; then
    DIST="$PYSIDE_SETUP_DIR/dist"
    if [[ -d "$DIST" ]]; then
        WHEEL_PYSIDE="${WHEEL_PYSIDE:-$(ls -1 "$DIST"/PySide6-*-android_aarch64.whl 2>/dev/null | tail -1)}"
        WHEEL_SHIBOKEN="${WHEEL_SHIBOKEN:-$(ls -1 "$DIST"/shiboken6-*-android_aarch64.whl 2>/dev/null | tail -1)}"
    fi
fi

if [[ ! -f "$WHEEL_PYSIDE" || ! -f "$WHEEL_SHIBOKEN" ]]; then
    echo "Error: set WHEEL_PYSIDE and WHEEL_SHIBOKEN, or run scripts/android/build_wheels.sh first." >&2
    exit 1
fi

export LLVM_INSTALL_DIR="${LLVM_INSTALL_DIR:-$HOME/.local/libclang}"

cd "$WORKORDER_ROOT/android"

echo "Deploy with $("$PYTHON311" --version), wheels:" >&2
echo "  $WHEEL_PYSIDE" >&2
echo "  $WHEEL_SHIBOKEN" >&2

"$PYTHON311" "$SCRIPT_DIR/run_android_deploy.py" \
    -c pysidedeploy.spec \
    --force \
    --name WorkOrder \
    --extra-modules Core,Gui,Qml,Quick \
    --wheel-pyside="$WHEEL_PYSIDE" \
    --wheel-shiboken="$WHEEL_SHIBOKEN" \
    --ndk-path="$ANDROID_NDK_ROOT" \
    --sdk-path="$ANDROID_SDK_ROOT" \
    "$@"

APK="$(find "$WORKORDER_ROOT" -maxdepth 3 -name 'WorkOrder*.apk' -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)"
if [[ -n "$APK" ]]; then
    echo ""
    echo "APK: $APK"
    echo "Install: adb install -r \"$APK\""
fi
