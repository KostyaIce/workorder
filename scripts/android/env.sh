#!/usr/bin/env bash
# Source before build_wheels.sh / build_apk.sh:
#   source scripts/android/env.sh

export WORKORDER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export QT_ANDROID_ROOT="${QT_ANDROID_ROOT:-$HOME/Qt/6.8.3}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}"
export ANDROID_NDK_ROOT="${ANDROID_NDK_ROOT:-$ANDROID_SDK_ROOT/ndk/26.1.10909125}"
export PYSIDE_SETUP_DIR="${PYSIDE_SETUP_DIR:-$HOME/Project/pyside-setup}"
export WORKORDER_VENV="${WORKORDER_VENV:-$WORKORDER_ROOT/.venv}"
export PYTHON311="${PYTHON311:-$HOME/.local/python311/bin/python3.11}"
export PATH="$(dirname "$PYTHON311"):$PATH"

# p4a develop defaults to Python 3.14; wheels are cp311.
export P4A_PYTHON_VERSION="${P4A_PYTHON_VERSION:-3.11.11}"
export VERSION_python3="${VERSION_python3:-$P4A_PYTHON_VERSION}"
export VERSION_hostpython3="${VERSION_hostpython3:-$P4A_PYTHON_VERSION}"
