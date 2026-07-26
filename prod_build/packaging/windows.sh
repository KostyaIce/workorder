#!/bin/bash
# Windows pack: delegates to PowerShell pack.ps1

PACK() {
    local self_dir ps1
    self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
    ps1="${self_dir}/../windows/pack.ps1"

    if command -v powershell.exe >/dev/null 2>&1; then
        powershell.exe -ExecutionPolicy Bypass -File "$ps1"
    elif command -v pwsh >/dev/null 2>&1; then
        pwsh -ExecutionPolicy Bypass -File "$ps1"
    else
        echo "Error: PowerShell not found. Run: .\\prod_build\\windows\\pack.ps1" >&2
        exit 1
    fi
}
