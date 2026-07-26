#!/bin/bash
# Windows build target: delegates to PowerShell build.ps1

run_build() {
    local ps1="${MHERE}/windows/build.ps1"
    if command -v powershell.exe >/dev/null 2>&1; then
        powershell.exe -ExecutionPolicy Bypass -File "$ps1" -BuildType "$BUILD_TYPE"
    elif command -v pwsh >/dev/null 2>&1; then
        pwsh -ExecutionPolicy Bypass -File "$ps1" -BuildType "$BUILD_TYPE"
    else
        echo "Error: PowerShell not found. Run: .\\prod_build\\windows\\build.ps1" >&2
        exit 1
    fi
}
