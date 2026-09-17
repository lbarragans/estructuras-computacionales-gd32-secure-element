# Ejercicio 11 - Secure Element y challenge-response

**Curso:** Estructuras Computacionales

**Autora:** Laura Daniela Barragan Silva

**Plataforma:** GD32VW553HMQ6/HMQ7, RISC-V RV32

## Objetivo

Simular autenticacion challenge-response con HMAC-SHA256, comparar el MAC sin
salidas tempranas y rechazar la repeticion de un challenge ya aceptado.

> Es una practica didactica. La clave está dentro del firmware y puede
> extraerse. No sustituye la proteccion fisica ni la API de un ATECC608 real.

## Tres caminos

| Camino | Archivos | Concepto |
|---|---|---|
| Referencia | `Src/main.c`, `Src/secure_element_sim.c`, `Src/sha256.c` | simulador y HMAC-SHA256 en C |
| RISC-V puro | `Ensamblador_RISCV_Puro/main.S` | guion, comparacion y HMAC fijo en Assembly |
| FreeRTOS puro | `FreeRTOS_Puro/main.c` | tarea de autenticacion y Queue de resultados |

La referencia continúa seleccionada por el CMake principal. Las alternativas
son independientes y no se compilan simultaneamente con `Src/main.c`.

## Cinco pruebas

| Paso | Prueba | Resultado |
|---:|---|---|
| 0 | challenge y respuesta validos | aceptada |
| 1 | challenge alterado, respuesta anterior | MAC rechazado |
| 2 | respuesta alterada | MAC rechazado |
| 3 | segundo par valido | aceptada |
| 4 | repeticion del par anterior | replay rechazado |

Al terminar un ciclo se esperan dos aceptaciones, tres rechazos, dos fallas
MAC, un replay y tres respuestas calculadas. PC13 muestra dos pulsos cortos por
aceptacion y uno largo por rechazo.

## Estructura

```text
11_Secure_Element_Challenge_Response/
├── Src/                         # referencia original
├── Inc/
├── Ensamblador_RISCV_Puro/      # aplicacion criptografica RV32
├── FreeRTOS_Puro/               # tareas y Queue de resultados
├── Doc/
├── CMakeLists.txt
└── README.md
```

Los documentos originales `Doc/1_SETUP.md` a `Doc/8_GLOSSARY.md` permanecen.
Las rutas se comparan en `Doc/6_VARIANTES_DEL_EJERCICIO.md` y se verifican con
`Doc/7_PLAN_DE_VALIDACION.md`.

## Estado

| Implementacion | Estado |
|---|---|
| Referencia C | compilada, grabada y validada fisicamente en GD32VW553 |
| Assembly puro | compilada, grabada y validada fisicamente en GD32VW553 |
| FreeRTOS puro | compilada con MSDK V1.0.3g, grabada y validada fisicamente |

## Ejecutar las variantes

Referencia original por JTAG/OpenOCD:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\\tools\\build_variant.ps1 -Variant original -Flash
```

Assembly puro por JTAG/OpenOCD:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\\tools\\build_variant.ps1 -Variant assembly -Flash
```

FreeRTOS usa el port oficial del SDK WiFi V1.0.3g. Desde VS Code seleccione
**Terminal > Run Task > Build + Flash FreeRTOS**. La tarea copia `main.c`,
`app_cfg.h`, `sha256.c` y `sha256.h`, limpia el build compartido, compila
MBL/MSDK y programa `image-all.bin`.

La programacion usa WCH-Link CMSIS-DAP v2 mediante USB bulk, VID:PID
`1A86:8012` y JTAG a 50 kHz.

## Patron visual esperado

- Dos pulsos cortos: autenticacion aceptada.
- Un pulso largo: rechazo por MAC o replay.
- Por ciclo: dos aceptaciones y tres rechazos, seguidos por una pausa.

Las tres variantes reprodujeron este patron en la placa real con WCH-Link.

## Guía central de ejecución

La [guía central GD32VW553](https://github.com/lbarragans/gd32vw553-vscode-cmake-guide)
documenta instalación, conexión, compilación y validación de las variantes.
