#!/bin/bash
# macOS pack: DMG via mac/pack.sh

PACK() {
    if [ "$(uname -s)" != "Darwin" ]; then
        echo "Error: osx pack requires macOS host." >&2
        exit 1
    fi
    local self_dir
    self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
    "${self_dir}/../mac/pack.sh"
}
