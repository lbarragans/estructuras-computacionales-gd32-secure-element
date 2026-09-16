# FreeRTOS puro

`authentication_task` ejecuta cinco pruebas y envia cada resultado a una
Queue. `indicator_task` espera bloqueada y genera el patron visual.

La comparacion MAC acumula las diferencias de los 32 bytes antes de decidir.
El replay se comprueba antes de recalcular el MAC. La tarea usa una pila mayor
por los buffers internos de SHA-256.

Esta ruta reutiliza `Src/sha256.c` como primitiva criptografica auditada, pero
no llama `Src/main.c` ni `Src/secure_element_sim.c`.
