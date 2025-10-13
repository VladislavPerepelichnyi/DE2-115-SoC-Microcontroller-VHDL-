# Preprocess labels
def preprocess_labels(input_code):

    labels = {}
    effective_line_number = 0  # Tracks the actual instruction count
    for line in input_code:
        line = line.strip()
        if line.endswith(":"):
            label_name = line[:-1]  # Remove the trailing colon
            labels[label_name] = effective_line_number
        elif line and not (line.startswith("--")):  # Non-blank lines increment the effective line count
            effective_line_number += 1
    return labels

def find_isr(input_code):
    main_code = []
    isr_t_code = []
    isr_u_code = []

    current_section = "main"

    for line in input_code:
        if "ISR_T_BEGIN:" in line:
            current_section = "isr_t"
            continue
        elif "ISR_T_END:" in line:
            current_section = "main"
            continue
        elif "ISR_U_BEGIN:" in line:
            current_section = "isr_u"
            continue
        elif "ISR_U_END:" in line:
            current_section = "main"
            continue

        if current_section == "main":
            main_code.append(line)
        elif current_section == "isr_t":
            isr_t_code.append(line)
        elif current_section == "isr_u":
            isr_u_code.append(line)

    return main_code, isr_t_code, isr_u_code


# Compile function
def compile_function(numbered_text, binary_output, formatted_code_output):
    Error_flag = 0
    raw_code = numbered_text.text_area.get("1.0", "end").strip().splitlines()

    # devide, ISR_T и ISR_U
    main_code, isr_t_code, isr_u_code = find_isr(raw_code)

    formatted_output = ""
    binary_instructions = []

    # --- Обработка основного кода ---
    labels_main = preprocess_labels(main_code)
    effective_line_number = 0
    for line in main_code:
        line = line.strip()
        if not line:
            continue
        try:
            binary_instruction = assemble_instruction(line, labels_main, effective_line_number)
            if binary_instruction:
                binary_instructions.append(binary_instruction)
                formatted_output += f"{effective_line_number} => \"{binary_instruction}\", -- {line}\n"
                effective_line_number += 1
        except ValueError as e:
            Error_flag = 1
            formatted_output += f"Error: {e} -- {line}\n"

    # --- Обработка ISR_T на строке 200 ---
    isr_t_bin = []
    labels_isr_t = preprocess_labels(isr_t_code)
    for i, line in enumerate(isr_t_code):
        line = line.strip()
        if not line:
            continue
        try:
            bin_instr = assemble_instruction(line, labels_isr_t, i)
            if bin_instr:
                isr_t_bin.append(bin_instr)
                formatted_output += f"{230 + i} => \"{bin_instr}\", -- [ISR_T] {line}\n"
        except ValueError as e:
            Error_flag = 1
            formatted_output += f"Error in ISR_T: {e} -- {line}\n"

    # --- Обработка ISR_U на строке 230 ---
    isr_u_bin = []
    labels_isr_u = preprocess_labels(isr_u_code)
    for i, line in enumerate(isr_u_code):
        line = line.strip()
        if not line:
            continue
        try:
            bin_instr = assemble_instruction(line, labels_isr_u, i)
            if bin_instr:
                isr_u_bin.append(bin_instr)
                formatted_output += f"{200 + i} => \"{bin_instr}\", -- [ISR_U] {line}\n"
        except ValueError as e:
            Error_flag = 1
            formatted_output += f"Error in ISR_U: {e} -- {line}\n"

    # --- Заполнение бинарного списка до нужной длины ---
    max_len = 256


    while len(binary_instructions) < 200:
        binary_instructions.append("000000000000000000000000")
    binary_instructions += isr_u_bin

    while len(binary_instructions) < 230:
        binary_instructions.append("000000000000000000000000")
    binary_instructions += isr_t_bin

    while len(binary_instructions) < max_len:
        binary_instructions.append("000000000000000000000000")

    # --- Вывод ---
    binary_output.delete("1.0", "end")
    binary_output.insert("end", "\n".join(binary_instructions))

    formatted_code_output.delete("1.0", "end")
    formatted_code_output.insert("end", formatted_output)

    return Error_flag

'''
def compile_function(numbered_text, binary_output, formatted_code_output):
    Error_flag = 0
    input_code = numbered_text.text_area.get("1.0", "end").strip().splitlines()

    formatted_output = ""
    labels = preprocess_labels(input_code)
    binary_instructions = []

    effective_line_number = 0
    for line in input_code:
        line = line.strip()
        if not line:
            continue
        try:
            binary_instruction = assemble_instruction(line, labels, effective_line_number)
            if binary_instruction:
                binary_instructions.append(binary_instruction)
                formatted_output += f"{effective_line_number} => \"{binary_instruction}\", -- {line}\n"
                effective_line_number += 1
        except ValueError as e:
            Error_flag = 1
            formatted_output += f"Error: {e} -- {line}\n"

    while len(binary_instructions) < 256:
        binary_instructions.append("000000000000000000000000")
    binary_output.delete("1.0", "end")
    binary_output.insert("end", "\n".join(binary_instructions))

    formatted_code_output.delete("1.0", "end")
    formatted_code_output.insert("end", formatted_output)
    return Error_flag
'''

def assemble_instruction(command: str, labels: dict, current_line: int) -> str:

    # Strip comments
    if '--' in command:
        command = command.split('--', 1)[0].strip()

    commands = {
        "IDLE": {"opcode": "00000000", "address": "00000000", "data": "00000000"},
        "LDA": {"opcode": "00000001", "address": "00000000", "data": None},
        "ADDA": {"opcode": "00000010", "address": None, "data": "00000000"},
        "WFR": {"opcode": "00000011", "address": None, "data": "00000000"},
        "RFR": {"opcode": "00000100", "address": None, "data": "00000000"},
        "OR": {"opcode": "00000101", "address": None, "data": "00000000"},
        "AND": {"opcode": "00000110", "address": None, "data": "00000000"},
        "NOT": {"opcode": "00000111", "address": None, "data": "00000000"},
        "XOR": {"opcode": "00001000", "address": None, "data": "00000000"},
        "SLL": {"opcode": "00001001", "address": None, "data": "00000000"},
        "SLR": {"opcode": "00001010", "address": None, "data": "00000000"},
        "JMP": {"opcode": "00001011", "address": None, "data": None},
        "SUB": {"opcode": "00001100", "address": None, "data": "00000000"},
        "LDR": {"opcode": "00001101", "address": None, "data": None},
        "JML": {"opcode": "00001110", "address": None, "data": None},
        "RAR": {"opcode": "00001111", "address": "00000000", "data": "00000000"},
        "INC": {"opcode": "00010000", "address": "00000000", "data": "00000000"},
        "DEC": {"opcode": "00010001", "address": "00000000", "data": "00000000"},
        "CMP": {"opcode": "00010010", "address": None, "data": "00000000"},
        "LROT": {"opcode": "00010011", "address": "00000000", "data": "00000000"},
        "RROT": {"opcode": "00010100", "address": "00000000", "data": "00000000"},
        "LCTR": {"opcode": "00010101", "address": "00000000", "data": None},
        "LCDR": {"opcode": "00010110", "address": "00000000", "data": None},
        "LISR": {"opcode": "00010111", "address": "00000000", "data": None},
        "RXTA": {"opcode": "00011000", "address": "00000000", "data": "00000000"},
        "ATTX": {"opcode": "00011001", "address": "00000000", "data": "00000000"},
        "TXTR": {"opcode": "00011010", "address": None, "data": "00000000"},
        "OUTP": {"opcode": "00011011", "address": "00000000", "data": "00000000"},
        "LDIR": {"opcode": "00011100", "address": "00000000", "data": None},
        "INTA": {"opcode": "00011101", "address": "00000000", "data": "00000000"}, 
        
    }

    # Ignore blank lines and labels
    if not command.strip() or command.endswith(":"):
        return None

    # Parse instruction
    parts = command.split()
    mnemonic = parts[0]
    if mnemonic not in commands:
        Error_flag = 1
        raise ValueError(f"Unsupported command: {mnemonic}")

    command_info = commands[mnemonic]
    opcode = command_info["opcode"]
    address = "00000000"
    data = "00000000"

    if len(parts) > 1:
            values = parts[1:]
            if mnemonic in ["JMP", "JML"]:
                # Resolve the label or address for the jump
                if len(values) != 2:
                    Error_flag = 1
                    raise ValueError(f"{mnemonic} requires two arguments: REGISTER ADDRESS and JUMP TARGET.")
                register_address = values[0]
                jump_target = values[1]

                # Convert register address
                if register_address.startswith("0x"):
                    address = f"{int(register_address, 16):08b}"
                else:
                    address = f"{int(register_address):08b}"

                # Resolve jump target
                if jump_target in labels:
                    data = f"{labels[jump_target]:08b}"
                elif jump_target.startswith("0x"):
                    data = f"{int(jump_target, 16):08b}"
                else:
                    Error_flag = 1
                    raise ValueError(f"Undefined label or invalid target: {jump_target}")
            else:
                # Handle other commands
                parsed_values = []
                for value in values:
                    if value.startswith("0x"):
                        parsed_values.append(int(value, 16))
                    elif value.startswith("0b"):
                        parsed_values.append(int(value, 2))
                    else:
                        parsed_values.append(int(value))

                if not all(0 <= v <= 255 for v in parsed_values):
                    Error_flag = 1
                    raise ValueError("Value out of range for 8-bit data.")

                if mnemonic == "LDA" or mnemonic == "LCTR" or mnemonic == "LCDR" or mnemonic == "LISR" or mnemonic == "LDIR":
                    data = f"{parsed_values[0]:08b}"
                elif mnemonic == "LDR":
                    data = f"{parsed_values[1]:08b}"
                    address = f"{parsed_values[0]:08b}"
                else:
                    address = f"{parsed_values[0]:08b}"

    return f"{opcode}{address}{data}"
