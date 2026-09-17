[CmdletBinding()]
param([ValidateRange(1, 64)] [int]$Jobs = 12, [switch]$Clean, [switch]$Flash)
$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ConfigFile = Join-Path $PSScriptRoot "local_config.ps1"
if (-not (Test-Path $ConfigFile)) { throw "Copie tools/local_config.example.ps1 como tools/local_config.ps1 y edite las rutas." }
. $ConfigFile
foreach ($VariableName in @("GD32_MSDK_ROOT", "NUCLEI_TOOLCHAIN_DIR", "OPENOCD_ROOT")) {
    $Value = Get-Variable -Name $VariableName -ValueOnly -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($Value)) { throw "$VariableName no esta configurada en tools/local_config.ps1." }
}
$SdkBuildScript = Join-Path $GD32_MSDK_ROOT "cmake_build.bat"
$SdkAppFolder = Join-Path $GD32_MSDK_ROOT "MSDK/app"
$SourceAppFolder = Join-Path $ProjectRoot "FreeRTOS_Puro"
$BackupFolder = Join-Path $GD32_MSDK_ROOT "BACKUP_APP_ORIGINAL"
$OpenOcdBin = Join-Path $OPENOCD_ROOT "bin"
foreach ($RequiredPath in @($SdkBuildScript, (Join-Path $SdkAppFolder "main.c"), (Join-Path $SdkAppFolder "app_cfg.h"), (Join-Path $SourceAppFolder "main.c"), (Join-Path $SourceAppFolder "app_cfg.h"), (Join-Path $SourceAppFolder "sha256.c"), (Join-Path $SourceAppFolder "sha256.h"), (Join-Path $NUCLEI_TOOLCHAIN_DIR "riscv-nuclei-elf-gcc.exe"), (Join-Path $OpenOcdBin "openocd.exe"))) {
    if (-not (Test-Path $RequiredPath)) { throw "No se encontro: $RequiredPath" }
}
New-Item -ItemType Directory -Path $BackupFolder -Force | Out-Null
foreach ($FileName in @("main.c", "app_cfg.h", "sha256.c", "sha256.h")) {
    $BackupPath = Join-Path $BackupFolder $FileName
    $OriginalFile = Join-Path $SdkAppFolder $FileName
    if ((Test-Path $OriginalFile) -and (-not (Test-Path $BackupPath))) {
        Copy-Item $OriginalFile $BackupPath
    }
    $DestinationFile = Join-Path $SdkAppFolder $FileName
    Copy-Item (Join-Path $SourceAppFolder $FileName) $DestinationFile -Force
    (Get-Item $DestinationFile).LastWriteTime = Get-Date
}
$env:TOOLCHAIN_PATH = $NUCLEI_TOOLCHAIN_DIR
$env:OPENOCD_PATH = $OpenOcdBin
Push-Location $GD32_MSDK_ROOT
try {
    if ($Clean) {
        & cmd.exe /c "cmake_build.bat app clean"
        if ($LASTEXITCODE -ne 0) { throw "La limpieza MSDK fallo con codigo $LASTEXITCODE." }
    }
    & cmd.exe /c "cmake_build.bat app -j$Jobs"
    if ($LASTEXITCODE -ne 0) { throw "La compilacion MSDK fallo con codigo $LASTEXITCODE." }
}
finally { Pop-Location }
$ImagePath = Join-Path $GD32_MSDK_ROOT "scripts/images/image-all.bin"
if (-not (Test-Path $ImagePath)) { throw "No se genero image-all.bin: $ImagePath" }
Write-Host "Imagen FreeRTOS creada: $ImagePath"
if ($Flash) { & (Join-Path $PSScriptRoot "flash_freertos.ps1") }
