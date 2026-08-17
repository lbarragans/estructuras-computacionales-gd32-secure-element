[CmdletBinding()]
param(
    [ValidateSet("Debug", "Release")]
    [string]$BuildType = "Debug"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ConfigFile = Join-Path $PSScriptRoot "local_config.ps1"

if (-not (Test-Path $ConfigFile)) {
    throw "Falta tools/local_config.ps1."
}

. $ConfigFile

$OpenOcdExe = Join-Path $OPENOCD_ROOT "bin/openocd.exe"
$OpenOcdScripts = Join-Path $OPENOCD_ROOT "scripts"
$BuildFolder = $BuildType.ToLowerInvariant()
$ElfPath = Join-Path $ProjectRoot "build/$BuildFolder/GD32VW55x.elf"

foreach ($RequiredPath in @($OpenOcdExe, $OpenOcdScripts, $ElfPath)) {
    if (-not (Test-Path $RequiredPath)) {
        throw "No se encontro: $RequiredPath"
    }
}

# Las barras / y las llaves evitan que OpenOCD pierda la ruta en Windows.
$ElfForOpenOcd = (Resolve-Path $ElfPath).Path.Replace("\", "/")
$ProgramCommand = "program {$ElfForOpenOcd} verify reset exit"

& $OpenOcdExe `
    -s $OpenOcdScripts `
    -f "interface/cmsis-dap.cfg" `
    -c "transport select jtag" `
    -c "adapter speed 100" `
    -f "target/gd32vw55x.cfg" `
    -c $ProgramCommand

if ($LASTEXITCODE -ne 0) {
    throw "OpenOCD fallo con codigo $LASTEXITCODE."
}
