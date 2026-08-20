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
$TargetDir = "$ProjectRoot\build-targets\windows\blink"
$BuildDir  = "$TargetDir\build"
$AppDir    = "$ProjectRoot\apps\blink"

# Docker paths
$DockerTargetDir = "/workspace/build-targets/windows/blink"

# Docker image
$Image = "embedded-windows-build"

# Dockerfile
$Dockerfile = "$TargetDir\Dockerfile"


# ============================================================
# Ensure Docker Image Exists
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host " Windows Build Environment"
Write-Host "========================================"
Write-Host ""
Write-Host "Image : $Image"
Write-Host ""

$imageId = docker images -q $Image 2>$null

if ([string]::IsNullOrWhiteSpace($imageId)) {

    Write-Host "Docker image not found."
    Write-Host "Building image..."
    Write-Host ""

    docker build `
        -t $Image `
        -f $Dockerfile `
        $ProjectRoot

    if ($LASTEXITCODE -ne 0) {

        Write-Error "Docker image build failed."
        exit $LASTEXITCODE
    }

    Write-Host ""
    Write-Host "Docker image built successfully."
    Write-Host ""
}
else {

    Write-Host "Docker image already exists."
    Write-Host "Skipping image build."
    Write-Host ""
}
# ============================================================
# Verify Build Tools
# ============================================================

Write-Host "========================================"
Write-Host "Verifying build tools..."
Write-Host "========================================"
Write-Host ""

docker run --rm `
    $Image `
    sh -c "cmake --version && ninja --version && x86_64-w64-mingw32-gcc --version"

if ($LASTEXITCODE -ne 0) {

    Write-Error "Build tool verification failed."
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Build tools verified successfully."
Write-Host ""


# ============================================================
# Clean
# ============================================================

if ($Command -eq "clean") {

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Windows / Baremetal / Blink Clean"
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
Write-Host " Windows / Baremetal / Blink Build"
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
        Write-Host "Windows build aborted."
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
    "-DCMAKE_TOOLCHAIN_FILE=/workspace/cmake/windows.cmake"

if ($LASTEXITCODE -ne 0) {

    Write-Error "CMake configuration failed."
    exit $LASTEXITCODE
}


# ============================================================
# 3. Build Windows Application
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host "[3/3] Building Windows application..."
Write-Host "========================================"
Write-Host ""

docker run --rm `
    -v "${ProjectRoot}:/workspace" `
    -w $DockerTargetDir `
    $Image `
    cmake --build build

if ($LASTEXITCODE -ne 0) {

    Write-Error "Windows application build failed."
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

Get-ChildItem -Path $BuildDir -File -Filter "*.exe" |
    Select-Object Name, Length

Write-Host ""