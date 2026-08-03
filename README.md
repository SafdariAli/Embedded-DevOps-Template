# Embedded-DevOps-Template

Production-ready Embedded DevOps template for professional firmware development, featuring reproducible Docker toolchains, Test-Driven Development (TDD), GitHub Actions CI/CD, static analysis, code coverage, artifact publishing, and hardware-in-the-loop (HIL) validation for 8-bit and 32-bit microcontrollers and FPGAs.

## Current Progress

### CH559L

* Docker-based SDCC 4.6.2 toolchain
* CH559L platform support
* Hardware Abstraction Layer (HAL) for GPIO and delay
* Blink firmware example
* Ceedling-based unit testing with Unity and CMock
* Reproducible firmware build script
* Firmware linking and binary generation
* `.hex` and `.bin` firmware artifacts
* Firmware successfully programmed and validated on real CH559L hardware

The current CH559L build flow is:

```text
C Source
   ↓
Ceedling / Unit Tests
   ↓
Docker + SDCC
   ↓
Compile
   ↓
Link
   ↓
firmware.hex
firmware.bin
   ↓
CH559L Hardware
```

## Third-Party Components

The CH559 platform currently uses `CH559.h`, derived from the following open-source project:

* Original project: [CH559sdccUSBHost](https://github.com/atc1441/CH559sdccUSBHost)
* Original author: atc1441
* Original license: GNU General Public License v3.0 (GPL-3.0)

This third-party component retains its original licensing terms and is not relicensed under the MIT License of this repository.

## Roadmap

* [ ] Expand CH559L firmware examples
* [ ] Complete automated firmware build pipeline
* [ ] Add GitHub Actions CI/CD
* [ ] Add static analysis and code coverage
* [ ] Add hardware-in-the-loop (HIL) validation
* [ ] Add additional embedded platforms
* [ ] Add 32-bit MCU and FPGA workflows
