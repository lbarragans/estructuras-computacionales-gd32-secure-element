# 3. Conceptos y preguntas

## Hash, cifrado, MAC y autenticación

- Un **hash** produce una huella de longitud fija y no usa clave.
- El **cifrado** busca confidencialidad y es reversible con una clave.
- Un **MAC** usa una clave para verificar integridad y autenticidad.
- La **autenticación** decide si una entidad demuestra conocer un secreto.

HMAC combina una función hash y una clave:

```text
HMAC(K,m) = H((K xor opad) || H((K xor ipad) || m))
```

Cambiar un bit del challenge o de la respuesta produce un MAC diferente. La
comparación recorre siempre los 32 bytes para reducir filtraciones de tiempo.

## Challenge–response y replay

El verificador envía un challenge impredecible y de un solo uso. El elemento
seguro calcula una respuesta sin revelar la clave. Reutilizar un challenge ya
aceptado es un ataque de repetición aunque su MAC siga siendo correcto.

Este simulador recuerda solamente el último challenge aceptado. Un sistema real
requiere nonces aleatorios, contadores persistentes o una ventana de historial.

## Elemento seguro real

Un ATECC608 real almacena secretos en hardware resistente a extracción y puede
ejecutar operaciones ECC, HMAC, generación aleatoria y gestión de slots. Aquí
se modela únicamente el concepto de challenge–response simétrico; la clave está
en Flash y no es segura contra lectura física.

## Preguntas

1. ¿Por qué un hash sin clave no autentica al dispositivo?
2. ¿Por qué cifrar y autenticar son objetivos diferentes?
3. ¿Qué ocurre si el challenge se repite después de reiniciar?
4. ¿Qué propiedad debería tener un generador de challenges real?
5. ¿Por qué `memcmp` puede ser inadecuado para comparar MAC sensibles?
