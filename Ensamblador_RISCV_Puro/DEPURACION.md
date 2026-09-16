# Depuracion Assembly

Observe challenges, respuestas, ultimo challenge aceptado, resultado, paso y
los contadores globales. Tras cinco pasos: aceptadas=2, rechazadas=3,
fallas_MAC=2, replays=1, comandos=3 y verificaciones=5.

Antes de usar la placa compare los 32 bytes producidos por
`hmac_sha256_fixed` con `Src/sha256.c` y con vectores externos. Integre ambos
archivos `.S` como unica aplicacion y conserve startup/linker del SDK.
