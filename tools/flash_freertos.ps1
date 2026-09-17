[CmdletBinding()]
param()
$ErrorActionPreference = "Stop"
$ConfigFile = Join-Path $PSScriptRoot "local_config.ps1"
if (-not (Test-Path $ConfigFile)) { throw "Copie tools/local_config.example.ps1 como tools/local_config.ps1 y edite las rutas." }
. $ConfigFile
$OpenOcdExe = Join-Path $OPENOCD_ROOT "bin/openocd.exe"
$OpenOcdScripts = Join-Path $OPENOCD_ROOT "scripts"
$ImagePath = Join-Path $GD32_MSDK_ROOT "scripts/images/image-all.bin"
foreach ($RequiredPath in @($OpenOcdExe, $OpenOcdScripts, $ImagePath)) {
    if (-not (Test-Path $RequiredPath)) { throw "No se encontro: $RequiredPath" }
}
$ImageForOpenOcd = (Resolve-Path $ImagePath).Path.Replace("\", "/")
$ProgramCommand = "program {$ImageForOpenOcd} 0x08000000 verify reset exit"
& $OpenOcdExe `
    -s $OpenOcdScripts `
    -f "interface/cmsis-dap.cfg" `
    -c "cmsis_dap_backend usb_bulk" `
    -c "cmsis_dap_vid_pid 0x1a86 0x8012" `
    -c "transport select jtag" `
    -c "adapter speed 50" `
    -f "target/gd32vw55x.cfg" `
    -c $ProgramCommand
if ($LASTEXITCODE -ne 0) { throw "OpenOCD fallo con codigo $LASTEXITCODE." }
