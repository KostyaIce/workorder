# Build WorkOrder C++ desktop (non-compact) for Windows.
# Compiles and stages bare exe into dist/. Run pack.ps1 after this.
#
# Usage:
#   .\prod_build\windows\build.ps1
#   .\prod_build\windows\build.ps1 -QtRoot C:\Qt\6.6.0\mingw_64
#
# Output:
#   prod_build\windows\build\WorkOrder.exe
#   prod_build\windows\dist\WorkOrder.exe

param(
    [string]$QtRoot = "",
    [string]$MingwBin = "",
    [ValidateSet("release", "debug", "rwd")]
    [string]$BuildType = "release"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "_common.ps1")

$BuildDir = Join-Path $script:WoWindowsDir "build"
$DistDir = Join-Path $script:WoWindowsDir "dist"
$SourceDir = Join-Path $script:WoProjectRoot "cpp"

switch($BuildType)
{
    "debug" { $CmakeBuildType = "Debug" }
    "rwd" { $CmakeBuildType = "RelWithDebInfo" }
    default { $CmakeBuildType = "Release" }
}

$QtRoot = Resolve-QtRoot -Preferred $QtRoot
$MingwBin = Resolve-MingwBin -Preferred $MingwBin
$CMake = Resolve-CMake
$Ninja = Resolve-Ninja

$QtRootCMake = To-CMakePath $QtRoot
$NinjaCMake = To-CMakePath $Ninja
$SourceDirCMake = To-CMakePath $SourceDir
$BuildDirCMake = To-CMakePath $BuildDir
$GxxCMake = To-CMakePath (Join-Path $MingwBin "g++.exe")

$env:PATH = "$MingwBin;$(Join-Path $QtRoot 'bin');$env:PATH"

# Persist toolchain for pack.ps1
$envFile = Join-Path $script:WoWindowsDir "build.env.ps1"
@"
`$env:WORKORDER_QT_ROOT = '$QtRoot'
`$env:WORKORDER_MINGW_BIN = '$MingwBin'
`$env:WORKORDER_BUILD_TYPE = '$BuildType'
"@ | Set-Content -Encoding UTF8 $envFile

Write-Host "==> Project:   $script:WoProjectRoot"
Write-Host "==> Qt:        $QtRoot"
Write-Host "==> MinGW:     $MingwBin"
Write-Host "==> CMake:     $CMake"
Write-Host "==> BuildType: $CmakeBuildType"
Write-Host "==> UI type:   desktop (non-compact)"

Write-Host "==> Configure"
if(Test-Path $BuildDir)
{
    Remove-Item -Recurse -Force $BuildDir
}
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
New-Item -ItemType Directory -Force -Path $DistDir | Out-Null

& $CMake -S $SourceDirCMake -B $BuildDirCMake `
    -G Ninja `
    "-DCMAKE_BUILD_TYPE=$CmakeBuildType" `
    "-DCMAKE_PREFIX_PATH=$QtRootCMake" `
    "-DCMAKE_MAKE_PROGRAM=$NinjaCMake" `
    "-DCMAKE_CXX_COMPILER=$GxxCMake" `
    -DType=desktop
if($LASTEXITCODE -ne 0)
{
    throw "CMake configure failed"
}

Write-Host "==> Build WorkOrder"
& $CMake --build $BuildDir --target WorkOrder --config $CmakeBuildType
if($LASTEXITCODE -ne 0)
{
    throw "CMake build failed"
}

$BuiltExe = Join-Path $BuildDir "WorkOrder.exe"
if(-not (Test-Path $BuiltExe))
{
    throw "Built exe not found: $BuiltExe"
}

Write-Host "==> Stage dist"
Get-ChildItem $DistDir -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
Copy-Item $BuiltExe (Join-Path $DistDir "WorkOrder.exe")

Write-Host "==> Build done"
Write-Host "Build: $BuiltExe"
Write-Host "Dist:  $(Join-Path $DistDir 'WorkOrder.exe')"
Write-Host "Next:  .\prod_build\windows\pack.ps1"
