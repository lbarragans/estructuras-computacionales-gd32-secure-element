# 1. Preparación del entorno

## Hardware

- GD32VW553HMQ6/HMQ7.
- Depurador WCH-Link/CMSIS-DAP conectado por JTAG.
- Cable USB y LED integrado en PC13; no se requiere protoboard.

## Software

- GD32 Embedded Builder (incluye Nuclei RISC-V GCC/GDB y OpenOCD).
- Biblioteca `GD32VW55x_Firmware_Library_V1.6.0`.
- Visual Studio Code con las extensiones recomendadas por
  `.vscode/extensions.json`.
- CMake y Ninja disponibles en `PATH`.

Copie `tools/local_config.example.ps1` como `tools/local_config.ps1`. Configure
`GD32_SDK_ROOT`, `NUCLEI_TOOLCHAIN_DIR` y `OPENOCD_ROOT`. El archivo resultante
es privado y está ignorado por Git.

En VS Code use `Terminal > Run Task > 1. Verificar entorno GD32`. Todos los
elementos deben aparecer con `[OK]` antes de continuar.
