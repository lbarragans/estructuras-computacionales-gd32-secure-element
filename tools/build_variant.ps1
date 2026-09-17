[CmdletBinding()]
param(
    [ValidateSet("original", "assembly")]
    [string]$Variant = "original",

    [ValidateSet("Debug", "Release")]
    [string]$BuildType = "Debug",

    [switch]$Flash
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

& (Join-Path $PSScriptRoot "configure.ps1") `
    -BuildType $BuildType -Variant $Variant
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$BuildPreset = if ($BuildType -eq "Release") {
    "build-release"
} else {
    "build-debug"
}

Push-Location $ProjectRoot
try {
    & cmake --build --preset $BuildPreset
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    if ($Flash) {
        & (Join-Path $PSScriptRoot "flash.ps1") -BuildType $BuildType
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
}
finally {
    Pop-Location
}
