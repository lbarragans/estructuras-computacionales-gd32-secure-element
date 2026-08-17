# 4. Depuración

Ejecute `6. Preparar depuración`, abra *Run and Debug* y seleccione
`Debug GD32VW553 - Secure Element`.

Coloque un breakpoint en `g_sequence_cycles++;` dentro de `Src/main.c`. Añada a
Watch los contadores del README y las estructuras `g_secure_element` y
`g_auth_verifier`. Antes de ejecutar esa línea debe observar dos aceptaciones,
tres rechazos, dos errores de MAC y un replay; después de *Step Over*,
`g_sequence_cycles` pasa a 1.

Otros breakpoints útiles:

- `secure_element_compute_response`: inspeccionar challenge y response.
- `auth_verifier_verify`: seguir las decisiones MAC/replay.
- `constant_time_equal`: observar la comparación byte a byte.
- `hmac_sha256`: relacionar la API con las dos rondas de SHA-256.

Las matrices pueden verse en hexadecimal desde Variables o Memory. No confunda
la salida de Debug Console con la terminal de tareas.
