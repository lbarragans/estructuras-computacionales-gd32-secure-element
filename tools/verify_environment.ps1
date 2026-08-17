[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$ConfigFile = Join-Path $PSScriptRoot "local_config.ps1"

if (-not (Test-Path $ConfigFile)) {
    throw "Falta tools/local_config.ps1. Copie y edite el archivo de ejemplo."
}

. $ConfigFile

$Checks = @(
    @{ Name = "CMake"; Path = (Get-Command cmake -ErrorAction SilentlyContinue).Source },
    @{ Name = "Ninja"; Path = (Get-Command ninja -ErrorAction SilentlyContinue).Source },
    @{ Name = "Compilador RISC-V"; Path = (Join-Path $NUCLEI_TOOLCHAIN_DIR "riscv-nuclei-elf-gcc.exe") },
    @{ Name = "GDB RISC-V"; Path = (Join-Path $NUCLEI_TOOLCHAIN_DIR "riscv-nuclei-elf-gdb.exe") },
    @{ Name = "OpenOCD"; Path = (Join-Path $OPENOCD_ROOT "bin/openocd.exe") },
    @{ Name = "Scripts OpenOCD"; Path = (Join-Path $OPENOCD_ROOT "scripts") },
    @{ Name = "system_gd32vw55x.c"; Path = (Join-Path $GD32_SDK_ROOT "Firmware/GD32VW55x_standard_peripheral/system_gd32vw55x.c") },
    @{ Name = "Linker script"; Path = (Join-Path $GD32_SDK_ROOT "Firmware/RISCV/env_Eclipse/GD32VW553xM.lds") },
    @{ Name = "Board support"; Path = (Join-Path $GD32_SDK_ROOT "Utilities/gd32vw553h_eval.c") }
)

$Failed = $false
foreach ($Check in $Checks) {
    $Exists = -not [string]::IsNullOrWhiteSpace($Check.Path) -and
        (Test-Path $Check.Path)
    $State = if ($Exists) { "OK" } else { "FALTA" }
    $Color = if ($Exists) { "Green" } else { "Red" }
    Write-Host ("[{0}] {1}: {2}" -f $State, $Check.Name, $Check.Path) `
        -ForegroundColor $Color
    if (-not $Exists) { $Failed = $true }
}

if ($Failed) {
    throw "La verificacion encontro elementos faltantes. Corrija las rutas."
}

Write-Host "Entorno listo para configurar y compilar." -ForegroundColor Green
