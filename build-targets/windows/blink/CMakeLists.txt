cmake_minimum_required(VERSION 3.20)

project(windows_blink C)

# ============================================================
# Project paths
# ============================================================

set(PROJECT_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../..")

set(APP_DIR              "${PROJECT_ROOT}/apps/blink")
set(PLATFORM_DIR         "${PROJECT_ROOT}/platforms/windows")
set(RUNTIME_DIR          "${PROJECT_ROOT}/runtimes/baremetal/blink")
set(PLATFORM_RUNTIME_DIR "${PROJECT_ROOT}/platform-runtimes/windows/baremetal")
set(TARGET_DIR           "${PROJECT_ROOT}/build-targets/windows/blink")

# ============================================================
# Include directories
# ============================================================

include_directories(
    "${APP_DIR}/src"
    "${PLATFORM_DIR}/blink"
    "${TARGET_DIR}"
)

# ============================================================
# Windows Application
# ============================================================

add_executable(blink
    "${RUNTIME_DIR}/main.c"
    "${APP_DIR}/src/blink.c"
    "${PLATFORM_DIR}/blink/gpio.c"
    "${PLATFORM_RUNTIME_DIR}/delay.c"
)

# ============================================================
# Windows libraries
# ============================================================

target_link_libraries(blink PRIVATE
    ws2_32
)

# ============================================================
# Application output
# ============================================================

set_target_properties(blink PROPERTIES
    OUTPUT_NAME blink
    SUFFIX .exe
)