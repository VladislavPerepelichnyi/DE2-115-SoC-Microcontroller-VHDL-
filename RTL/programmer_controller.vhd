library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity programmer_controller is port(
	clk : in std_logic;
	rst : in std_logic;
	-- uart_r
	data_in    : in std_logic_vector(7 downto 0); 
   data_new   : in std_logic;                     
	
	-- uart_t
	data_out_uart_t       : out  std_logic_vector(7 downto 0); -- Input data
   write_dout            : out  std_logic;                   -- Write enable signal
	-- Control signals
	rst_command    : out std_logic;
   start          : out  std_logic;           -- begin a program operation
	erase_sector   : out  std_logic; 
	data_out_flash : out  std_logic_vector(7 downto 0);
	addr_out_flash : out  std_logic_vector(19 downto 0) -- target address
   
	

);
end;

architecture a of programmer_controller is 
constant S_symbol : std_logic_vector(7 downto 0) := x"53";
constant F_symbol : std_logic_vector(7 downto 0) := x"46";




type state is (
    IDLE,
	 RESET,
	 EREASER,
	 SSEND,
	 WRITE_STATE, 
	 FSEND
	 );
	 
signal state_of_programming : state;
signal address_s : std_logic_vector(19 downto 0) := x"FFFFF";
signal delay_rx : integer := 0;
signal delay_flash_operations : integer := 0;

signal data_out_flash_sig : std_logic_vector(7 downto 0); 
signal addr_out_flash_sig : std_logic_vector(19 downto 0);
	 
begin
process(clk, rst)
begin	 
	 
if rst = '0' then 
	delay_flash_operations <= 0;
	state_of_programming <= IDLE;
	address_s <= x"FFFFF";
	delay_rx <= 0;
	rst_command <= '1';
	erase_sector <= '1';
	start <= '1';
	write_dout <= '0';

	
elsif rising_edge(clk) then 
	
		case state_of_programming is 
			when IDLE =>if data_new = '1' then
									delay_rx <= 1; 
									write_dout <= '0';
									
								elsif delay_rx > 0 and delay_rx < 100 then
									delay_rx <= delay_rx + 1;
								elsif delay_rx = 100 and data_in = S_symbol then
										state_of_programming <= RESET;
										delay_rx <= 0;
								else
								    write_dout <= '0';
										delay_rx <= 0;
										address_s <= x"FFFFF";
								end if;
								
								
			when RESET => delay_flash_operations <= delay_flash_operations + 1;
								
								if (delay_flash_operations<=5)then 
			                 rst_command <= '0';
							  
								elsif (delay_flash_operations > 5) then
									rst_command <= '1';
								end if;
								if (delay_flash_operations > 200) then
									delay_flash_operations <= 0;
									state_of_programming <= EREASER;
								end if;
								
								
			when EREASER => 
							  delay_flash_operations <= delay_flash_operations + 1;
							  if (delay_flash_operations <= 5) then
									erase_sector <= '0';
							  elsif (delay_flash_operations > 5) then
									erase_sector <= '1';
								end if;
							  if (delay_flash_operations > 200) then
									delay_flash_operations <= 0;
									state_of_programming <= SSEND;
								end if;
								
								
			when SSEND => data_out_uart_t <= S_symbol;
							  write_dout <= '1'; 
							  state_of_programming <= WRITE_STATE;
							  
							 
			when WRITE_STATE =>  if (address_s < 768 or address_s = x"FFFFF") then
											write_dout <= '0';
											data_out_flash_sig <= data_in;
											addr_out_flash_sig <= address_s;
													if(address_s = 767) then address_s <= address_s + '1'; end if;
													
													if (data_new = '1') then
														delay_rx <= 1; 
														address_s <= address_s + '1';
												
													elsif (delay_rx > 0 and delay_rx < 100) then
															delay_rx <= delay_rx + 1;
															start <= '1';
			
														
													elsif (delay_rx >= 100 and delay_rx < 130) then
															--data_out_flash <= data_in;
															--addr_out_flash <= address_s;
															delay_rx <= delay_rx + 1;
															start <= '1';
															
													elsif (delay_rx >= 130 and delay_rx < 140) then
															start <= '0';
															delay_rx <= delay_rx + 1;
															--data_out_flash <= data_in;
															--addr_out_flash <= address_s;
															
													elsif delay_rx = 140 then
															--data_out_flash <= data_in;
															--addr_out_flash <= address_s;
															start <= '1';
															delay_rx <= 0;
													end if;
										else 
										address_s <= x"FFFFF";
										state_of_programming <= FSEND;
										write_dout <= '0';
										end if;
							  
													
			when FSEND => data_out_uart_t <= F_symbol;
							  write_dout <= '1'; 
							  state_of_programming <= IDLE;	
				

			when others => state_of_programming <= IDLE;
								write_dout <= '0';
			
		end case;
end if;
end process;
data_out_flash <= data_out_flash_sig;
addr_out_flash <= addr_out_flash_sig;
end;

							  
									
						