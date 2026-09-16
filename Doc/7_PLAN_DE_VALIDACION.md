# 7. Plan de validacion

## Resultado por ciclo

- 2 autenticaciones aceptadas;
- 3 rechazadas;
- 2 fallas MAC esperadas;
- 1 replay esperado;
- 3 respuestas HMAC generadas;
- 5 verificaciones.

## Referencia

Compilar con `build-debug` y observar elemento seguro, verificador, challenges,
respuestas, paso y contadores al completar las cinco pruebas.

## Assembly

Integrar `main.S` como unica aplicacion. Verificar primero HMAC-SHA256 con
vectores conocidos fuera de la placa y luego comparar los 32 bytes de cada
respuesta con la referencia C. Inspeccionar la comparacion acumulativa y el
rechazo de replay en el `.lst`.

## FreeRTOS

Integrar kernel, port, heap, configuracion y `Src/sha256.c`. Confirmar Queue de
resultados, cinco pasos ordenados y las metricas esperadas.

## Limite de seguridad

No usar estas rutas para secretos reales: la clave permanece en Flash, no hay
proteccion contra lectura, canales laterales ni manipulacion fisica.
