# DE2-115 SoC Microcontroller VHDL
FPGA SoC microcontroller with external flash and UART programming GUI
# About
This repository presents a soft SoC microcontroller implemented on FPGA.

Key features:

Primitive multi-cycle architecture designed for easy extension with custom assembly instructions.

Non-volatile external flash memory located on the DE2-115 board for storing user programs.

Two hard-vector interrupt interfaces (fixed routine addresses) implemented for UART and timer modules.

A lightweight Python utility for assembling mnemonics into machine code and programming the device via UART.
