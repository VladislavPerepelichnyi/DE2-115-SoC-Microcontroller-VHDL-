# DE2-115 SoC Microcontroller VHDL
FPGA SoC microcontroller with external flash and UART programming GUI

This repository presents a soft System-on-Chip (SoC) microcontroller implemented in **VHDL** on the **DE2-115 FPGA board**.  
The project includes a RISC-like CPU, memory subsystem, and peripheral interfaces, along with a **Python-based programming utility**.

## Overview

The designed microcontroller is based on a **primitive multi-cycle architecture** that supports easy addition of custom assembly instructions.  
User programs are stored in **non-volatile external flash memory** located on the FPGA board.  
A **simple UART-based loader** enables programming directly from a PC using a Python GUI.

<img width="1264" height="670" alt="image" src="https://github.com/user-attachments/assets/4acd00a6-4489-4d22-b6ff-1a98865a6585" />

