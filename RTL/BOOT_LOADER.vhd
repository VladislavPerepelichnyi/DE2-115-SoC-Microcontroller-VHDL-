library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
use ieee.std_logic_unsigned.all;

entity BOOT_LOADER is port(
	global_rst : in std_logic;-- active low
	rst_MMU : out std_logic; -- rst mmu while loading ram
	clk : in std_logic;
	select_address_sourse : out std_logic; -- 0 for boot loader, 1 for program counter in start mode
	RAM_WE : out std_logic; --ram write enable 
	
	
	dataout   : out std_logic_vector(23 downto 0); --for data to RAM 
	RAM_address : out std_logic_vector(7 downto 0);
	--FLASH PART
	-----------FLASH CONTROL LINES { 
   fl_addr  : out std_logic_vector(22 downto 0);-- flash address
	fl_dq    : in std_logic_vector(7 downto 0);--data 8 bit 
	fl_we_n  : out std_logic;--write enable = 0, write disable = 1
	fl_rst_n : out std_logic;-- rst_inverted (reset when the pin = 0)
	fl_ry    : in std_logic; --ready = 1 / busy = 0
	fl_ce_n  : out std_logic; --flash chip enable = 0/ disable = 1
	fl_oe_n  : out std_logic; -- flash output enable output = 0 , disable = 1
	-----------FLASH CONTROL LINES } 
	
	ready_flag : out std_logic
);
end;

architecture BOOT_LOADER_A of BOOT_LOADER is 
  type state_type is (
    ST_IDLE,
	 WRITE_DATA, 
	 WRITE_ADDRESS, 
	 WRITE_OPCODE, 
	 WRIRE_RAM, 
	 START_RUN
	 );
signal present_state : state_type := ST_IDLE;

component DAO_REG is port(
	input : in std_logic_vector(7 downto 0);
	load, en: in std_logic;
	clk, rst : in std_logic;
	output: out std_logic_vector(7 downto 0)
);
end component;

signal address_signal_for_RAM :   std_logic_vector(7 downto 0):= x"00";
signal address_signal_for_FLASH : std_logic_vector(9 downto 0):= "0000000000";
signal delay_cnt : integer  := 0;
signal load_data_sig, load_address_sig,load_opcode_sig : std_logic; 

begin
DATA_REG : DAO_REG port map(
         input => fl_dq,
		   load => load_data_sig,
		   en => '1', 
			clk => clk, 
		   rst => global_rst, 
		   output => dataout(7 downto 0) 	
		);
ADDRESS_REG : DAO_REG port map(
         input => fl_dq,
		   load => load_address_sig,
		   en => '1', 
			clk => clk, 
		   rst => global_rst, 
		   output => dataout(15 downto 8) 	
		);
OPCODE_REG : DAO_REG port map(
         input => fl_dq,
		   load => load_opcode_sig,
		   en => '1', 
			clk => clk, 
		   rst => global_rst, 
		   output => dataout(23 downto 16) 	
		);
process(global_rst, clk)
begin 
if(global_rst = '0') then 
	present_state <= ST_IDLE;
	address_signal_for_RAM <= x"00";
	address_signal_for_FLASH <= "0000000000";
	
elsif rising_edge(clk) then 

	case present_state is 
		when ST_IDLE => 
			   address_signal_for_RAM <= x"00";
	         address_signal_for_FLASH <= "0000000000";
				present_state <= WRITE_DATA;
				
		when WRITE_DATA => 
		      if delay_cnt < 1000 then 
				   delay_cnt <= delay_cnt + 1;
				else 
				   address_signal_for_FLASH <= address_signal_for_FLASH + '1';
					delay_cnt <= 0;
					present_state <= WRITE_ADDRESS;
				end if;
				
		when WRITE_ADDRESS => 
				
				if delay_cnt < 1000 then 
					delay_cnt <= delay_cnt + 1;
				else 
				   address_signal_for_FLASH <= address_signal_for_FLASH + '1';
					delay_cnt <= 0;
					present_state <= WRITE_OPCODE;
				end if;
				
		when WRITE_OPCODE => 
		if delay_cnt < 1000 then 
			delay_cnt <= delay_cnt + 1;
		else 
			address_signal_for_FLASH <= address_signal_for_FLASH + '1';
			delay_cnt <= 0;
			present_state <= WRIRE_RAM;
		end if;
		
		when WRIRE_RAM => 
				if delay_cnt < 1000 then 
					delay_cnt <= delay_cnt + 1;
				else 
					delay_cnt <= 0;
					if(address_signal_for_RAM < 255) then 
						present_state <= WRITE_DATA;
						address_signal_for_RAM <= address_signal_for_RAM + '1';
					else 
					   present_state <= START_RUN;
					end if;
				end if;
		when START_RUN => present_state <= START_RUN;
		
		when others =>  present_state <= ST_IDLE;
		end case;
		
end if ;
end process;

process(present_state)
begin
	case  present_state is 
   when 	ST_IDLE =>
	
			fl_ce_n  <= '0';
         fl_oe_n  <= '0';
         fl_rst_n <= '1';
         fl_we_n  <= '1';
			RAM_WE   <= '0';
			select_address_sourse <='0';
			load_data_sig <= '0';
			load_address_sig<= '0';
			load_opcode_sig <= '0';
			rst_MMU <= '1';
			ready_flag <= '0';
	when WRITE_DATA => 

			fl_ce_n  <= '0';
         fl_oe_n  <= '0';
         fl_rst_n <= '1';
         fl_we_n  <= '1';
			RAM_WE   <= '0';
			select_address_sourse <='0';
			load_data_sig   <= '1';
			load_address_sig<= '0';
			load_opcode_sig <= '0';
			rst_MMU <= '1';
			ready_flag <= '0';
			
	when WRITE_ADDRESS => 

			fl_ce_n  <= '0';
         fl_oe_n  <= '0';
         fl_rst_n <= '1';
         fl_we_n  <= '1';
			RAM_WE   <= '0';
			select_address_sourse <='0';
			load_data_sig <= '0';
			load_address_sig<= '1';
			load_opcode_sig <= '0';
			rst_MMU <= '1';
			ready_flag <= '0';
			
	when WRITE_OPCODE => 

			fl_ce_n  <= '0';
         fl_oe_n  <= '0';
         fl_rst_n <= '1';
         fl_we_n  <= '1';
			RAM_WE   <= '0';
			select_address_sourse <='0';
			load_data_sig <= '0';
			load_address_sig<= '0';
			load_opcode_sig <= '1';
			rst_MMU <= '1';
			ready_flag <= '0';
	when WRIRE_RAM => 

			fl_ce_n  <= '0';
         fl_oe_n  <= '0';
         fl_rst_n <= '1';
         fl_we_n  <= '1';
			RAM_WE   <= '1';
			select_address_sourse <='0';
			load_data_sig <= '0';
			load_address_sig<= '0';
			load_opcode_sig <= '0';
			rst_MMU <= '1';
			ready_flag <= '0';
	when START_RUN => 
			fl_ce_n  <= '0';
         fl_oe_n  <= '1';
         fl_rst_n <= '1';
         fl_we_n  <= '1';
			RAM_WE   <= '0';
			select_address_sourse <='1';
			load_data_sig <= '0';
			load_address_sig<= '0';
			load_opcode_sig <= '0';
			rst_MMU <= '0';
			ready_flag <= '1';
	when others =>
				
			fl_ce_n  <= '0';
         fl_oe_n  <= '1';
         fl_rst_n <= '1';
         fl_we_n  <= '1';
			RAM_WE   <= '0';
			select_address_sourse <='0';
			load_data_sig <= '0';
			load_address_sig<= '0';
			load_opcode_sig <= '0';
	end case;
end process;


RAM_address <= address_signal_for_RAM;
fl_addr <= "0000000000000"&address_signal_for_FLASH ;
end;



