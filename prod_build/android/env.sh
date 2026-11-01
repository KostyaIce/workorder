#!/usr/bin/env bash
# Source before build_wheels.sh / build_apk.sh:
#   source prod_build/android/env.sh

export WORKORDER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export QT_ANDROID_ROOT="${QT_ANDROID_ROOT:-$HOME/Qt/6.8.3}"
case "$(uname -s)" in
    Darwin) _workorder_sdk_default="$HOME/Library/Android/sdk" ;;
    *) _workorder_sdk_default="$HOME/Android/Sdk" ;;
esac
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$_workorder_sdk_default}}"
if [ -z "${ANDROID_NDK_ROOT:-}" ]; then
    ANDROID_NDK_ROOT="$(for _workorder_ndk in "$ANDROID_SDK_ROOT"/ndk/*; do
        [ -f "$_workorder_ndk/build/cmake/android.toolchain.cmake" ] && printf '%s\n' "$_workorder_ndk"
    done | sort -V 2>/dev/null | tail -n 1)"
fi
export ANDROID_NDK_ROOT="${ANDROID_NDK_ROOT:-}"
unset _workorder_sdk_default _workorder_ndk
export PYSIDE_SETUP_DIR="${PYSIDE_SETUP_DIR:-$HOME/Project/pyside-setup}"
export WORKORDER_VENV="${WORKORDER_VENV:-$WORKORDER_ROOT/.venv}"
export PYTHON311="${PYTHON311:-$HOME/.local/python311/bin/python3.11}"
export PATH="$(dirname "$PYTHON311"):$PATH"

# p4a develop defaults to Python 3.14; wheels are cp311.
export P4A_PYTHON_VERSION="${P4A_PYTHON_VERSION:-3.11.11}"
export VERSION_python3="${VERSION_python3:-$P4A_PYTHON_VERSION}"
export VERSION_hostpython3="${VERSION_hostpython3:-$P4A_PYTHON_VERSION}"
