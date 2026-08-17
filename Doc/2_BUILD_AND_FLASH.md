# 2. Compilación y programación

El flujo recomendado para estudiantes se realiza desde `Terminal > Run Task`:

1. `1. Verificar entorno GD32`: comprueba herramientas, SDK y rutas.
2. `2. Configurar CMake (Debug)`: genera el proyecto Ninja en `build/debug`.
3. `3. Compilar GD32 (Debug)`: compila C y genera ELF, HEX, BIN, MAP y LST.
4. `4. Programar GD32 (Debug)`: escribe y verifica el ELF mediante OpenOCD.

La tarea `5. Compilar y programar GD32` ejecuta la secuencia habitual. La tarea
`6. Preparar depuración` crea `.vscode/launch.json` con las rutas locales.

CMake describe fuentes, opciones RISC-V, linker script y artefactos. Ninja
ejecuta únicamente los pasos que cambiaron. OpenOCD comunica VS Code o el
programador con el núcleo a través de CMSIS-DAP/JTAG.
