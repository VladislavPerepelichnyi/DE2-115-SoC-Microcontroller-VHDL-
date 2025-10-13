import tkinter as tk
from tkinter import filedialog, messagebox, ttk
import serial
import threading
import time
from intelhex import IntelHex

SERIAL_PORT = 'COM6'
BAUDRATE = 115200
BYTE_TIMEOUT = 5
BYTE_TO_SEND = 768

def open_hex_programmer(parent_frame):

    frame = ttk.Frame(parent_frame, padding=10)
    frame.pack(fill="both", expand=True)

    progress = ttk.Progressbar(frame, length=300, mode='determinate')
    progress.grid(column=0, row=1, pady=10)

    log_box = tk.Text(frame, width=60, height=12)
    log_box.grid(column=0, row=2, pady=10)
    log_box.config(state=tk.DISABLED)

    def log(msg):
        log_box.config(state=tk.NORMAL)
        log_box.insert(tk.END, msg + '\n')
        log_box.see(tk.END)
        log_box.config(state=tk.DISABLED)

    def select_file():
        filepath = filedialog.askopenfilename(filetypes=[("HEX Files", "*.hex")])
        if filepath:
            threading.Thread(target=program_device, args=(filepath,), daemon=True).start()

    def load_hex_file(filepath):
        ih = IntelHex(filepath)
        addresses = sorted(ih.addresses())
        base = addresses[0]
        data = [ih[addr] for addr in range(base, base + BYTE_TO_SEND)]
        return bytes(data)

    def program_device(filepath):
        try:
            hex_data = load_hex_file(filepath)
        except Exception as e:
            messagebox.showerror("Error", f"Failed to parse hex file:\n{e}")
            return

        try:
            ser = serial.Serial(SERIAL_PORT, BAUDRATE, timeout=BYTE_TIMEOUT)
            log(f"[INFO] Serial port {SERIAL_PORT} opened")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to open serial port:\n{e}")
            return

        ser.write(b'S')
        log("[WAIT] Waiting for 'S'...")

        start_time = time.time()
        while time.time() - start_time < BYTE_TIMEOUT:
            if ser.in_waiting:
                received = ser.read(1)
                log(f"[RECV] {received.hex()}")
                if received == b'S':
                    break
        else:
            ser.close()
            log("[ERROR] 'S' not received within timeout.")
            messagebox.showerror("Programming Error", "No 'S' received from device.")
            return

        log("[SEND] Starting data transmission...")
        progress["maximum"] = len(hex_data)

        for i, byte in enumerate(hex_data):
            if i < 8:
                time.sleep(0.5)
            else:
                time.sleep(0.001)
            ser.write(bytes([byte]))
            log(f"[SEND] {byte:02X}")
            progress["value"] = i + 1
            frame.update_idletasks()

        log("[WAIT] Waiting for 'F'...")
        start_time = time.time()
        while time.time() - start_time < BYTE_TIMEOUT:
            if ser.in_waiting:
                received = ser.read(1)
                log(f"[RECV] {received.hex()}")
                if received == b'F':
                    ser.close()
                    log("[DONE] Programming complete.")
                    messagebox.showinfo("Success", "Programming complete.")
                    return

        ser.close()
        log("[ERROR] 'F' not received after transmission.")
        messagebox.showerror("Programming Error", "No 'F' received after transmission.")

    select_btn = ttk.Button(frame, text="Select HEX File", command=select_file)
    select_btn.grid(column=0, row=0, pady=5)
