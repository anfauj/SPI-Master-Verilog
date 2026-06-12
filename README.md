# Parameterizable SPI Master in Verilog

A flexible, fully parameterizable SPI Master module written in Verilog. This design is optimized for interfacing with mixed-signal hardware peripherals, such as DACs and ADCs, requiring precise bit-widths and clock divisions.

## Features
* **Dynamic Sizing:** `DATA_WIDTH` is fully parameterizable (tested at 16-bit).
* **Adjustable Speed:** `CLOCK_DIV_RATIO` allows custom scaling of the system clock to generate the desired SCLK frequency.
* **Efficient Synthesis:** Utilizes `$clog2()` for dynamic register sizing, ensuring no wasted flip-flops in the synthesized hardware.
* **SPI Mode 0:** Configured for CPOL = 0, CPHA = 0 (Data sampled on the rising edge, shifted on the falling edge).

## File Structure
* `spi_master.v` - The core state machine and datapath logic.
* `tb_spi_master.v` - A self-checking testbench that implements behavioral dummy-slave logic to verify MISO/MOSI transactions.

## Simulation & Verification
This project can be simulated locally or via [EDA Playground](https://edaplayground.com/) using **Icarus Verilog**. 

The testbench runs a 16-bit transaction loop. It stimulates the master with a `16'hABCD` payload while a behavioral slave replies with `16'h1234`, verifying cycle-accurate alignment of the physical lines.

### Understanding the Waveforms
The simulation outputs both single-bit physical wires and multi-bit data buses to provide a complete picture of the hardware's behavior:

* **Multi-Bit Buses (The Hexagons):** Signals like `tx_data`, `rx_data`, and the internal shift registers (`slave_tx_reg`) are multi-bit buses. The simulator groups these wires into hexagonal "eyes." The crossed lines represent transition states, while the parallel top/bottom lines represent stable data, displaying the combined hexadecimal value (e.g., `abcd`).
* **Single-Bit Wires (The Flat Lines):** Signals like `sclk`, `mosi`, `miso`, and `cs_n` are physical single-wire representations, showing strict High (`1`) or Low (`0`) voltage states over time.

**Transaction Timeline:**
1. **Trigger:** The active-low reset (`rst_n`) goes high, and the `start` signal pulses for one clock cycle.
2. **Wake-up:** Chip Select (`cs_n`) drops low to initiate the transfer with the peripheral.
3. **Data Exchange:** The generated `sclk` pulses 16 times. On every falling edge, data shifts out on `mosi` and `miso`. On every rising edge, that data is sampled.
4. **Completion:** After 16 cycles, `cs_n` is pulled back high, and the `done` flag pulses to indicate `rx_data` is valid.

### Timing Diagram

---
*Developed for hardware verification and serial communication testing.*