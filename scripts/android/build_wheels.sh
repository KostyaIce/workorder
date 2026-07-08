#!/usr/bin/env bash
# Cross-compile PySide6 + shiboken6 Android wheels (once per Qt version).
# Requires: Linux, Qt 6.8.x for Android, Android SDK/NDK, Python 3.11 (no venv).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "$SCRIPT_DIR/env.sh"

ARCH="${1:-aarch64}"   # aarch64 | armv7a | x86_64 | i686
QT_TAG="${QT_TAG:-6.8}"
API_LEVEL="${API_LEVEL:-34}"

if [[ ! -x "$QT_ANDROID_ROOT/android_arm64_v8a/bin/qmake" ]]; then
    echo "Error: Qt for Android not found at $QT_ANDROID_ROOT" >&2
    exit 1
fi
if [[ ! -d "$ANDROID_SDK_ROOT" ]]; then
    echo "Error: Android SDK not found at $ANDROID_SDK_ROOT" >&2
    exit 1
fi
if [[ ! -d "$ANDROID_NDK_ROOT" ]]; then
    echo "Error: Android NDK not found at $ANDROID_NDK_ROOT" >&2
    exit 1
fi

if [[ ! -d "$PYSIDE_SETUP_DIR/.git" ]]; then
    echo "Cloning pyside-setup (branch $QT_TAG)..."
    git clone --depth 1 --branch "$QT_TAG" https://code.qt.io/pyside/pyside-setup.git "$PYSIDE_SETUP_DIR"
fi

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

ensure_standalone_python_prefix()
{
    local py_root include_ok
    py_root="$(cd "$(dirname "$PYTHON311")/.." && pwd)"
    include_ok="$py_root/include/python3.11/Python.h"
    if [[ ! -f "$include_ok" ]]; then
        return 0
    fi
    if [[ -f "/install/include/python3.11/Python.h" ]]; then
        return 0
    fi
    echo "Standalone Python 3.11 uses /install prefix; creating symlink (once):" >&2
    echo "  sudo ln -sfn $py_root /install" >&2
    if sudo ln -sfn "$py_root" /install; then
        echo "OK: /install -> $py_root" >&2
    else
        echo "Error: could not create /install symlink. Run manually and retry." >&2
        exit 1
    fi
}

_libclang_config_ok()
{
    local dir="$1"
    [[ -f "$dir/lib/cmake/clang/ClangConfig.cmake" ]] \
        || [[ -f "$dir/lib64/cmake/clang/ClangConfig.cmake" ]]
}

_find_libclang_dir()
{
    local candidate
    for candidate in \
        "${LLVM_INSTALL_DIR:-}" \
        "$HOME/.local/libclang" \
        "$HOME/Загрузки/~/.local/libclang" \
        "$HOME/Downloads/~/.local/libclang" \
        "$HOME/libclang" \
        "$HOME/Загрузки/libclang" \
        "$HOME/Downloads/libclang"
    do
        if [[ -n "$candidate" ]] && _libclang_config_ok "$candidate"; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

ensure_qt_libclang()
{
    local libclang_dir archive cache_dir parent found
    found="$(_find_libclang_dir || true)"
    if [[ -n "$found" ]]; then
        export LLVM_INSTALL_DIR="$found"
        echo "Using libclang: $LLVM_INSTALL_DIR" >&2
        return 0
    fi

    libclang_dir="${LLVM_INSTALL_DIR:-$HOME/.local/libclang}"
    archive="libclang-release_18.1.5-based-linux-Rhel8.6-gcc10.3-x86_64.7z"
    cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/workorder-libclang"

    echo "PySide6 needs Qt prebuilt libclang (system llvm-18-dev is not enough)." >&2
    mkdir -p "$cache_dir"
    parent="$(dirname "$libclang_dir")"

    # Try archive from Downloads before curl
    for candidate in \
        "$HOME/Загрузки/$archive" \
        "$HOME/Downloads/$archive" \
        "$cache_dir/$archive"
    do
        if [[ -f "$candidate" && "$candidate" != "$cache_dir/$archive" ]]; then
            cp -f "$candidate" "$cache_dir/$archive"
            break
        fi
    done

    if [[ ! -f "$cache_dir/$archive" ]]; then
        echo "Downloading libclang (~618 MB)..." >&2
        if ! curl -fsSL -o "$cache_dir/$archive" \
            "https://download.qt.io/development_releases/prebuilt/libclang/$archive"; then
            echo "" >&2
            echo "Auto-download failed. Install manually:" >&2
            echo "  1. Browser: https://download.qt.io/development_releases/prebuilt/libclang/$archive" >&2
            echo "  2. 7z x $archive -o\$HOME/.local    # note: use \$HOME, not literal ~ in -o" >&2
            echo "  3. export LLVM_INSTALL_DIR=\$HOME/.local/libclang" >&2
            echo "  4. ./scripts/android/build_wheels.sh aarch64" >&2
            exit 1
        fi
    fi

    echo "Extracting libclang to $parent ..." >&2
    7z x "$cache_dir/$archive" -o"$parent" -y >/dev/null
    found="$(_find_libclang_dir || true)"
    if [[ -z "$found" ]]; then
        echo "Error: ClangConfig.cmake not found after extract." >&2
        echo "Expected: $libclang_dir/lib/cmake/clang/ClangConfig.cmake" >&2
        exit 1
    fi
    export LLVM_INSTALL_DIR="$found"
    echo "OK: LLVM_INSTALL_DIR=$LLVM_INSTALL_DIR" >&2
}

ensure_android_sdk_platform()
{
    local api="${API_LEVEL:-34}"
    local jar="$ANDROID_SDK_ROOT/platforms/android-${api}/android.jar"
    local sdkmanager="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"

    if [[ -f "$jar" ]]; then
        return 0
    fi
    if [[ ! -x "$sdkmanager" ]]; then
        echo "Error: missing $jar and sdkmanager not found." >&2
        echo "Install: $sdkmanager \"platforms;android-${api}\"" >&2
        exit 1
    fi
    echo "Installing Android SDK platform android-${api}..." >&2
    yes | "$sdkmanager" "platforms;android-${api}" >/dev/null
    if [[ ! -f "$jar" ]]; then
        echo "Error: failed to install platforms;android-${api}" >&2
        exit 1
    fi
}

if ! resolve_python311; then
    echo "Error: Python 3.11 not found." >&2
    echo "Ubuntu 24.04: use ~/.local/python311 or deadsnakes PPA:" >&2
    echo "  sudo add-apt-repository ppa:deadsnakes/ppa && sudo apt install python3.11 python3.11-dev" >&2
    exit 1
fi

ensure_standalone_python_prefix
ensure_qt_libclang
ensure_android_sdk_platform

PYTHON311_ROOT="$(cd "$(dirname "$PYTHON311")/.." && pwd)"
if [[ ! -f "$PYTHON311_ROOT/lib/libpython3.11.so" ]] \
    && [[ ! -f "$PYTHON311_ROOT/lib/x86_64-linux-gnu/libpython3.11.so" ]]; then
    echo "Error: libpython3.11.so not found for $PYTHON311" >&2
    echo "Install python3.11-dev or use standalone python-build-standalone (not venv)." >&2
    exit 1
fi

# Do not use venv: standalone/relocatable Python breaks sysconfig (/install prefix).
unset VIRTUAL_ENV

cd "$PYSIDE_SETUP_DIR"
"$PYTHON311" -m pip install -r requirements.txt -q
"$PYTHON311" -m pip install -r tools/cross_compile_android/requirements.txt -q
"$PYTHON311" -m pip install ninja -q

export PATH="$(dirname "$PYTHON311"):$PATH"
export CMAKE_MAKE_PROGRAM="$(command -v ninja)"

if [[ ! -x "$CMAKE_MAKE_PROGRAM" ]]; then
    echo "Error: ninja not found (pip install ninja or: sudo apt install ninja-build)" >&2
    exit 1
fi

echo "Building wheels for $ARCH (Qt $QT_ANDROID_ROOT, $("$PYTHON311" --version), ninja $($ninja --version))..."
"$PYTHON311" tools/cross_compile_android/main.py \
    --plat-name="$ARCH" \
    --api-level="$API_LEVEL" \
    --qt-install-path="$QT_ANDROID_ROOT" \
    --ndk-path="$ANDROID_NDK_ROOT" \
    --sdk-path="$ANDROID_SDK_ROOT" \
    --auto-accept-license \
    --skip-update

echo ""
echo "Wheels:"
ls -1 "$PYSIDE_SETUP_DIR"/dist/*android_"${ARCH}"*.whl 2>/dev/null || ls -1 "$PYSIDE_SETUP_DIR"/dist/*.whl
