#!/bin/bash
# WorkOrder prod build (dapchain-style entry).
#
# Usage:
#   ./prod_build/build.sh [--target windows|osx] [release|debug|rwd]
#
# Windows (PowerShell):
#   .\prod_build\windows\build.ps1
# macOS:
#   ./prod_build/mac/build.sh [desktop|mobile] [version]
set -euo pipefail

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
    TARGET="$(readlink "$SOURCE")"
    if [[ "$TARGET" == /* ]]; then
        SOURCE="$TARGET"
    else
        DIR="$(dirname "$SOURCE")"
        SOURCE="$DIR/$TARGET"
    fi
done
MHERE="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"

# shellcheck disable=SC1091
. "${MHERE}/validate.sh"

NAME_OUT="$(uname -s)"
case "${NAME_OUT}" in
    Linux*) MACHINE=Linux ;;
    Darwin*) MACHINE=Mac ;;
    CYGWIN*) MACHINE=Cygwin ;;
    MINGW*) MACHINE=MinGw ;;
    MSYS_NT*) MACHINE=Git ;;
    *) MACHINE="UNKNOWN:${NAME_OUT}" ;;
esac

Help() {
    echo "WorkOrder build"
    echo "Usage: build.sh [--target windows|osx] [release|debug|rwd]"
}

POSITIONAL_ARGS=()
TARGET=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            Help
            exit 0
            ;;
        -t|--target)
            TARGET="$2"
            shift 2
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done
set -- "${POSITIONAL_ARGS[@]+"${POSITIONAL_ARGS[@]}"}"

BUILD_TYPE="${1:-release}"

DEFAULT_TARGET="osx"
if [ "$MACHINE" = "Mac" ]; then
    DEFAULT_TARGET="osx"
elif [ "$MACHINE" = "Git" ] || [ "$MACHINE" = "MinGw" ] || [[ "$NAME_OUT" == MINGW* ]] || [[ "$NAME_OUT" == MSYS* ]]; then
    DEFAULT_TARGET="windows"
fi

BUILD_TARGET="${TARGET:-$DEFAULT_TARGET}"
VALIDATE_TARGET
VALIDATE_BUILD_TYPE

echo "Host machine is $MACHINE"
echo "Build [${BUILD_TYPE}] for [${BUILD_TARGET}]"

# shellcheck disable=SC1090
. "${MHERE}/targets/${BUILD_TARGET}.sh"
run_build
