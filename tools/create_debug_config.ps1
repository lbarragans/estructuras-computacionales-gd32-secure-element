[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ConfigFile = Join-Path $PSScriptRoot "local_config.ps1"
$VsCodeFolder = Join-Path $ProjectRoot ".vscode"
$LaunchFile = Join-Path $VsCodeFolder "launch.json"

if (-not (Test-Path $ConfigFile)) {
    throw "Copie tools/local_config.example.ps1 como tools/local_config.ps1 y editelo."
}

. $ConfigFile

$GdbPath = Join-Path $NUCLEI_TOOLCHAIN_DIR "riscv-nuclei-elf-gdb.exe"
$ObjdumpPath = Join-Path $NUCLEI_TOOLCHAIN_DIR "riscv-nuclei-elf-objdump.exe"
$OpenOcdPath = Join-Path $OPENOCD_ROOT "bin/openocd.exe"
$OpenOcdScripts = Join-Path $OPENOCD_ROOT "scripts"

foreach ($RequiredPath in @($GdbPath, $ObjdumpPath, $OpenOcdPath, $OpenOcdScripts)) {
    if (-not (Test-Path $RequiredPath)) {
        throw "No se encontro: $RequiredPath"
    }
}

function Convert-ToVsCodePath([string]$Path) {
    return (Resolve-Path $Path).Path.Replace("\", "/")
}

$LaunchConfiguration = [ordered]@{
    version = "0.2.0"
    configurations = @(
        [ordered]@{
            name = "Debug GD32VW553 - Secure Element"
            type = "cortex-debug"
            request = "launch"
            cwd = '${workspaceFolder}'
            executable = '${workspaceFolder}/build/debug/GD32VW55x.elf'
            servertype = "openocd"
            serverpath = Convert-ToVsCodePath $OpenOcdPath
            gdbPath = Convert-ToVsCodePath $GdbPath
            objdumpPath = Convert-ToVsCodePath $ObjdumpPath
            toolchainPrefix = "riscv-nuclei-elf"
            searchDir = @(Convert-ToVsCodePath $OpenOcdScripts)
            configFiles = @("interface/cmsis-dap.cfg")
            openOCDLaunchCommands = @(
                "transport select jtag",
                "adapter speed 100",
                "source [find target/gd32vw55x.cfg]"
            )
            overrideLaunchCommands = @(
                "monitor reset halt",
                "load",
                "monitor reset halt"
            )
            overrideResetCommands = @("monitor reset halt")
            runToEntryPoint = "main"
            preLaunchTask = "3. Compilar GD32 (Debug)"
            showDevDebugOutput = "raw"
        }
    )
}

if (-not (Test-Path $VsCodeFolder)) {
    New-Item -ItemType Directory -Path $VsCodeFolder | Out-Null
}

$LaunchConfiguration | ConvertTo-Json -Depth 8 |
    Set-Content -Path $LaunchFile -Encoding UTF8

Write-Host "Creado: $LaunchFile"
