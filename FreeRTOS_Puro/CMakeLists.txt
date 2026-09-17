cmake_minimum_required(VERSION 3.15)

# Aplicacion MSDK: el SDK oficial ya define TARGET_EXE, toolchain, linker,
# FreeRTOS, port Nuclei/ECLIC, heap y tick.
include_directories(BEFORE ${CMAKE_CURRENT_SOURCE_DIR})

target_sources(${TARGET_EXE}
    PRIVATE
        main.c
        sha256.c
)
