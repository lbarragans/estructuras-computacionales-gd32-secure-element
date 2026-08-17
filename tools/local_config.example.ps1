# Copie este archivo como tools/local_config.ps1 y edite las tres rutas.
# tools/local_config.ps1 contiene rutas personales y esta excluido de Git.

$GD32_SDK_ROOT = "C:/path/to/GD32VW55x_Firmware_Library_V1.6.0"

$NUCLEI_TOOLCHAIN_DIR = `
    "C:/path/to/GD32EmbeddedBuilder/Tools/NucleiRISCVGCC/bin"

# Debe apuntar al directorio que contiene bin/ y scripts/.
$OPENOCD_ROOT = `
    "C:/path/to/GD32EmbeddedBuilder/Tools/OpenOCD/xpack-openocd-0.11.0-3"
