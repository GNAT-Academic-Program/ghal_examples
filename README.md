# ghal_examples

Example applications demonstrating the Generic Hardware Abstraction Layer (GHAL) for STM32 microcontrollers.

## Overview

This repository contains working examples that demonstrate how to use the GHAL ecosystem for bare-metal Ada development on STM32 boards. Examples cover GPIO, SPI, I2C, USART, and NOR flash operations.

## Examples

### Blinky
Basic LED blinking example demonstrating GPIO output.

**File:** `src/blinky_0.adb`

### I2C Sensor
I2C communication with BMP390 pressure/temperature sensor.

**Files:**
- `src/i2c/i2c_bmp.adb` - Main application
- `src/i2c/bmp390.adb` - BMP390 driver
- `src/i2c/bmp.ads` - Sensor interface

### SPI Communication
Basic SPI transfer example.

**File:** `src/spi_0.adb`

### NOR Flash
SPI NOR flash (W25Q128) read/write operations.

**Files:**
- `src/nor_flash/nor_flash_0.adb` - Main application
- `src/nor_flash/w25q128_dev.adb` - W25Q128 device driver
- `src/nor_flash/nor_flash_dev.adb` - Flash device abstraction

## Building

```bash
alr build
```

## Flashing

### STM32G4 (Nucleo-G431KB)

```bash
openocd -f interface/stlink.cfg -f target/stm32g4x.cfg \
  -c "program bin/blinky_0 verify reset exit"
```

### STM32F7 (STM32F746G-DISCO)

```bash
openocd -f interface/stlink.cfg -f target/stm32f7x.cfg \
  -c "program bin/i2c_bmp verify reset exit"
```

## Supported Boards

- STM32 Nucleo-G431KB
- STM32F746G-DISCO

## Dependencies

- `nucleo_g431kb` or `stm32f746g_disco` - Board support package
- `stm32g431` or `stm32f746` - MCU HAL
- Generic peripheral interfaces (gpio_generic, spi_generic, i2c_generic, usart_generic)

## License

MIT OR Apache-2.0 WITH LLVM-exception
