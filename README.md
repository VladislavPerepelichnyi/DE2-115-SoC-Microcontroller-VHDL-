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
<img width="2029" height="1016" alt="CPU" src="https://github.com/user-attachments/assets/674de43e-146b-4163-a788-99e2dc7276bd" />


**Timer structure :**
<img width="973" height="640" alt="TIMER (1)" src="https://github.com/user-attachments/assets/f69549f4-a68f-4cfd-a241-96b0095f393d" />



**UART structure :**
<img width="1971" height="1300" alt="UART" src="https://github.com/user-attachments/assets/ce17cc07-249b-4d54-b40d-746206d5e0c4" />

**Loader structure :**
<img width="1021" height="1107" alt="BOOTLOADER" src="https://github.com/user-attachments/assets/5b7f5635-7d4f-462e-9c4f-6520dad870f7" />




## Get started 
<img width="1509" height="983" alt="image" src="https://github.com/user-attachments/assets/ef98caee-1a88-46c0-a869-d153011722ff" />
 

