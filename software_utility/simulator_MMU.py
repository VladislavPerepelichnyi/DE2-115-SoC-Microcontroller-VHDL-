'''
def update_ram_address(address, value):
    """Функция обновления значения в ячейке памяти."""
    ram_table.item(address, values=(address, value))
def next_step_function():
    if current_step < 1000:
        current_step +=1
    else:
        current_step = 0
    simulation_function()

def simulation_function():

    opcode_to_commands = {
    '00000000': 'IDLE',
    '00000001': 'LDA',
    '00000010': 'ADDA',
    '00000011': 'WFR',
    '00000100': 'RFR',
    '00000101': 'OR',
    '00000110': 'AND',
    '00000111': 'NOT',
    '00001000': 'XOR',
    '00001001': 'SLL',
    '00001010': 'SLR',
    '00001011': 'JMP',
    '00001100': 'SUB',
    '00001101': 'LDR',
    '00001110': 'JML',
    '00001111': 'RAR',
    '00010000': 'INC',
    '00010001': 'DEC',
    '00010010': 'CMP',
    '00010011': 'LROT',
    '00010100': 'RROT'
}

    global current_step



    # Получаем текущую репрезентацию данных (HEX, BIN, DEC)
    current_representation = data_representation.get()

    # Вспомогательная функция для конвертации чисел в выбранную репрезентацию
    def convert_value(value):
        if current_representation == "HEX":
            return f"0x{value:X}"
        elif current_representation == "BIN":
            return f"{value:08b}"
        elif current_representation == "DEC":
            return str(value)
    #code processing
    input_code = numbered_text.text_area.get("1.0", tk.END).strip().splitlines()
    '''
'''
    binary_instructions = []


    # Preprocess labels
    labels = preprocess_labels(input_code)

    # Second pass: Assemble instructions
    effective_line_number = 0
    for line in input_code:
        line = line.strip()  # Remove leading/trailing whitespace
        if not line:  # Ignore completely blank lines
            continue
        try:
            binary_instruction = assemble_instruction(line, labels, effective_line_number)
            if binary_instruction:
                binary_instructions.append(binary_instruction)
                effective_line_number += 1
        except ValueError as e:
            print("ERROR")
'''
'''
    # Инициализация начальных значений
    registers = {
        "A": 0,  # Регистр A
        "B": 0,  # Регистр B
        "IR": 0,  # Регистр IR (Instruction Register)
        "PC": 0,  # Регистр PC (Program Counter)
        "RAR": 0,  # Регистр RAR (Return Address Register)
        "AR": 0,  # Регистр
        "DR": 0,  # Регистр
    }

    # Память RAM (инициализация нулями)
    ram = [0] * 256

    def get_register_value(register_entry):

        value = register_entry.get().strip()  # Считываем значение из текстового поля
        try:
            if value.startswith("0x"):  # Если значение в шестнадцатеричном формате
                return int(value, 16)
            elif value.startswith("0b"):  # Если значение в двоичном формате
                return int(value, 2)
            else:  # Предполагается десятичный формат
                return int(value)
        except ValueError:
            # Если значение некорректное, можно выбросить исключение или вернуть 0
            raise ValueError(f"Некорректное значение регистра: {value}")

    def set_register_value(register, value):
        """Установить значение в указанный регистр и обновить интерфейс"""
        if value > 255:
            value = 0
        elif value < 0:
            value = 255
        registers[register] = value
        if register == "A":
            a_reg.delete(0, tk.END)
            a_reg.insert(0, convert_value(value))
        elif register == "B":
            b_reg.delete(0, tk.END)
            b_reg.insert(0, convert_value(value))
        elif register == "IR":
            ir_reg.delete(0, tk.END)
            ir_reg.insert(0, convert_value(value))
        elif register == "PC":
            PC_output.delete(0, tk.END)
            PC_output.insert(0, convert_value(value))
        elif register == "RAR":
            RARreg.delete(0, tk.END)
            RARreg.insert(0, convert_value(value))
        elif register == "AR":
            adr_reg.delete(0, tk.END)
            adr_reg.insert(0, convert_value(value))
        elif register == "DR":
            dr_reg.delete(0, tk.END)
            dr_reg.insert(0, convert_value(value))




    def set_ram_value(address, value):
        """Установить значение в память RAM и обновить таблицу RAM"""
        ram[address] = value
        row = address // 16
        col = address % 16
        values = list(ram_table.item(row, "values"))
        values[col] = convert_value(value)
        ram_table.item(row, values=values)

    def left_rotate(value, shift = 1, bit_width=8):

        mask = (1 << bit_width) - 1  # Маска для ограничения числа до bit_width бит
        shift %= bit_width  # Обеспечиваем, что сдвиг не превышает ширину
        return ((value << shift) | (value >> (bit_width - shift))) & mask

    def right_rotate(value, shift = 1, bit_width=8):
        mask = (1 << bit_width) - 1  # Маска для ограничения числа до bit_width бит
        shift %= bit_width  # Обеспечиваем, что сдвиг не превышает ширину
        return ((value >> shift) | (value << (bit_width - shift))) & mask

    ROM_output.delete(0, tk.END)
    ROM_output.insert(0, binary_instructions[registers["PC"]])
    opcode = opcode_to_commands[str(binary_instructions[registers["PC"]][0:7])]
    address = int(binary_instructions[registers["PC"]][7:15], 2)
    data = int(binary_instructions[registers["PC"]][16:24], 2)
    print(opcode, str(binary_instructions[registers["PC"]][0:7]), address, data)

    # Обновляем регистр IR
    set_register_value("IR", int(binary_instructions[registers["PC"]][0:7], 2))
    set_register_value("DR", data)
    set_register_value("AR", address)

    if opcode == "LDA":
       set_register_value("A", data)
    elif opcode == "LDR":
        set_ram_value(address, data)
    elif opcode == "WFR":
        set_ram_value(address, registers["A"])
    elif opcode == "RFR":
        set_register_value("A", ram[address])
    elif opcode == "RFR":
        set_register_value("A", ram[address])
    elif opcode == "ADDA":
        set_register_value("B", ram[address])
        set_register_value("A", registers["A"] + ram[address])
    elif opcode == "SUB":
        set_register_value("B", ram[address])
        set_register_value("A", registers["A"] - ram[address])
    elif opcode == "AND" :
        set_register_value("A", registers["A"] & ram[address])
    elif opcode == "OR" :
        set_register_value("A", registers["A"] | ram[address])
    elif opcode == "XOR" :
        set_register_value("A", registers["A"] ^ ram[address])
    elif opcode == "NOT":
        set_register_value("A", ~registers["A"])
    elif opcode == "SLL":
        set_register_value("A", registers["A"] << 1)
    elif opcode == "SRL":
        set_register_value("A", registers["A"] >> 1)
    elif opcode == "INC":
        set_register_value("A", registers["A"] + 1)
    elif opcode == "DEC":
        set_register_value("A", registers["A"] - 1)
    elif opcode == "LROT":
        set_register_value("A", left_rotate(registers["A"]))
    elif opcode == "RROT":
        set_register_value("A", right_rotate(registers["A"]))
    elif opcode == "CMP":
        if registers["A"] == ram[address]:
            set_register_value("A", 1)
        else:
            set_register_value("A", 0)
    elif opcode == "JMP":
        if ram[address] != 0:
            set_register_value("PC", data)
    elif opcode == "JML":
        if ram[address] != 0:
            set_register_value("RAR", registers["PC"])
            set_register_value("PC", data)
    elif opcode == "RAR":
        if ram[address] != 0:
            set_register_value("PC", registers["RAR"])
    a = input("next")

    set_register_value("PC", registers["PC"] + 1)




    print("Simulation stopped.")
    # Удаляем кнопки после завершения симуляции

'''
