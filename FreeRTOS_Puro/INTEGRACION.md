# Integracion funcional con el MSDK oficial

Esta variante usa el FreeRTOS, port Nuclei/ECLIC, heap, tick, startup y linker
ya integrados y probados por GigaDevice en `GD32VW55x_RELEASE_V1.0.3g`.

1. Instale o extraiga el SDK en `C:\\GD32\\GD32VW55x_RELEASE_V1.0.3g`.
2. Configure las rutas en `tools/local_config.ps1`.
3. En VS Code abra **Terminal > Run Task**.
4. Seleccione **Build + Flash FreeRTOS**.
5. La tarea respalda `MSDK/app` y copia `main.c`, `app_cfg.h`, `sha256.c` y
   `sha256.h`. Después actualiza sus fechas y limpia el build compartido para
   que CMake registre también el nuevo módulo SHA-256.
6. La tarea compila MBL + MSDK, genera `scripts/images/image-all.bin` y la
   programa en `0x08000000` mediante WCH-Link CMSIS-DAP v2, USB bulk y JTAG a
   50 kHz.
7. Observe PC13 y los simbolos `g_*` indicados por el ejercicio.

`main.c` llama `platform_init()`, crea las tareas/objetos FreeRTOS y entrega
el control a `sys_os_start()`. No descargue otro kernel ni mezcle un port
RISC-V generico con el ECLIC de este dispositivo.

La compilacion en el MSDK elimina la antigua dependencia de un port externo.
Esta ruta fue compilada, grabada y validada fisicamente en la placa real: se
observaron dos aceptaciones y tres rechazos por ciclo, como especifica el
ejercicio.
