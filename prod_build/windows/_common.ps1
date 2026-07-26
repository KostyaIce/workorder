# Shared helpers for Windows prod_build scripts.

$script:WoWindowsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:WoProdBuildDir = Split-Path -Parent $script:WoWindowsDir
$script:WoProjectRoot = Split-Path -Parent $script:WoProdBuildDir

function Read-ProjectVersion {
    $versionFile = Join-Path $script:WoProjectRoot "version.mk"
    $major = "1"
    $minor = "0"
    $patch = "0"
    Get-Content $versionFile | ForEach-Object {
        if($_ -match "^VERSION_MAJOR\s*=\s*(\d+)") { $major = $Matches[1] }
        elseif($_ -match "^VERSION_MINOR\s*=\s*(\d+)") { $minor = $Matches[1] }
        elseif($_ -match "^VERSION_PATCH\s*=\s*(\d+)") { $patch = $Matches[1] }
    }
    return "$major.$minor.$patch"
}

function To-CMakePath([string]$PathValue)
{
    return ($PathValue -replace '\\', '/')
}

function Resolve-QtRoot {
    param([string]$Preferred)
    if(-not [string]::IsNullOrWhiteSpace($Preferred) -and (Test-Path (Join-Path $Preferred "bin\windeployqt.exe")))
    {
        return (Resolve-Path $Preferred).Path
    }

    $candidates = @(
        "C:\Qt\6.6.0\mingw_64",
        "C:\Qt\6.8.3\mingw_64",
        "C:\Qt\6.7.3\mingw_64",
        "C:\Qt\6.5.3\mingw_64"
    )
    foreach($candidate in $candidates)
    {
        if(Test-Path (Join-Path $candidate "bin\windeployqt.exe"))
        {
            return $candidate
        }
    }

    $found = Get-ChildItem "C:\Qt\6*\mingw_64\bin\windeployqt.exe" -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending |
        Select-Object -First 1
    if($found)
    {
        return $found.Directory.Parent.FullName
    }

    throw "Qt mingw_64 not found. Pass -QtRoot, e.g. -QtRoot C:\Qt\6.6.0\mingw_64"
}

function Resolve-MingwBin {
    param([string]$Preferred)
    if(-not [string]::IsNullOrWhiteSpace($Preferred) -and (Test-Path (Join-Path $Preferred "g++.exe")))
    {
        return (Resolve-Path $Preferred).Path
    }

    $candidates = @(
        "C:\Qt\Tools\mingw1120_64\bin",
        "C:\Qt\Tools\mingw1310_64\bin",
        "C:\Qt\Tools\mingw64\bin"
    )
    foreach($candidate in $candidates)
    {
        if(Test-Path (Join-Path $candidate "g++.exe"))
        {
            return $candidate
        }
    }

    $found = Get-ChildItem "C:\Qt\Tools\mingw*\bin\g++.exe" -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending |
        Select-Object -First 1
    if($found)
    {
        return $found.Directory.FullName
    }

    throw "MinGW g++ not found. Pass -MingwBin, e.g. -MingwBin C:\Qt\Tools\mingw1120_64\bin"
}

function Resolve-CMake {
    $cmd = Get-Command cmake.exe -ErrorAction SilentlyContinue
    if($cmd)
    {
        return $cmd.Source
    }
    $candidates = @(
        "C:\Qt\Tools\CMake_64\bin\cmake.exe",
        "C:\Program Files\CMake\bin\cmake.exe",
        "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
    )
    foreach($candidate in $candidates)
    {
        if(Test-Path $candidate)
        {
            return $candidate
        }
    }
    throw "cmake.exe not found"
}

function Resolve-Ninja {
    $cmd = Get-Command ninja.exe -ErrorAction SilentlyContinue
    if($cmd)
    {
        return $cmd.Source
    }
    $candidate = "C:\Qt\Tools\Ninja\ninja.exe"
    if(Test-Path $candidate)
    {
        return $candidate
    }
    throw "ninja.exe not found (install Qt Ninja or add it to PATH)"
}
