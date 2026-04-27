library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity CPUtl is port(
CLOCK_50: in std_logic;
rst : in std_logic;
switch : in std_logic_vector(7 downto 0);
rx : in std_logic;
tx : out std_logic;
address_to_RAM : out std_logic_vector(7 downto 0);
data_out_from_RAM : in std_logic_vector(23 downto 0);
ledr : out std_logic_vector(15 downto 0)
);
end;

architecture arc of CPUtl is 

  component PC 
	port(
	clk, rst, en, inc : in std_logic;
		data_in : in std_logic_vector(7 downto 0);
		output: out std_logic_vector(7 downto 0)
	);
	end component;
	
	component RAM
    port (
        clk          : in  std_logic;
        address      : in  std_logic_vector(7 downto 0); 
        data_in      : in  std_logic_vector(7 downto 0); 
        read_enable  : in  std_logic;
        write_enable : in  std_logic;
        data_out     : out std_logic_vector(7 downto 0) 
    );
   end component;

	component DR  
		port(
			input : in std_logic_vector(7 downto 0);
			load, en: in std_logic;
			clk, rst : in std_logic;
			output: out std_logic_vector(7 downto 0)
		);
	end component; 
	
--   component ROM 
--    port (
--        address  : in std_logic_vector(7 downto 0); 
--        data_out : out std_logic_vector(23 downto 0) 
--    );
--end component;

	component IR  
	port(
		input : in std_logic_vector(7 downto 0);
		load: in std_logic;
		clk, rst : in std_logic;
		output: out std_logic_vector(7 downto 0)
);
end component; 

component controller 
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
load_adr:	out std_logic;
load_rar : out std_logic;
enable_rar : out std_logic;
load_ctr :  out std_logic;  
load_cdr :  out std_logic; 
pop_rar : out std_logic;
isr_addr_en : out std_logic;
load_isr : out std_logic;
enable_rx_reg : out std_logic;
load_tx_reg : out std_logic;
uart_tx_en : out std_logic;
tx_ready_en: out std_logic;
load_out_reg: out std_logic;
input_reg_en : out std_logic;
load_dir : out std_logic;

clear_interrupt_flag : out std_logic
);
end component;

component ALU  port(
	a, b : in std_logic_vector(7 downto 0);
	clk : in std_logic;
	oper : in std_logic_vector(7 downto 0);
	ouput_enable : in std_logic;
	result : out std_logic_vector(7 downto 0);
	carry : out std_logic;
	zero : out std_logic
);
end component;

component Stack
    port (
        data_in   : in  std_logic_vector(7 downto 0); -- Input data for push
        push      : in  std_logic;                   -- Push signal
        pop       : in  std_logic;                   -- Pop signal
        clk       : in  std_logic;                   -- Clock
        rst       : in  std_logic;                   -- Reset signal
        en        : in  std_logic;                   -- Enable signal for output
        data_out  : out std_logic_vector(7 downto 0) -- Tri-state output
    );
end component;

component ISR  
  port(
	addres_to_databus_en : in std_logic;
	data_in : in std_logic_vector(7 downto 0);
	clk, rst, load_ISR, clear_int_flag: in std_logic;
	timer_int, uart_int : in std_logic;
	hard_int : out std_logic;
	address_for_pc : out std_logic_vector(7 downto 0)
  );
 end component;


component timer 
   port(
	rst, clk, load_ctr, load_cdr : in std_logic;
	data_in : in std_logic_vector(7 downto 0);
	timer_interrupt : out std_logic
       );
end component;

component UART_R is
    port (
        clk        : in  std_logic;  -- System clock
        rst        : in  std_logic;  -- Active-high reset
        rx         : in  std_logic;  -- Asynchronous UART RX line
        
        data_out   : out std_logic_vector(7 downto 0); -- Received byte
        dout_new   : out std_logic;                     -- Pulses when a byte is ready
		  rx_ready   : out std_logic
    );
end component;

component UART_T is
    port (
        din       : in  std_logic_vector(7 downto 0); -- Input data
        rst       : in  std_logic;                   -- Reset signal
        clk       : in  std_logic;                   -- System clock
        write_din : in  std_logic;                   -- Write enable signal
        tx        : out std_logic;                   -- UART TX line
        tx_ready  : out std_logic                    -- Ready signal
    );
end component;

--CONTROL SIGNAL
signal sig_up_counter :   std_logic;
signal sig_load_counter : std_logic;
signal sig_load_ir : 	   std_logic;
signal sig_RAM_WE :        std_logic;
signal sig_RAM_RE :        std_logic;
signal sig_load_dr : 	   std_logic;
signal sig_enable_dr: 	   std_logic;
signal sig_load_ar : 	   std_logic;
signal sig_enable_ar: 	   std_logic;
signal sig_load_br : 	   std_logic;
signal sig_ALU_en :		   std_logic;
signal sig_load_adr:       std_logic;
signal sig_load_rar :	   std_logic;
signal sig_enable_rar:     std_logic;
signal sig_data_out   :    std_logic_vector(7 downto 0);   -- uart_rx
--signal sig_dout_new   :    std_logic;                    -- uart_rx
signal sig_rx_ready   :    std_logic; 					   -- uart_rx
signal sig_enable_rx_reg :    std_logic; 				   -- uart_rx

signal sig_load_tx_reg	:    std_logic; 				     --UART_TX
signal sig_UART_T_din :    std_logic_vector(7 downto 0); 	 --UART_TX
--signal sig_UART_T_write_din :    std_logic;				 --UART_TX
signal sig_UART_T_tx_ready :    std_logic_vector(7 downto 0);--UART_TX
signal sig_enable_uart_tx : std_logic;						 --UART_TX
signal sig_tx_ready_en : std_logic;

--signal load_out_reg_sig:    std_logic;
signal sig_pop_rar: std_logic;
signal isr_addr_en_sig :  std_logic;
signal load_isr_sig : std_logic;
signal hard_int_sig : std_logic;
signal timer_int_sig : std_logic;
signal uart_int_sig : std_logic;
signal load_ctr_sig : std_logic;
signal load_cdr_sig : std_logic;
signal sig_load_out_reg : std_logic;
-- DATA AND BUS SIGNAL
signal sig_data_bus :      std_logic_vector(7 downto 0);
signal sig_rom_adress:     std_logic_vector(7 downto 0);
signal sig_rom_output:     std_logic_vector(23 downto 0); 
signal ALU_A_in_sig:       std_logic_vector(7 downto 0);
signal ALU_B_in_sig:   	   std_logic_vector(7 downto 0);
signal Instruction_signal: std_logic_vector(7 downto 0);
signal address_signal:     std_logic_vector(7 downto 0);
signal signal_zero_flag:   std_logic;
--PIN ASSIGNMENT
signal clk: std_logic;
--signal rst:  std_logic;
signal clear_interrupt_flag_sig: std_logic;

signal int_flag_sig: std_logic; --debug sig
signal interrupt_status_msb_sig: std_logic; --debug sig
signal timer_int_debug_sig: std_logic; --debug sig
signal timer_int_sig_debug: std_logic_vector(1 downto 0); --debug sig
signal hard_int_sig_debug: std_logic_vector(1 downto 0); --debug sig


signal sig_enable_input, sig_load_dir_reg : std_logic;
signal gpio_signal, sig_GPIO_dir_sig, sig_out_reg : std_logic_vector(7 downto 0);
begin
sig_UART_T_tx_ready(7 downto 1) <= "0000000";
--rst <=sw(0);
clk<=CLOCK_50;
PC_CPU : PC port map(clk => clk, rst => rst, en=>sig_load_counter,inc=>sig_up_counter, data_in =>sig_data_bus, output=>sig_rom_adress);

address_to_RAM <= sig_rom_adress;

sig_rom_output <= data_out_from_RAM;

--ROM_CPU :ROM port map(address=>sig_rom_adress, data_out=>sig_rom_output);

DataR :  DR port map(input => sig_rom_output(7 downto 0),load=>sig_load_dr, en =>sig_enable_dr,clk => clk, rst=>rst, output=>sig_data_bus);

REGA  :  DR port map(input => sig_data_bus, load=>sig_load_ar, en =>sig_enable_ar,clk => clk, rst=>rst, output=>ALU_A_in_sig);

REGB  :  DR port map(input => sig_data_bus, load=>sig_load_br, en =>'1',clk => clk, rst=>rst, output=>ALU_B_in_sig);

RX_REG :  DR port map(input => sig_data_out, load=> '1', en => sig_enable_rx_reg ,clk => clk, rst=>rst, output=> sig_data_bus);

TX_REG :  DR port map(input => sig_data_bus, load=> sig_load_tx_reg, en => '1' ,clk => clk, rst=>rst, output=> sig_UART_T_din);


-- GPIO REGISTERS BEGIN

input_reg :  DR port map(input => gpio_signal, load=> '1', en => sig_enable_input ,clk => clk, rst=>rst, output=> sig_data_bus);
direct_reg : DR port map(input => sig_data_bus, load=> sig_load_dir_reg, en => '1' ,clk => clk, rst=>rst, output=> sig_GPIO_dir_sig);
output_reg : DR port map(input => sig_data_bus, load=> sig_load_out_reg, en => '1' ,clk => clk, rst=>rst, output=> sig_out_reg);
ledr(7 downto 0) <= gpio_signal;
process(sig_GPIO_dir_sig) begin
for i in (8-1) downto 0 LOOP
		if (sig_GPIO_dir_sig(i) = '0') then -- If is input
			gpio_signal(i) <= switch(i);
				
		else  --If is output
			gpio_signal(i) <= sig_out_reg(i);  --Get OUTPUT_VALUE 
		end if;
	end loop;
end process;

--GPIO REGISTERS END 

tx_ready_REG :  DR port map(input => sig_UART_T_tx_ready, load=> '1', en => sig_tx_ready_en ,clk => clk, rst=>rst, output=> sig_data_bus); 

IR_CPU : IR port map(input =>sig_rom_output(23 downto 16), load => sig_load_ir, clk=>clk, rst=>rst, output =>Instruction_signal);

AR_CPU : IR port map(input =>sig_rom_output(15 downto 8), load => sig_load_adr, clk=>clk, rst=>rst, output =>address_signal);

RAM_CPU: RAM port map(clk=>clk, 
			address=>address_signal, 
			data_in=>sig_data_bus,
		   read_enable => sig_RAM_RE,	
			write_enable=> sig_RAM_WE,
			data_out =>sig_data_bus);
 

ALU_CPU : ALU port map(a =>ALU_A_in_sig, b => ALU_B_in_sig, clk=>clk,
				oper=> Instruction_signal, ouput_enable => sig_ALU_en, 
				result=>sig_data_bus, carry=>open, zero=>signal_zero_flag);
--
RAR : Stack port map(data_in => sig_rom_adress,push=>sig_load_rar,pop =>sig_pop_rar ,clk => clk, rst=>rst,en =>sig_enable_rar,data_out=>sig_data_bus);

TIMER1:  timer  port map(
	rst => rst,  clk => clk, load_ctr => load_ctr_sig, load_cdr => load_cdr_sig,
	data_in => sig_data_bus,
	timer_interrupt => timer_int_sig
       );

ISR1 :  ISR port map(
	addres_to_databus_en => isr_addr_en_sig,
	data_in => sig_data_bus,
	clk => clk, rst => rst, 
	load_ISR => load_isr_sig, 
	clear_int_flag =>clear_interrupt_flag_sig,
	timer_int =>timer_int_sig, uart_int =>uart_int_sig,
	hard_int => hard_int_sig,
	address_for_pc => sig_data_bus
	);
	
	
UART_R1 : UART_R  port map(
         clk        => clk,  -- System clock
         rst        => rst,  -- Active-high reset
         rx         => rx,  -- Asynchronous UART RX line      
         data_out   => sig_data_out, -- Received byte
         dout_new   => uart_int_sig,                     -- Pulses when a byte is ready
		 rx_ready   => sig_rx_ready);
		 
UART_T1 : UART_T  port map(
        din       => sig_UART_T_din, -- Input data
        rst       => rst,                   -- Reset signal
        clk       => clk,                   -- System clock
        write_din => sig_enable_uart_tx,                   -- Write enable signal
        tx        => tx,                    -- UART TX line
        tx_ready  => sig_UART_T_tx_ready(0)); --tx ready is 0 while idle and 1 while working

 
U_CONTROLLER: controller
port map (
    zero_flag=>signal_zero_flag,
    clk          => clk,        
    rst          => rst,
    hard_int     => hard_int_sig,       
    oper         => Instruction_signal,        
    up_counter   => sig_up_counter,
    load_counter => sig_load_counter,
    load_ir      => sig_load_ir,
    RAM_WE       => sig_RAM_WE,
    RAM_RE       => sig_RAM_RE,
    load_dr      => sig_load_dr,
    enable_dr    => sig_enable_dr,
    load_ar      => sig_load_ar,
    enable_ar    => sig_enable_ar,
    load_br      => sig_load_br,
    ALU_en       => sig_ALU_en,
    load_adr	 => sig_load_adr,
    load_rar     => sig_load_rar,
    enable_rar   => sig_enable_rar,
    load_ctr     => load_ctr_sig,  
    load_cdr     => load_cdr_sig, 
    pop_rar      => sig_pop_rar, 
    isr_addr_en  => isr_addr_en_sig,
    load_isr     => load_isr_sig,
	enable_rx_reg=> sig_enable_rx_reg,
	load_tx_reg  => sig_load_tx_reg,
	uart_tx_en   => sig_enable_uart_tx,
	tx_ready_en  => sig_tx_ready_en,
	load_out_reg => sig_load_out_reg,
	input_reg_en => sig_enable_input,
   load_dir     => sig_load_dir_reg,
    clear_interrupt_flag => clear_interrupt_flag_sig
);



end architecture;