# 6. Implementaciones definitivas

| Implementacion | Ejecucion | Criptografia |
|---|---|---|
| Referencia C | guion temporal bare-metal | HMAC-SHA256 en C |
| Assembly puro | guion e indicador Assembly | HMAC-SHA256 fijo key32/message32 |
| FreeRTOS puro | tarea de prueba + Queue | reutiliza el modulo SHA-256 auditado |

## Referencia

`Src/main.c`, `Src/secure_element_sim.c`, `Src/sha256.c` y `Src/systimer.c`
permanecen como control y compilacion principal.

## Assembly puro

`Ensamblador_RISCV_Puro/main.S` implementa challenges, HMAC-SHA256 para la
forma fija del laboratorio, comparacion acumulativa, memoria anti-replay,
contadores y señalizacion. No es una biblioteca criptografica general.

## FreeRTOS puro

`FreeRTOS_Puro/main.c` implementa elemento seguro y verificador sobre dos
tareas. Reutiliza exclusivamente la primitiva `hmac_sha256` de `Src/sha256.c`;
no llama la aplicacion ni el simulador originales.
