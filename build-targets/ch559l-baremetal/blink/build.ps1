param(
    [ValidateSet("clean")]
    [string]$Command
)

$ErrorActionPreference = "Stop"

# ============================================================
# Project Configuration
# ============================================================

$ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..\").Path.TrimEnd('\')

# Host paths
$TargetDir = "$ProjectRoot\build-targets\ch559l-baremetal\blink"
$BuildDir  = "$TargetDir\build"
$AppDir    = "$ProjectRoot\apps\blink"

# Docker paths
$DockerTargetDir = "/workspace/build-targets/ch559l-baremetal/blink"
$DockerToolchain = "/workspace/cmake/ch559l-sdcc.cmake"

# Docker image
$Image = "safdariali/sdcc-8051:cmake"


# ============================================================
# Clean
# ============================================================

if ($Command -eq "clean") {

    Write-Host ""
    Write-Host "========================================"
    Write-Host " CH559L / Baremetal / Blink Clean"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Build : $BuildDir"
    Write-Host ""

    if (-not (Test-Path $BuildDir)) {

        Write-Host "Build directory does not exist."
        Write-Host "Nothing to clean."
        Write-Host ""

        exit 0
    }

    Write-Host "Running Ninja clean..."
    Write-Host ""

    docker run --rm `
        -v "${ProjectRoot}:/workspace" `
        -w $DockerTargetDir `
        $Image `
        ninja -C build clean

    if ($LASTEXITCODE -ne 0) {

        Write-Error "Ninja clean failed."
        exit $LASTEXITCODE
    }

    Write-Host ""
    Write-Host "Clean completed successfully."
    Write-Host ""

    exit 0
}


# ============================================================
# Build Information
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host " CH559L / Baremetal / Blink Build"
Write-Host "========================================"
Write-Host "Project : $ProjectRoot"
Write-Host "Target  : $TargetDir"
Write-Host "Build   : $BuildDir"
Write-Host "Image   : $Image"
Write-Host ""


# ============================================================
# 1. Unit Tests
# ============================================================

Write-Host "========================================"
Write-Host "[1/3] Running unit tests..."
Write-Host "========================================"
Write-Host ""

Push-Location $AppDir

try {

    & ".\run_test.ps1"

    if ($LASTEXITCODE -ne 0) {

        Write-Host ""
        Write-Host "=========================================================="
        Write-Host "Unit tests failed!"
        Write-Host "Firmware build aborted."
        Write-Host "=========================================================="
        Write-Host ""

        exit $LASTEXITCODE
    }

}
finally {

    Pop-Location
}

Write-Host ""
Write-Host "Unit tests passed."
Write-Host ""


# ============================================================
# 2. CMake Configure
# ============================================================

Write-Host "========================================"
Write-Host "[2/3] Configuring CMake..."
Write-Host "========================================"
Write-Host ""

docker run --rm `
    -v "${ProjectRoot}:/workspace" `
    -w $DockerTargetDir `
    $Image `
    cmake -S . -B build -G Ninja `
    "-DCMAKE_TOOLCHAIN_FILE=$DockerToolchain"

if ($LASTEXITCODE -ne 0) {

    Write-Error "CMake configuration failed."
    exit $LASTEXITCODE
}


# ============================================================
# 3. Build Firmware
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host "[3/3] Building firmware..."
Write-Host "========================================"
Write-Host ""

docker run --rm `
    -v "${ProjectRoot}:/workspace" `
    -w $DockerTargetDir `
    $Image `
    cmake --build build

if ($LASTEXITCODE -ne 0) {

    Write-Error "Firmware build failed."
    exit $LASTEXITCODE
}


# ============================================================
# Final Result
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host " Build completed successfully."
Write-Host "========================================"
Write-Host ""

Get-ChildItem -Path $BuildDir -File |
    Where-Object {
        $_.Name -in @(
            "firmware.ihx",
            "firmware.hex",
            "firmware.bin"
        )
    } |
    Select-Object Name, Length

Write-Host ""