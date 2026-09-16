# Ensamblador RISC-V puro

La ruta contiene dos fuentes Assembly:

- `main.S`: challenges, cinco pruebas, comparacion acumulativa, replay,
  contadores, SysTimer y LED;
- `sha256_fixed.S`: SHA-256 y HMAC especializado para clave y mensaje de
  32 bytes, exactamente la forma usada por el laboratorio.

No se llama codigo C de aplicacion. El HMAC fijo es pedagogico y debe validarse
con vectores conocidos; no pretende ser una biblioteca criptografica general.
