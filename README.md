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
- **Peripherals:** UART(115200 8N1) interface and hardware timer  
- **Bus System:** Simple address decoding and control logic  
- **Programming Interface:** UART(115200 8N1)-based flash programmer using Python GUI
  
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

**RAM buffer map :**

<img width="676" height="708" alt="ROM map" src="https://github.com/user-attachments/assets/077e6d5d-ae2c-4ac7-8f69-8cf5346f7e87" />

**Programmer structure :**

<img width="1620" height="375" alt="Programmer" src="https://github.com/user-attachments/assets/627b8c6a-f532-43ce-a682-2d5658a15e69" />

**Programmer flowchart :**

<img width="658" height="1090" alt="flowchart Programmer" src="https://github.com/user-attachments/assets/6a7be092-5bd0-4011-a91d-4426ce7a85b1" />



## How to Build and Run
**1. Hardware Setup**

FPGA board: DE2-115

UART-USB cable (RS232): connected to PC serial port and de2-115.

**2. FPGA Synthesis**
Download VHDL_RTL.zip and unzip it.
Press on "microcontroller_noama_vladona" (QPF file)
Compile and program the FPGA

**3. Python programmer-utility**
Download the "softwareutility" directory.
Install the necessary libraries (all libraries are in main.py).
Paste the example program into the "ASSEMBLER" tab.
Click "Compiler," then "Save." The utility saves two types of files: the first is a text string with ones and zeros (not related to programming), and the second is a HEX file (related to programming). Then go to the "PROGRAMMER" tab and press **sw(17)** on the FPGA board (to enter programming mode). Then click "On."

<img width="1509" height="983" alt="image" src="https://github.com/user-attachments/assets/ef98caee-1a88-46c0-a869-d153011722ff" />

<img width="1488" height="831" alt="image" src="https://github.com/user-attachments/assets/a532b1ee-3f47-4ce6-b921-864bb897ae76" />


This program demonstrates the use of all the devices. It uses two types of interrupts (received from the UART receiver and a timer triggered by a comparison), and blinks the resulting character on 7 red LEDs. The character is sent from the PC via UART (use an external terminal such as PuTTY). When SW(1) is raised and then released, the microcontroller transmits the word "hello" to the terminal. Note that blinking is driven by a timer, the combination of LEDs is driven by a receiver interrupt, and polling for SW(1) presses is done by pooling.

Below are assembly mnemonics for writing programs, along with a brief explanation of the peripherals.

The user can also leave comments using "--" (as in VHDL).
**Assembler list**
<img width="599" height="722" alt="image" src="https://github.com/user-attachments/assets/9aa946b2-6c6d-4e8d-8572-b78f6bba18bb" />

<img width="584" height="367" alt="image" src="https://github.com/user-attachments/assets/f1181c54-8ad5-432d-8a5a-d2b83849b518" />
 

