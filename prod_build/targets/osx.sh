#!/bin/bash
# macOS build target: delegates to mac/build.sh (PyInstaller)

run_build() {
    if [ "$(uname -s)" != "Darwin" ]; then
        echo "Error: osx target requires macOS host." >&2
        exit 1
    fi
    # release/debug map only to versioned artifacts; UI type stays desktop by default
    "${MHERE}/mac/build.sh" desktop
}
