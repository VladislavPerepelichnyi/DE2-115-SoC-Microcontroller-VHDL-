# DE2-115 SoC Microcontroller VHDL
FPGA SoC microcontroller with external flash and UART programming GUI

This repository presents a soft System-on-Chip (SoC) microcontroller implemented in **VHDL** on the **DE2-115 FPGA board**.  
The project includes a  CPU, memory subsystem, and peripheral interfaces, along with a **Python-based programming utility**.

## Overview

The designed microcontroller is based on a **primitive multi-cycle architecture** that supports easy addition of custom assembly instructions.  
User programs are stored in **non-volatile external flash memory** located on the FPGA board.  
A **simple UART-based loader** enables programming directly from a PC using a Python GUI.

## System Architecture
The SoC consists of several main blocks:

- **CPU Core:** Multi-cycle architecture with accumulator-based computation  
- **Memory System:** External flash memory for program storage, internal RAM - buffer and file register for data  
- **Peripherals:** UART interface and hardware timer  
- **Bus System:** Simple address decoding and control logic  
- **Programming Interface:** UART-based flash programmer using Python GUI
  
**The top level :** 

<img width="740" height="410" alt="TL" src="https://github.com/user-attachments/assets/c9d17237-5f44-46d2-bb5f-e5b77c05f16b" />



**CPU structure :** 
<img width="2476" height="1498" alt="CPU" src="https://github.com/user-attachments/assets/43595e75-6bfd-41ba-b5c0-f63ac5b55da0" />

**Timer structure :**
<img width="1357" height="858" alt="TIMER" src="https://github.com/user-attachments/assets/fe7be93d-4269-4d7f-8fb2-a15c9c8029ff" />

**UART structure :**
<img width="2306" height="1521" alt="UART" src="https://github.com/user-attachments/assets/cf3d3582-029c-4604-90c6-faf0f8ca30c3" />



## Get started 
<img width="1509" height="983" alt="image" src="https://github.com/user-attachments/assets/ef98caee-1a88-46c0-a869-d153011722ff" />
 

