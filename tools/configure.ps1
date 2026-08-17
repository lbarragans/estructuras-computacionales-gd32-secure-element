[CmdletBinding()]
param(
    [ValidateSet("Debug", "Release")]
    [string]$BuildType = "Debug"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ConfigFile = Join-Path $PSScriptRoot "local_config.ps1"

if (-not (Test-Path $ConfigFile)) {
    throw @"
Falta tools/local_config.ps1.
Copie tools/local_config.example.ps1 como tools/local_config.ps1 y edite sus rutas.
"@
}

. $ConfigFile

foreach ($VariableName in @(
    "GD32_SDK_ROOT",
    "NUCLEI_TOOLCHAIN_DIR",
    "OPENOCD_ROOT"
)) {
    $Value = Get-Variable -Name $VariableName -ValueOnly `
        -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "La variable $VariableName no esta configurada."
    }
}

# try_compile abre una configuracion CMake secundaria. Las variables de
# entorno garantizan que esa configuracion tambien encuentre el compilador.
$env:GD32_SDK_ROOT = $GD32_SDK_ROOT
$env:NUCLEI_TOOLCHAIN_DIR = $NUCLEI_TOOLCHAIN_DIR
$env:OPENOCD_ROOT = $OPENOCD_ROOT

$Preset = if ($BuildType -eq "Release") {
    "gd32-release"
} else {
    "gd32-debug"
}

Push-Location $ProjectRoot
try {
    & cmake `
        --preset $Preset `
        "-DGD32_SDK_ROOT=$GD32_SDK_ROOT" `
        "-DNUCLEI_TOOLCHAIN_DIR=$NUCLEI_TOOLCHAIN_DIR"

    if ($LASTEXITCODE -ne 0) {
        throw "CMake fallo con codigo $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}
