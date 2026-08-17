# 5. Solución de problemas

- **No aparece el depurador:** ejecute `6. Preparar depuración`, compruebe que
  existe `.vscode/launch.json` y recargue la ventana.
- **CMake no encuentra GCC:** corrija `NUCLEI_TOOLCHAIN_DIR` y borre `build/`
  antes de volver a configurar.
- **OpenOCD no encuentra CMSIS-DAP:** cierre otras sesiones, reconecte el
  WCH-Link y confirme alimentación y cableado JTAG.
- **El breakpoint no se activa:** compile en Debug y programe el ELF actual.
- **El LED parece extraño:** PC13 es activo en bajo; use los contadores como
  evidencia principal.
- **IntelliSense marca includes del SDK:** configure primero CMake y recargue;
  la compilación real es la fuente de verdad.
- **Los contadores no coinciden:** deténgase exactamente al final del primer
  ciclo y reinicie la sesión para repetir la prueba desde cero.
