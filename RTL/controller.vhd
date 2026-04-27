library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity controller_step_counter is 
port(
clk, rst : in std_logic;
ouput : out integer range 0 to 6
);
end;

architecture a of  controller_step_counter is 
signal ouput_sig :  integer range 0 to 6;
begin 
	process(clk, rst)
	begin 
		if rst = '1' then 
		 ouput_sig <= 0;
		elsif rising_edge(clk) then 
		if  ouput_sig = 6 then
		ouput_sig <= 0;
		else
		ouput_sig <= ouput_sig + 1;
		end if;
		end if ;
	end process;
	ouput <= ouput_sig;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity controller is
generic ( NUMBER_CONTROL_LINES : integer := 26 ); 
port(
zero_flag: in std_logic;
clk, rst : 		in std_logic;
hard_int : in std_logic;
oper : 			in std_logic_vector(7 downto 0);

up_counter :   out std_logic;
load_counter : out std_logic;
load_ir : 		out std_logic;
RAM_WE :       out std_logic;
RAM_RE :       out std_logic;
load_dr : 		out std_logic;
enable_dr: 		out std_logic;
load_ar : 		out std_logic;
enable_ar: 		out std_logic;
load_br : 		out std_logic;
ALU_en :			out std_logic;
load_adr:      out std_logic;
load_rar : out std_logic;
enable_rar : out std_logic;
load_ctr : out std_logic;
load_cdr : out std_logic;
pop_rar : out std_logic;
isr_addr_en : out std_logic;
load_isr : out std_logic;
enable_rx_reg : out std_logic;
load_tx_reg : out std_logic;
uart_tx_en : out std_logic; --write enable for UART_T
tx_ready_en : out std_logic;--tx_ready register enable
load_out_reg : out std_logic;
input_reg_en : out std_logic;
load_dir : out std_logic;



clear_interrupt_flag : out std_logic -- it is not control line. that is rst fot isr to clear flag
);
end;

architecture a of controller is 
signal MICROPEARATION : std_logic_vector(NUMBER_CONTROL_LINES-1 downto 0);
signal step_sig : integer range 0 to 6;
signal int_flag_sig , rst_sig, reset: std_logic;
component controller_step_counter 
		port(
		clk, rst : in std_logic;
		ouput : out integer range 0 to 6
		);
end component;
--MICROPEARATIONS FIELD


constant NOP : 			         std_logic_vector(NUMBER_CONTROL_LINES-1 downto 0):="00000000100000000000000000";--without operations
constant first_basic_step: 	     std_logic_vector(NUMBER_CONTROL_LINES-1 downto 0):="00100100100100000000000000";--load instruction register and data register and address register
constant second_basic_step:      std_logic_vector(NUMBER_CONTROL_LINES-1 downto 0):="10000000100000000000000000";-- up program counter 
constant from_data_reg_toA_reg:  std_logic_vector(NUMBER_CONTROL_LINES-1 downto 0):="00000011100000000000000000";--load from data_reg to A
constant write_to_ram_from_a: 	 std_logic_vector(NUMBER_CONTROL_LINES-1 downto 0):="00010000101000000000000000";--write from a to ram
constant write_from_ram_to_a: 	 std_logic_vector(NUMBER_CONTROL_LINES-1 downto 0):="00001001100000000000000000";--write from ram to a
constant write_from_ram_to_b: 	 std_logic_vector(NUMBER_CONTROL_LINES-1 downto 0):="00001000110000000000000000";--write from ram to b
constant write_from_alu_to_a: 	 std_logic_vector(NUMBER_CONTROL_LINES-1 downto 0):="00000001101000000000000000";--write from alu to a
constant load_programm_counter:  std_logic_vector(NUMBER_CONTROL_LINES-1 downto 0):="01000010100000000000000000";--load programm counter
constant load_from_dr_to_ram:    std_logic_vector(NUMBER_CONTROL_LINES-1 downto 0):="00010010100000000000000000";--load_from_dr_to_ram
constant load_rar_command:       std_logic_vector(NUMBER_CONTROL_LINES-1 downto 0):="00000000100010000000000000";--load RAR return address register
constant load_pc_from_rar :      std_logic_vector(NUMBER_CONTROL_LINES-1 downto 0):="01000000100001001000000000";--load pc from rar 
constant load_from_dr_to_ctr:    std_logic_vector(NUMBER_CONTROL_LINES-1 downto 0):="00000010100000100000000000";--load_from_dr_to_control timer register
constant load_from_dr_to_cdr:    std_logic_vector(NUMBER_CONTROL_LINES-1 downto 0):="00000010100000010000000000";--load_from_dr_to_ compare data register
constant load_pc_from_isr:       std_logic_vector(NUMBER_CONTROL_LINES-1 downto 0):="01000000100000000100000000";--load programm counter from isr 
constant from_data_reg_to_isr:   std_logic_vector(NUMBER_CONTROL_LINES-1 downto 0):="00000010100000000010000000";--load from data_reg to isr
constant first_basic_step_for_j: std_logic_vector(NUMBER_CONTROL_LINES-1 downto 0):="00101101100100000000000000";--load instruction register and data register and address register and ld a from ram
constant second_basic_step_for_j:std_logic_vector(NUMBER_CONTROL_LINES-1 downto 0):="10001001100000000000000000";--up pc and ld a from ram
constant write_from_rx_reg_to_a :std_logic_vector(NUMBER_CONTROL_LINES-1 downto 0):="00000001100000000001000000";-- load rx_reg to acc
constant write_from_a_to_tx_reg :std_logic_vector(NUMBER_CONTROL_LINES-1 downto 0):="00000000101000000000100000";-- load acc to tx_reg
constant enable_uart_tx         :std_logic_vector(NUMBER_CONTROL_LINES-1 downto 0):="00000000100000000000010000";-- starts the trasmitting
constant write_tx_ready_to_ram	:std_logic_vector(NUMBER_CONTROL_LINES-1 downto 0):="00010000100000000000001000";
constant write_a_to_out_reg	    :std_logic_vector(NUMBER_CONTROL_LINES-1 downto 0):="00000000101000000000000100";
constant write_from_input_to_a :  std_logic_vector(NUMBER_CONTROL_LINES-1 downto 0):="00000001100000000000000010";--write
constant load_dir_from_dr :  std_logic_vector(NUMBER_CONTROL_LINES-1 downto 0)     :="00000010100000000000000001";
--OPERATION CODE
constant IDLE : 					   std_logic_vector(7 downto 0):="00000000";--without operations
constant LDA : 						   std_logic_vector(7 downto 0):="00000001";--load a
constant WFR : 						   std_logic_vector(7 downto 0):="00000011";--write file register(write ram)
constant RFR : 						   std_logic_vector(7 downto 0):="00000100";--read file register(from ram to a)
constant JMP :						   std_logic_vector(7 downto 0):="00001011";--jmp if number in ram by address is not 0
constant LDR :						   std_logic_vector(7 downto 0):="00001101";--load from data reg to ram by address
constant JML :						   std_logic_vector(7 downto 0):="00001110";--jmp if number in ram by address is not 0 and remind return address
constant RAR :						   std_logic_vector(7 downto 0):="00001111";--jmp in address in RAR
constant LCTR :						   std_logic_vector(7 downto 0):="00010101";--load control timer register
constant LCDR :						   std_logic_vector(7 downto 0):="00010110";--load compare data register
constant LISR :						   std_logic_vector(7 downto 0):="00010111";--load inter enable
constant RXTA :						   std_logic_vector(7 downto 0):="00011000";--rx to a
constant ATTX :						   std_logic_vector(7 downto 0):="00011001";--a to tx
constant TXTR :						   std_logic_vector(7 downto 0):="00011010";--tx_ready to ram
constant OUTP :						   std_logic_vector(7 downto 0):="00011011";--tx_ready to ram
constant LDIR :                     std_logic_vector(7 downto 0):="00011100";
constant INTA :                     std_logic_vector(7 downto 0):="00011101";
begin 
reset <= rst or rst_sig;
controller_step_counter1 : controller_step_counter port map(clk => clk, rst => reset, ouput=>step_sig);
process(clk, oper, rst)
begin
if rst = '1' then 
int_flag_sig <= '0';
clear_interrupt_flag <= '1';
rst_sig <= '0';
elsif rising_edge(clk) then
if step_sig = 0 then 
	if(hard_int = '1') then 
        int_flag_sig <= '1';
	MICROPEARATION <= NOP;
        else
        clear_interrupt_flag <= '0';
	MICROPEARATION <= first_basic_step;
	end if;
elsif step_sig = 1 then 
     if(int_flag_sig = '0') then 
       case oper is
	when JMP | JML => MICROPEARATION <=second_basic_step_for_j;
        when others => MICROPEARATION <= second_basic_step;
       end case;
     else MICROPEARATION <= NOP; end if;
elsif step_sig = 2 then 
	if int_flag_sig = '0' then 
		case oper is
			when IDLE => MICROPEARATION <= NOP;
			when LDA =>  MICROPEARATION <=from_data_reg_toA_reg;
			when WFR =>  MICROPEARATION <=write_to_ram_from_a;
			when RFR =>  MICROPEARATION <=write_from_ram_to_a;
			when JMP =>  MICROPEARATION <=write_from_ram_to_a;
			when LDR =>  MICROPEARATION <=load_from_dr_to_ram;
			when JML =>  MICROPEARATION <= write_from_ram_to_a;
			when RAR =>  MICROPEARATION <= load_pc_from_rar;
			
			when LCTR =>  MICROPEARATION <= load_from_dr_to_ctr;
			when LCDR =>  MICROPEARATION <= load_from_dr_to_cdr;
			when LISR =>  MICROPEARATION <= from_data_reg_to_isr;
			when RXTA =>  MICROPEARATION <= write_from_rx_reg_to_a;
			when ATTX =>  MICROPEARATION <= write_from_a_to_tx_reg;
			when TXTR =>  MICROPEARATION <= write_tx_ready_to_ram;
			when OUTP =>  MICROPEARATION <= write_a_to_out_reg;
			when LDIR =>  MICROPEARATION <= load_dir_from_dr;
			when INTA =>  MICROPEARATION <= write_from_input_to_a;
			when others => MICROPEARATION <= write_from_ram_to_b;
			end case;
	else MICROPEARATION <= load_rar_command; end if;
elsif step_sig = 3   then
	if int_flag_sig = '0' then 
		case oper is
			when IDLE => MICROPEARATION <=NOP;
			when LDA =>  MICROPEARATION <=from_data_reg_toA_reg;
			when WFR =>  MICROPEARATION <=write_to_ram_from_a;
			when RFR =>  MICROPEARATION <=write_from_ram_to_a;
			when JMP =>  MICROPEARATION <=NOP;
			when LDR =>  MICROPEARATION <=load_from_dr_to_ram;
			when JML =>  MICROPEARATION <=NOP;
			when RAR =>  MICROPEARATION <= NOP;
			when LCTR =>  MICROPEARATION <= load_from_dr_to_ctr;
			when LCDR =>  MICROPEARATION <= load_from_dr_to_cdr;
			when LISR =>  MICROPEARATION <= from_data_reg_to_isr;
			when RXTA =>  MICROPEARATION <= write_from_rx_reg_to_a;
			when ATTX =>  MICROPEARATION <= write_from_a_to_tx_reg;
			when TXTR =>  MICROPEARATION <= write_tx_ready_to_ram;
			when OUTP =>  MICROPEARATION <= write_a_to_out_reg;
			when LDIR =>  MICROPEARATION <= load_dir_from_dr;
			when INTA =>  MICROPEARATION <= write_from_input_to_a;
			when others => MICROPEARATION <= write_from_ram_to_b;
			end case;
	else MICROPEARATION <= load_pc_from_isr; end if;
elsif step_sig = 4   then  
	if int_flag_sig = '0' then 
		case oper is
			when IDLE => MICROPEARATION <=NOP;
			when LDA =>  MICROPEARATION <=NOP;
			when WFR =>  MICROPEARATION <=NOP;
			when RFR =>  MICROPEARATION <=NOP;
			when JMP =>  if zero_flag = '0' then MICROPEARATION <=load_programm_counter; else MICROPEARATION <= NOP; end if;
			when LDR =>  MICROPEARATION <=NOP;
			when JML =>  if zero_flag = '0' then MICROPEARATION <=load_rar_command; else MICROPEARATION <= NOP; end if;
			when RAR =>  MICROPEARATION <= NOP;
			when LCTR =>  MICROPEARATION <= NOP;
			when LCDR =>  MICROPEARATION <= NOP;
			when LISR => MICROPEARATION <= NOP;
			when RXTA =>  MICROPEARATION <= NOP;
			when ATTX =>  MICROPEARATION <= enable_uart_tx;
			when TXTR =>  MICROPEARATION <= NOP;
			when OUTP =>  MICROPEARATION <= NOP;
			when LDIR =>  MICROPEARATION <= NOP;
			when INTA =>  MICROPEARATION <= NOP;
			when others => MICROPEARATION <= write_from_alu_to_a;
			end case;
	else MICROPEARATION <= load_pc_from_isr; end if;
elsif step_sig = 5 then
	if int_flag_sig = '0' then 
		case oper is
			when IDLE => MICROPEARATION <=NOP;
			when LDA =>  MICROPEARATION <=NOP;
			when WFR =>  MICROPEARATION <=NOP;
			when RFR =>  MICROPEARATION <=NOP;
			when JMP =>  if MICROPEARATION = load_programm_counter then MICROPEARATION <=load_programm_counter; else MICROPEARATION <= NOP; end if;
			when LDR =>  MICROPEARATION <=NOP;
			when JML =>  if zero_flag = '0' then MICROPEARATION <=load_programm_counter; else MICROPEARATION <= NOP; end if;
			when RAR =>  MICROPEARATION <= NOP;
			when LCTR =>  MICROPEARATION <= NOP;
			when LCDR =>  MICROPEARATION <= NOP;
			when LISR => MICROPEARATION <= NOP;
			when ATTX =>  MICROPEARATION <= enable_uart_tx;			
			when others => MICROPEARATION <= NOP;
			end case;
	else MICROPEARATION <= load_pc_from_isr; end if;

elsif step_sig = 6 then 
if int_flag_sig = '0' then  
case oper is 
when JML => if MICROPEARATION = load_programm_counter then MICROPEARATION <=load_programm_counter;end if;
when ATTX =>  MICROPEARATION <= enable_uart_tx;
when others => MICROPEARATION <= NOP;
end case;
else MICROPEARATION <= NOP; int_flag_sig <= '0'; clear_interrupt_flag <= '1'; end if;
end if;
end if;
end process;


up_counter   <= MICROPEARATION(NUMBER_CONTROL_LINES-1);
load_counter <= MICROPEARATION(NUMBER_CONTROL_LINES-2);
load_ir      <= MICROPEARATION(NUMBER_CONTROL_LINES-3);
RAM_WE       <= MICROPEARATION(NUMBER_CONTROL_LINES-4);
RAM_RE       <= MICROPEARATION(NUMBER_CONTROL_LINES-5);
load_dr      <= MICROPEARATION(NUMBER_CONTROL_LINES-6);
enable_dr    <= MICROPEARATION(NUMBER_CONTROL_LINES-7);
load_ar      <= MICROPEARATION(NUMBER_CONTROL_LINES-8);
enable_ar    <= MICROPEARATION(NUMBER_CONTROL_LINES-9);
load_br      <= MICROPEARATION(NUMBER_CONTROL_LINES-10);
ALU_en       <= MICROPEARATION(NUMBER_CONTROL_LINES-11);
load_adr     <= MICROPEARATION(NUMBER_CONTROL_LINES-12);
load_rar     <= MICROPEARATION(NUMBER_CONTROL_LINES-13);
enable_rar   <= MICROPEARATION(NUMBER_CONTROL_LINES-14);
load_ctr     <= MICROPEARATION(NUMBER_CONTROL_LINES-15);
load_cdr     <= MICROPEARATION(NUMBER_CONTROL_LINES-16);
pop_rar      <= MICROPEARATION(NUMBER_CONTROL_LINES-17);
isr_addr_en  <= MICROPEARATION(NUMBER_CONTROL_LINES-18);
load_isr     <= MICROPEARATION(NUMBER_CONTROL_LINES-19);
enable_rx_reg<= MICROPEARATION(NUMBER_CONTROL_LINES-20);
load_tx_reg  <= MICROPEARATION(NUMBER_CONTROL_LINES-21);
uart_tx_en   <= MICROPEARATION(NUMBER_CONTROL_LINES-22);
tx_ready_en  <= MICROPEARATION(NUMBER_CONTROL_LINES-23);
load_out_reg <= MICROPEARATION(NUMBER_CONTROL_LINES-24);
input_reg_en <= MICROPEARATION(NUMBER_CONTROL_LINES-25);
load_dir     <= MICROPEARATION(NUMBER_CONTROL_LINES-26);

end; 
