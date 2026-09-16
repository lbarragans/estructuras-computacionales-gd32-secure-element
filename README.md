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
| Referencia C | funcional y seleccionada por CMake |
| Assembly puro | fuente pedagogica lista; integracion y vectores pendientes |
| FreeRTOS puro | fuente lista; kernel, port e integracion pendientes |
