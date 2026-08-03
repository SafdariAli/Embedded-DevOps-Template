$ErrorActionPreference = "Stop"

$ProjectRoot = "J:\ch559l\MyProjectinGit\Embedded-DevOps-Template"
$BuildDir = "$ProjectRoot\firmware\platform\ch559l\build"
$Image = "safdariali/sdcc-8051:latest"

New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

Write-Host "========================================"
Write-Host " CH559L Firmware Build"
Write-Host "========================================"
Write-Host "Project : $ProjectRoot"
Write-Host "Build   : $BuildDir"
Write-Host "Image   : $Image"
Write-Host ""

# ----------------------------------------

# 1. main.c

# ----------------------------------------

Write-Host "[1/4] Compiling main.c..."

docker run --rm -it -v "J:\ch559l\MyProjectinGit\Embedded-DevOps-Template:/workspace" -w /workspace $Image sdcc -mmcs51 -I /workspace/firmware/platform/ch559l -I /workspace/firmware/platform/ch559l/hal -I /workspace/examples/blink/src -c /workspace/firmware/src/main.c -o /workspace/firmware/platform/ch559l/build/main.rel

if ($LASTEXITCODE -ne 0) {
Write-Error "main.c compilation failed."
exit $LASTEXITCODE
}

# ----------------------------------------

# 2. blink.c

# ----------------------------------------

Write-Host "[2/4] Compiling blink.c..."

docker run --rm -it -v "J:\ch559l\MyProjectinGit\Embedded-DevOps-Template:/workspace" -w /workspace $Image sdcc -mmcs51 -I /workspace/firmware/platform/ch559l -I /workspace/firmware/platform/ch559l/hal -I /workspace/examples/blink/src -c /workspace/examples/blink/src/blink.c -o /workspace/firmware/platform/ch559l/build/blink.rel

if ($LASTEXITCODE -ne 0) {
Write-Error "blink.c compilation failed."
exit $LASTEXITCODE
}

# ----------------------------------------

# 3. gpio.c

# ----------------------------------------

Write-Host "[3/4] Compiling gpio.c..."

docker run --rm -it -v "J:\ch559l\MyProjectinGit\Embedded-DevOps-Template:/workspace" -w /workspace $Image sdcc -mmcs51 -I /workspace/firmware/platform/ch559l -I /workspace/firmware/platform/ch559l/hal -c /workspace/firmware/platform/ch559l/hal/gpio.c -o /workspace/firmware/platform/ch559l/build/gpio.rel

if ($LASTEXITCODE -ne 0) {
Write-Error "gpio.c compilation failed."
exit $LASTEXITCODE
}

# ----------------------------------------

# 4. delay.c

# ----------------------------------------

Write-Host "[4/4] Compiling delay.c..."

docker run --rm -it -v "J:\ch559l\MyProjectinGit\Embedded-DevOps-Template:/workspace" -w /workspace $Image sdcc -mmcs51 -I /workspace/firmware/platform/ch559l -I /workspace/firmware/platform/ch559l/hal -c /workspace/firmware/platform/ch559l/hal/delay.c -o /workspace/firmware/platform/ch559l/build/delay.rel

if ($LASTEXITCODE -ne 0) {
Write-Error "delay.c compilation failed."
exit $LASTEXITCODE
}

Write-Host ""
Write-Host "========================================"
Write-Host " All sources compiled successfully."
Write-Host "========================================"
Write-Host ""

Get-ChildItem "$BuildDir*.rel" | Select-Object Name, Length

# ----------------------------------------
# 5. Link firmware
# ----------------------------------------

Write-Host "[5/5] Linking firmware..."

docker run --rm -it `
  -v "J:\ch559l\MyProjectinGit\Embedded-DevOps-Template:/workspace" `
  -w /workspace `
  $Image `
  sdcc -mmcs51 `
  -I /workspace/firmware/platform/ch559l `
  -I /workspace/firmware/platform/ch559l/hal `
  -I /workspace/examples/blink/src `
  /workspace/firmware/platform/ch559l/build/main.rel `
  /workspace/firmware/platform/ch559l/build/blink.rel `
  /workspace/firmware/platform/ch559l/build/gpio.rel `
  /workspace/firmware/platform/ch559l/build/delay.rel `
  -o /workspace/firmware/platform/ch559l/build/firmware.ihx

if ($LASTEXITCODE -ne 0) {
    Write-Error "Firmware linking failed."
    exit $LASTEXITCODE
}
# ----------------------------------------
# 6. Convert IHX to HEX and BIN
# ----------------------------------------

Write-Host "[6/6] Converting firmware.ihx -> firmware.hex..."

docker run --rm -it `
  -v "J:\ch559l\MyProjectinGit\Embedded-DevOps-Template:/workspace" `
  -w /workspace `
  $Image `
  sh -c "packihx /workspace/firmware/platform/ch559l/build/firmware.ihx > /workspace/firmware/platform/ch559l/build/firmware.hex"

if ($LASTEXITCODE -ne 0) {
    Write-Error "IHX to HEX conversion failed."
    exit $LASTEXITCODE
}

Write-Host "[6/6] Converting firmware.ihx -> firmware.bin..."

docker run --rm -it `
  -v "J:\ch559l\MyProjectinGit\Embedded-DevOps-Template:/workspace" `
  -w /workspace `
  $Image `
  sdobjcopy -I ihex -O binary `
  /workspace/firmware/platform/ch559l/build/firmware.ihx `
  /workspace/firmware/platform/ch559l/build/firmware.bin

if ($LASTEXITCODE -ne 0) {
    Write-Error "IHX to BIN conversion failed."
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "========================================"
Write-Host " Firmware build completed successfully."
Write-Host "========================================"
Write-Host ""

Get-ChildItem "$BuildDir\firmware.*" |
    Select-Object Name, Length
# ----------------------------------------
# 7. Cleanup build directory
# ----------------------------------------

Write-Host "[7/7] Cleaning temporary build files..."

Get-ChildItem -Path $BuildDir -File |
    Where-Object {
        $_.Name -notin @("firmware.hex", "firmware.bin")
    } |
    Remove-Item -Force

Write-Host ""
Write-Host "========================================"
Write-Host " Firmware build completed successfully."
Write-Host "========================================"
Write-Host ""

Get-ChildItem -Path $BuildDir -File |
    Select-Object Name, Length