# ghal_examples

Example applications demonstrating the Generic Hardware Abstraction Layer
(GHAL) on the **STM32F746G-DISCO**.

## Overview

GHAL splits bare-metal Ada drivers into generic interfaces (`gpio_generic`,
`i2c_generic`, `dc_generic`, `fb_generic`, `touch_generic`, ...), MCU-level
drivers that implement them (`stm32f746`, in the `stm32f746_ghal` repository),
and a board crate that wires the two together for one physical board
(`stm32f746g_disco`).

This repository is the application layer on top of that stack. As shipped, the
manifest builds one example for the STM32F746G-DISCO.

## Primary example: 2048

A playable 2048 on the DISCO's 480x272 RK043FN48H panel: LTDC display
controller, double-buffered framebuffer in external SDRAM, DMA2D fills, FT5336
capacitive touch driving a gesture recognizer, and the hardware RNG for tile
spawning.

**Sources:** `src/demo_2048/`, entry point `src/demo_2048/demo_2048.adb`

## Building

Requires [Alire](https://alire.ada.dev/) 2.0 or newer and git. All GHAL
dependencies are pinned by git URL, so no sibling checkouts or manual index
setup are needed:

```bash
git clone https://github.com/GNAT-Academic-Program/ghal_examples
cd ghal_examples
alr build
```

This cross-compiles for `arm-eabi` and produces `bin/demo_2048`.

## Flashing

```bash
openocd -f board/stm32f746g-disco.cfg \
  -c "program bin/demo_2048 verify reset exit"
```

## Other examples in this repository

The sources below are kept for reference but are **not built by this
manifest**. They target the STM32G4 stack (`nucleo_g431kb` /
`stm32g431_ghal`), not the F746 stack pinned here. Building them means
switching the board dependency and pin in `alire.toml` and selecting the
matching `Main` in `ghal_examples.gpr`, where the full list is kept commented.

### Blinky
Basic LED blinking example demonstrating GPIO output. Targets `nucleo_g431kb`.

**File:** `src/blinky_0.adb`

### I2C Sensor (BMP390)
I2C communication with a BMP390 pressure/temperature sensor. Targets
`nucleo_g431kb`.

**Files:**
- `src/i2c/i2c_bmp.adb` - Main application
- `src/i2c/bmp390.adb` - BMP390 driver
- `src/i2c/bmp.ads` - Sensor interface

### SPI Communication
Basic SPI transfer example. Targets `nucleo_g431kb`.

**File:** `src/spi_0.adb`

### NOR Flash (W25Q128)
SPI NOR flash read/write operations. Targets `nucleo_g431kb`.

**Files:**
- `src/nor_flash/nor_flash_0.adb` - Main application
- `src/nor_flash/w25q128_dev.adb` - W25Q128 device driver
- `src/nor_flash/nor_flash_dev.adb` - Flash device abstraction

## License

MIT OR Apache-2.0 WITH LLVM-exception
