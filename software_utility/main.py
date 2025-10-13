import time
import tkinter as tk
from tkinter import scrolledtext, filedialog, messagebox
from tkinter import ttk
from tkinter import *
#customic modules
from compile_MMU import *
from simulator_MMU import *
from programmer_MMU import *

from time import sleep
from PIL import Image, ImageTk
from tkinter import PhotoImage
Error_flag = 0
sim = 0

current_step = 0

from intelhex import IntelHex

def convert_bin_to_ihex(bin_lines, save_path):
    ih = IntelHex()
    address = 0

    for line in bin_lines:
        line = line.strip()
        if len(line) != 24:
            continue

        reversed_bits = line[::-1]
        bytes_list = [
            int(reversed_bits[i:i+8][::-1], 2)
            for i in range(0, 24, 8)
        ]

        for byte in bytes_list:
            ih[address] = byte
            address += 1

    ih.write_hex_file(save_path)
    print(f"HEX file saved: {save_path}")

def ask_and_save(hex_lines):
    save_path = filedialog.asksaveasfilename(
        defaultextension=".hex",
        filetypes=[("HEX files", "*.hex")]
    )
    if save_path:
        lines = hex_lines.strip().splitlines()
        convert_bin_to_ihex(lines, save_path)









# Save function
def save_to_file():
    global Error_flag
    input_code = numbered_text.text_area.get("1.0", tk.END).strip()
    binary_data = binary_output.get("1.0", tk.END).strip()
    formatted_code = formatted_code_output.get("1.0", tk.END).strip()
    if (Error_flag == 0):
        save_path = filedialog.asksaveasfilename(defaultextension=".txt", filetypes=[("Text files", "*.txt")])
        #print(type(binary_data))
        #print(binary_data)
        ask_and_save(binary_data)
        if save_path:
            with open(save_path, "w") as file:
               # file.write("Assembly Code (Input):\n")
               # file.write(input_code + "\n\n")
               # file.write("Binary Instructions:\n")
                file.write(binary_data + "\n\n")
               #file.write("Formatted Code:\n")
               # file.write(formatted_code)
            messagebox.showinfo("Save", f"File saved successfully at {save_path}")
    else:
        messagebox.showerror("Error", f"File can not be saved")



class NumberedText(tk.Frame):
    def __init__(self, parent, **kwargs):
        super().__init__(parent)
        self.line_numbers = tk.Text(self, width=4, padx=5, bg="lightgrey", state="disabled")
        self.line_numbers.pack(side="left", fill="y")
        self.text_area = scrolledtext.ScrolledText(self, wrap="none", **kwargs)
        self.text_area.pack(side="right", fill="both", expand=True)
        self.text_area.bind("<KeyRelease>", self.update_line_numbers)
        self.text_area.bind("<MouseWheel>", self.update_line_numbers)

    def update_line_numbers(self, event=None):
        self.line_numbers.config(state="normal")
        self.line_numbers.delete("1.0", "end")
        current_lines = self.text_area.index("end-1c").split(".")[0]
        line_numbers = "\n".join(str(i) for i in range(1, int(current_lines)))
        self.line_numbers.insert("1.0", line_numbers)
        self.line_numbers.config(state="disabled")





# Main window setup
window = tk.Tk()
window.title("ASSEMBLER MICROCONTROLLER")
window.geometry("1000x600")
window.configure(bg="lightblue")

# Tabs setup
tab_control = ttk.Notebook(window)
tab1 = ttk.Frame(tab_control)
tab2 = ttk.Frame(tab_control)
tab3 = ttk.Frame(tab_control)
tab_control.add(tab1, text="CODE")
tab_control.add(tab2, text="SIMULATOR")
tab_control.add(tab3, text="PROGRAMER")
tab_control.pack(expand=1, fill="both")

# CODE tab 1
numbered_text = NumberedText(tab1, font=("Courier", 12))
numbered_text.place(relx=0, rely=0, relwidth=0.35, relheight=1)

binary_output_label = tk.Label(tab1, text="BINARY OUTPUT:", font=("Calibri", 14), bg="lightblue")
binary_output_label.place(relx=0.35, rely=0.15, relwidth=0.2, relheight=0.1)

formatted_code_output = scrolledtext.ScrolledText(tab1, font=("Calibri", 14))
formatted_code_output.place(relx=0.35, rely=0.65, relwidth=0.6, relheight=0.3)

binary_output = scrolledtext.ScrolledText(tab1, font=("Calibri", 14))
binary_output.place(relx=0.35, rely=0.25, relwidth=0.6, relheight=0.3)

formatted_code_label = tk.Label(tab1, text="FORMATTED CODE:", font=("Calibri", 14), bg="lightblue")
formatted_code_label.place(relx=0.35, rely=0.55, relwidth=0.2, relheight=0.1)

def on_compile():
    global Error_flag# если переменная глобальная
    Error_flag = compile_function(numbered_text, binary_output, formatted_code_output)



btn_compile = tk.Button(tab1, text="COMPILE", bg="lightblue", width=20,
                         command = lambda : on_compile(), font=("Calibri", 14))
btn_compile.place(relx=0.35, rely=0, relwidth=0.15, relheight=0.1)

#CODE tab3
image = Image.open("MMU.jpg")  # или .png, .bmp и т.п.
image = image.resize((300, 200))  # при необходимости изменить размер
photo = ImageTk.PhotoImage(image)
open_hex_programmer(tab3)
# Помещаем в Label внутри нужной вкладки
label = tk.Label(tab3, image=photo)
label.image = photo  # важно: сохранить ссылку, иначе изображение пропадёт
label.place(relx=0.5, rely = 0.1)
#btn_flash = tk.Button(tab3, text = "FLASH",  bg="lightblue", width=20, command= lambda: open_hex_programmer(tab3))
#btn_flash.place(relx=0.1, rely=0.1, relwidth=0.15, relheight=0.1)















# CODE tab 2
#register A
a_reg = Entry(tab2,font=("Calibri", 10))
a_reg.place(relx = 0.7 , rely = 0.15, relwidth=0.1, relheight = 0.05)
areg_label= Label(tab2, text="A REGISTER", font=("Calibri", 10))
areg_label.place(relx = 0.7, rely = 0.05, relwidth=0.1, relheight = 0.1)
#register B
b_reg = Entry(tab2,font=("Calibri", 10))
b_reg.place(relx = 0.8 , rely = 0.15, relwidth=0.1, relheight = 0.05)
breg_label= Label(tab2, text="B REGISTER", font=("Calibri", 10))
breg_label.place(relx = 0.8, rely = 0.05, relwidth=0.1, relheight = 0.1)
#IR AR DR
ir_reg = Entry(tab2,font=("Calibri", 10))
ir_reg.place(relx = 0.2, rely = 0.15, relwidth=0.1, relheight = 0.05)
ireg_label= Label(tab2, text="IR", font=("Calibri", 10))
ireg_label.place(relx = 0.2, rely = 0.05, relwidth=0.05, relheight = 0.1)

adr_reg = Entry(tab2,font=("Calibri", 10))
adr_reg.place(relx=0.3, rely=0.15, relwidth=0.1, relheight=0.05)
adreg_label= Label(tab2, text="AR", font=("Calibri", 10))
adreg_label.place(relx=0.3, rely=0.05, relwidth=0.05, relheight=0.1)

dr_reg = Entry(tab2,font=("Calibri", 10))
dr_reg.place(relx = 0.4 , rely = 0.15, relwidth=0.1, relheight = 0.05)
dreg_label= Label(tab2, text="DR", font=("Calibri", 10))
dreg_label.place(relx = 0.4, rely = 0.05, relwidth=0.05, relheight = 0.1)

#RAM

rows = 16
columns = 16

# Создаем таблицу RAM
column_names = [f"Byte {i}" for i in range(columns)]  # Названия столбцов

# Создаем таблицу с 16 столбцами
ram_table = ttk.Treeview(tab2, columns=column_names, show="headings", height=rows)

# Настроим заголовки столбцов
for col in column_names:
    ram_table.heading(col, text=col)

# Настроим ширину всех столбцов
for col in column_names:
    ram_table.column(col, width=50, anchor="center")

# Заполняем таблицу 16x16 ячейками с начальными значениями 0
for row in range(rows):
    values = [f"0x{(0):02X}" for col in range(columns)]
    ram_table.insert("", "end", iid=row, values=values)

# Устанавливаем таблицу на вкладке
ram_table.place(relx=0, rely=0.4, relwidth=0.8, relheight=0.8)
#ROM output
ROM_output = Entry(tab2,font=("Calibri", 10))
ROM_output.place(relx = 0 , rely = 0.15, relwidth=0.2, relheight = 0.05)
ROM_output_label= Label(tab2, text="ROM output", font=("Calibri", 10))
ROM_output_label.place(relx = 0, rely = 0.05, relwidth=0.1, relheight = 0.1)
#PC output
PC_output = Entry(tab2,font=("Calibri", 10))
PC_output.place(relx = 0 , rely = 0.25, relwidth=0.1, relheight = 0.05)
PC_output_label = Label(tab2, text="PC output", font=("Calibri", 10))
PC_output_label.place(relx = 0, rely = 0.2, relwidth=0.1, relheight = 0.05)
#RAR
RARreg = Entry(tab2,font=("Calibri", 10))
RARreg.place(relx = 0.5 ,  rely = 0.15, relwidth=0.1, relheight = 0.05)
RARreg_label = Label(tab2, text="RAR", font=("Calibri", 10))
RARreg_label.place(relx = 0.5, rely = 0.05, relwidth=0.1, relheight = 0.1)

#COMBOX data representation
# Combobox creation
n = tk.StringVar()
data_representation = ttk.Combobox(tab2, width=20, textvariable=n)
# Adding combobox drop down list
data_representation['values'] = ('HEX', 'BIN', 'DEC')
data_representation.place(relx = 0.95, rely = 0, relwidth=0.05, relheight = 0.05)
data_representation.current(0)#HEX defoult value
#current_data_representation = data_representation.get()
#simulate button
btn_simulate = tk.Button(tab2, text="SIMULATE", bg="lightblue", width=20, command= None, font=("Calibri", 10))
btn_simulate.place(relx=0, rely=0, relwidth=0.1, relheight=0.05)
next_step_button = tk.Button(tab2, text="NEXT", bg="lightblue", width=20, command=None, font=("Calibri", 10))
next_step_button.place(relx=0.1, rely=0, relwidth=0.1, relheight=0.05)

stop_sim_button = tk.Button(tab2, text="STOP", bg="lightblue", width=20, command=None, font=("Calibri", 10))
stop_sim_button.place(relx=0.2, rely=0, relwidth=0.1, relheight=0.05)





# Menu setup
menu = tk.Menu(window)
filemenu = tk.Menu(menu)
menu.add_cascade(label="File", menu=filemenu)
filemenu.add_command(label="Save...", command=save_to_file)
filemenu.add_separator()
filemenu.add_command(label="Exit", command=window.quit)
window.config(menu=menu)


# Main loop
window.mainloop()
