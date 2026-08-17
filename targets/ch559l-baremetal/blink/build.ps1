$ErrorActionPreference = "Stop"

# ============================================================
# Project Configuration
# ============================================================

$ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..\").Path.TrimEnd('\')

$TargetDir   = "$ProjectRoot\targets\ch559l-baremetal\blink"
$BuildDir    = "$TargetDir\build"

$AppDir      = "$ProjectRoot\apps\blink"
$AppSrc      = "$AppDir\src"

$PlatformDir = "$ProjectRoot\platforms\ch559l"
$PlatformSrc = "$PlatformDir\blink"

$RuntimeSrc  = "$ProjectRoot\runtimes\baremetal\blink"

$TargetSrc   = $TargetDir

$Image = "safdariali/sdcc-8051:latest"

# ============================================================
# Prepare Build Directory
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
# 0. Unit Test
# ============================================================

Write-Host "========================================"
Write-Host "[0/6] Running unit tests..."
Write-Host "========================================"
Write-Host ""

Push-Location $AppDir

try {
    & ".\run_test.ps1"

    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host ""
        Write-Host ""		
        Write-Host "=========================================================="
        Write-Host "Unit tests failed!"
		Write-Host "Firmware build aborted."
        Write-Host "=========================================================="
        Write-Host ""
        Write-Host ""
        Write-Host ""
		Write-Error "Unit tests failed. Firmware build aborted."
        exit $LASTEXITCODE
    }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "Unit tests passed."
Write-Host ""

New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

# ============================================================
# 1. Compile main.c
# ============================================================

Write-Host "========================================"
Write-Host "[1/6] Compiling main.c..."
Write-Host "========================================"

docker run --rm -it `
    -v "${ProjectRoot}:/workspace" `
    -w /workspace `
    $Image `
    sdcc -mmcs51 `
    -I /workspace/apps/blink/src `
    -I /workspace/platforms/ch559l `
    -I /workspace/platforms/ch559l/blink `
    -I /workspace/targets/ch559l-baremetal/blink `
    -c /workspace/runtimes/baremetal/blink/main.c `
    -o /workspace/targets/ch559l-baremetal/blink/build/main.rel

if ($LASTEXITCODE -ne 0) {
    Write-Error "main.c compilation failed."
    exit $LASTEXITCODE
}

# ============================================================
# 2. Compile blink.c
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host "[2/6] Compiling blink.c..."
Write-Host "========================================"

docker run --rm -it `
    -v "${ProjectRoot}:/workspace" `
    -w /workspace `
    $Image `
    sdcc -mmcs51 `
    -I /workspace/apps/blink/src `
    -I /workspace/platforms/ch559l `
    -I /workspace/platforms/ch559l/blink `
    -I /workspace/targets/ch559l-baremetal/blink `
    -c /workspace/apps/blink/src/blink.c `
    -o /workspace/targets/ch559l-baremetal/blink/build/blink.rel

if ($LASTEXITCODE -ne 0) {
    Write-Error "blink.c compilation failed."
    exit $LASTEXITCODE
}

# ============================================================
# 3. Compile gpio.c
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host "[3/6] Compiling gpio.c..."
Write-Host "========================================"

docker run --rm -it `
    -v "${ProjectRoot}:/workspace" `
    -w /workspace `
    $Image `
    sdcc -mmcs51 `
    -I /workspace/apps/blink/src `
    -I /workspace/platforms/ch559l `
    -I /workspace/platforms/ch559l/blink `
    -I /workspace/targets/ch559l-baremetal/blink `
    -c /workspace/platforms/ch559l/blink/gpio.c `
    -o /workspace/targets/ch559l-baremetal/blink/build/gpio.rel

if ($LASTEXITCODE -ne 0) {
    Write-Error "gpio.c compilation failed."
    exit $LASTEXITCODE
}

# ============================================================
# 4. Compile delay.c
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host "[4/6] Compiling delay.c..."
Write-Host "========================================"

docker run --rm -it `
    -v "${ProjectRoot}:/workspace" `
    -w /workspace `
    $Image `
    sdcc -mmcs51 `
    -I /workspace/apps/blink/src `
    -I /workspace/platforms/ch559l `
    -I /workspace/platforms/ch559l/blink `
    -I /workspace/targets/ch559l-baremetal/blink `
    -c /workspace/targets/ch559l-baremetal/blink/delay.c `
    -o /workspace/targets/ch559l-baremetal/blink/build/delay.rel

if ($LASTEXITCODE -ne 0) {
    Write-Error "delay.c compilation failed."
    exit $LASTEXITCODE
}

# ============================================================
# 5. Link Firmware
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host "[5/6] Linking firmware..."
Write-Host "========================================"

docker run --rm -it `
    -v "${ProjectRoot}:/workspace" `
    -w /workspace `
    $Image `
    sdcc -mmcs51 `
    -I /workspace/apps/blink/src `
    -I /workspace/platforms/ch559l `
    -I /workspace/platforms/ch559l/blink `
    -I /workspace/targets/ch559l-baremetal/blink `
    /workspace/targets/ch559l-baremetal/blink/build/main.rel `
    /workspace/targets/ch559l-baremetal/blink/build/blink.rel `
    /workspace/targets/ch559l-baremetal/blink/build/gpio.rel `
    /workspace/targets/ch559l-baremetal/blink/build/delay.rel `
    -o /workspace/targets/ch559l-baremetal/blink/build/firmware.ihx

if ($LASTEXITCODE -ne 0) {
    Write-Error "Firmware linking failed."
    exit $LASTEXITCODE
}

# ============================================================
# 6. Generate HEX and BIN
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host "[6/6] Generating firmware images..."
Write-Host "========================================"

# ------------------------------------------------------------
# IHX -> HEX
# ------------------------------------------------------------

Write-Host "Generating firmware.hex..."

docker run --rm -it `
    -v "${ProjectRoot}:/workspace" `
    -w /workspace `
    $Image `
    sh -c "packihx /workspace/targets/ch559l-baremetal/blink/build/firmware.ihx > /workspace/targets/ch559l-baremetal/blink/build/firmware.hex"

if ($LASTEXITCODE -ne 0) {
    Write-Error "IHX to HEX conversion failed."
    exit $LASTEXITCODE
}

# ------------------------------------------------------------
# IHX -> BIN
# ------------------------------------------------------------

Write-Host "Generating firmware.bin..."

docker run --rm -it `
    -v "${ProjectRoot}:/workspace" `
    -w /workspace `
    $Image `
    sdobjcopy -I ihex -O binary `
    /workspace/targets/ch559l-baremetal/blink/build/firmware.ihx `
    /workspace/targets/ch559l-baremetal/blink/build/firmware.bin

if ($LASTEXITCODE -ne 0) {
    Write-Error "IHX to BIN conversion failed."
    exit $LASTEXITCODE
}

# ============================================================
# Cleanup
# ============================================================

Write-Host ""
Write-Host "Cleaning temporary build files..."

Get-ChildItem -Path $BuildDir -File |
    Where-Object {
        $_.Name -notin @(
            "firmware.hex",
            "firmware.bin"
        )
    } |
    Remove-Item -Force

# ============================================================
# Final Result
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host " Firmware build completed successfully."
Write-Host "========================================"
Write-Host ""

Get-ChildItem -Path $BuildDir -File |
    Select-Object Name, Length