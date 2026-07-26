#!/bin/bash
# Validate prod_build target / build type (dapchain-style).

if [ "${0:0:1}" = "/" ]; then
    HERE="$(dirname "$0")"
else
    CMD="$(pwd)/$0"
    HERE="$(dirname "${CMD}")"
fi

containsElement() {
    local e match="$1"
    shift
    for e; do [[ "$e" == "$match" ]] && return 0; done
    return 1
}

TARGETS=(windows osx)
BUILD_TYPES=(release debug rwd)

VALIDATE_TARGET() {
    containsElement "$BUILD_TARGET" "${TARGETS[@]}" || {
        echo "Such target not implemented [$BUILD_TARGET]"
        echo "Available targets are [${TARGETS[*]}]"
        exit 255
    }
}

VALIDATE_BUILD_TYPE() {
    containsElement "$BUILD_TYPE" "${BUILD_TYPES[@]}" || {
        echo "Unknown build type [$BUILD_TYPE]"
        echo "Available types are [${BUILD_TYPES[*]}]"
        exit 255
    }
}
