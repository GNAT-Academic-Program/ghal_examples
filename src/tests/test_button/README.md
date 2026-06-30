# Button Test Firmware

Portable button test firmware for GHAL-based boards.

## Description

This test firmware demonstrates and validates button input functionality across different board implementations. It:

- Detects button presses using edge detection
- Toggles the LED on each button press
- Counts and logs button presses to the console
- Implements basic debouncing (50ms delay)

## Features

- **Portable**: Works on any board that implements `Board.Button` and `Board.Led`
- **Edge Detection**: Only triggers on button press (rising edge), not continuous hold
- **Visual Feedback**: LED toggles on each press
- **Console Logging**: Press count and LED state logged via UART
- **Debouncing**: 50ms delay prevents multiple triggers from mechanical bounce

## Supported Boards

- STM32F746G-DISCO (button on PI11)
- STM32F469I-DISCO (button on PA0)
- Any board implementing the GHAL Board API with button support

## Building

To build for your target board:

```bash
cd ghal_examples
alire build
```

Or edit `ghal_examples.gpr` to set the main:

```ada
for Main use ("test_button.adb");
```

## Expected Output

```
===========================================
  Button Test Firmware
===========================================
Press the user button to toggle the LED.
Button presses are counted and logged.

Button pressed! Count= 1, LED=ON
Button pressed! Count= 2, LED=OFF
Button pressed! Count= 3, LED=ON
...
```

## Hardware Requirements

- Board with user button (typically blue button)
- Board with user LED (typically green LED)
- UART console connection (ST-LINK VCP)

## Usage

1. Flash the firmware to your board
2. Connect to the UART console (115200 baud)
3. Press the user button
4. Observe LED toggling and console messages

## Implementation Notes

- Uses `Board.Button_Pressed` function for portable button reading
- Uses `Gpio.Set` and `Gpio.Clear` for LED control
- Uses `Ada.Real_Time` for precise timing and debouncing
- Edge detection prevents continuous triggering while button is held
