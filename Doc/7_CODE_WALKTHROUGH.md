# 7. Recorrido del código

- `Src/main.c` ejecuta el guion de cinco pruebas, actualiza contadores y muestra
  resultados con PC13 sin bloquear el procesador.
- `Src/secure_element_sim.c` contiene el modelo del dispositivo y del
  verificador. La API del dispositivo entrega una respuesta, nunca la clave.
- `Src/sha256.c` implementa SHA-256 y HMAC-SHA256 sin memoria dinámica.
- `Src/systimer.c` genera la base de tiempo de 1 ms mediante interrupciones.
- `CMakeLists.txt` integra fuentes propias y SDK para producir el firmware.

La interfaz separa tres capas: aplicación, autenticación y primitiva
criptográfica. Esa abstracción permite sustituir el simulador por un driver de
hardware conservando gran parte de la lógica de alto nivel.
