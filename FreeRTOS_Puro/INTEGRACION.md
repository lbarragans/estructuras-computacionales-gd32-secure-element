# Integracion FreeRTOS

1. Añadir kernel, port RISC-V, `heap_x.c` y `FreeRTOSConfig.h`.
2. Compilar `FreeRTOS_Puro/main.c` junto con `Src/sha256.c`.
3. No compilar `Src/main.c` ni `Src/secure_element_sim.c`.
4. Añadir `Inc/` y los headers FreeRTOS al include path.
5. Dimensionar heap y pila de `Auth` para el contexto SHA-256.
6. Ejecutar `Doc/7_PLAN_DE_VALIDACION.md`.

No almacenar secretos reales en esta simulacion.
