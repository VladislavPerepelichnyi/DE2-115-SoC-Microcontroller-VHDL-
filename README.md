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
  
### The top level :

<img width="370" height="205" alt="TL" src="https://github.com/user-attachments/assets/14fbd6f2-7f3e-4e6d-aa51-9bdf3deac421" />




## CPU structure : 

<img width="1015" height="508" alt="CPU" src="https://github.com/user-attachments/assets/6332a42e-5ceb-4832-8905-f8f7d9815579" />




**Timer structure :**

<img width="500" height="329" alt="TIMER (1)" src="https://github.com/user-attachments/assets/d1f6915f-d522-46d8-b54e-0ef4184e9ad2" />




**UART structure :**

<img width="493" height="325" alt="UART" src="https://github.com/user-attachments/assets/dc6e1665-0bc9-4890-a8cd-d5f5a2f42a67" />


**Loader structure :**

<img width="510" height="553" alt="BOOTLOADER" src="https://github.com/user-attachments/assets/5b7f5635-7d4f-462e-9c4f-6520dad870f7" />

**RAM buffer map :**

<img width="676" height="708" alt="ROM map" src="https://github.com/user-attachments/assets/077e6d5d-ae2c-4ac7-8f69-8cf5346f7e87" />

**Programmer structure :**

<img width="1620" height="375" alt="Programmer" src="https://github.com/user-attachments/assets/627b8c6a-f532-43ce-a682-2d5658a15e69" />

**Programmer flowchart :**

<img width="658" height="1090" alt="flowchart Programmer" src="https://github.com/user-attachments/assets/6a7be092-5bd0-4011-a91d-4426ce7a85b1" />



## How to Build and Run
### 1. Hardware Setup
- **FPGA board:** DE2-115  
- **UART-USB cable (RS-232):** connect between PC serial port and DE2-115 UART port  

### 2. FPGA Synthesis
1. Download and unzip `VHDL_RTL.zip`.  
2. Open the `microcontroller_noama_vladona.qpf` project file in Quartus.  
3. Compile and program the FPGA.  

### 3. Python Programming Utility
1. Download the `software_utility` directory.  
2. Install required Python libraries (listed in `main.py`).  
3. Open the GUI tool:  
   - Paste your assembly program into the **ASSEMBLER** tab.  
   - Click **Compile**, then **Save**.  
     The tool generates:
     - A binary text representation (for reference)  
     - A **HEX file** for programming  
   - Switch the FPGA into programming mode by pressing **SW(17)** on the board.  
   - Go to the **PROGRAMMER** tab and click **Select HEX file** to begin programming.

## Example Application
The provided demonstration program uses both UART and timer interrupts.  
It receives a character from the PC terminal (e.g., PuTTY) and blinks the corresponding pattern on **7 red LEDs**.  
When **SW(1)** is pressed and released, the microcontroller transmits the word **“hello”** via UART.

- **Timer interrupt:** drives LED blinking  
- **UART receiver interrupt:** updates LED pattern  
- **SW(1) polling:** detects button presses in software  

Comments can be inserted using `--` (as in VHDL).

<img width="1509" height="983" alt="image" src="https://github.com/user-attachments/assets/ef98caee-1a88-46c0-a869-d153011722ff" />

<img width="1488" height="831" alt="image" src="https://github.com/user-attachments/assets/a532b1ee-3f47-4ce6-b921-864bb897ae76" />




## Assembler list

<img width="599" height="722" alt="image" src="https://github.com/user-attachments/assets/9aa946b2-6c6d-4e8d-8572-b78f6bba18bb" />

<img width="584" height="367" alt="image" src="https://github.com/user-attachments/assets/f1181c54-8ad5-432d-8a5a-d2b83849b518" />

## Acknowledgments
Developed by **Noam Alon** and **Vladislav Perepelichnyi**  
Faculty of Electrical Engineering,  
**Holon Institute of Technology, Israel**.
 

