cmake_minimum_required(VERSION 3.20)

project(ch559l_blink C)

# ============================================================
# Project paths
# ============================================================

set(PROJECT_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../..")

set(APP_DIR              "${PROJECT_ROOT}/apps/blink")
set(PLATFORM_DIR         "${PROJECT_ROOT}/platforms/ch559l")
set(RUNTIME_DIR          "${PROJECT_ROOT}/runtimes/baremetal/blink")
set(PLATFORM_RUNTIME_DIR "${PROJECT_ROOT}/platform-runtimes/ch559l/baremetal")
set(TARGET_DIR           "${PROJECT_ROOT}/build-targets/ch559l-baremetal/blink")

# ============================================================
# Include directories
# ============================================================

include_directories(
    "${APP_DIR}/src"
    "${PLATFORM_DIR}/include"
    "${PLATFORM_DIR}/blink"
    "${TARGET_DIR}"
)

# ============================================================
# Firmware
# ============================================================

add_executable(firmware
    "${RUNTIME_DIR}/main.c"
    "${APP_DIR}/src/blink.c"
    "${PLATFORM_DIR}/blink/gpio.c"
    "${PLATFORM_RUNTIME_DIR}/delay.c"
)

# ============================================================
# SDCC options
# ============================================================

target_compile_options(firmware PRIVATE
    -mmcs51
)

target_link_options(firmware PRIVATE
    -mmcs51
)

# ============================================================
# Firmware output
# ============================================================

set_target_properties(firmware PROPERTIES
    OUTPUT_NAME firmware
    SUFFIX .ihx
)

# ============================================================
# HEX generation
# ============================================================

add_custom_command(
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/firmware.hex"

    COMMAND packihx
            "${CMAKE_CURRENT_BINARY_DIR}/firmware.ihx"
            >
            "${CMAKE_CURRENT_BINARY_DIR}/firmware.hex"

    DEPENDS firmware

    COMMENT "Generating firmware.hex"

    VERBATIM
)

# ============================================================
# BIN generation
# ============================================================

add_custom_command(
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/firmware.bin"

    COMMAND sdobjcopy
            -I ihex
            -O binary
            "${CMAKE_CURRENT_BINARY_DIR}/firmware.ihx"
            "${CMAKE_CURRENT_BINARY_DIR}/firmware.bin"

    DEPENDS firmware

    COMMENT "Generating firmware.bin"

    VERBATIM
)

# ============================================================
# Firmware images target
# ============================================================

add_custom_target(firmware_images ALL
    DEPENDS
        "${CMAKE_CURRENT_BINARY_DIR}/firmware.hex"
        "${CMAKE_CURRENT_BINARY_DIR}/firmware.bin"
)