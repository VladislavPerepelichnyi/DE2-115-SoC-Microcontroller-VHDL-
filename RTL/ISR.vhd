library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ISR is port(
	addres_to_databus_en : in std_logic;
	data_in : in std_logic_vector(7 downto 0);
	clk, rst, load_ISR, clear_int_flag: in std_logic;
	timer_int, uart_int : in std_logic;
	hard_int : out std_logic;
	address_for_pc : out std_logic_vector(7 downto 0)
);
end ISR;

architecture a_isr of ISR is
signal counter : integer range 0 to 15 := 0;
signal interrupt_status : std_logic_vector(7 downto 0) := "00000000";
signal hard_int_sig : std_logic_vector(1 downto 0);
signal last_hard_int_sig : std_logic_vector(1 downto 0);
signal clear_int_flag_sig : std_logic;
signal uart_int_sig : std_logic_vector(1 downto 0);
signal timer_int_sig : std_logic_vector(1 downto 0);
begin

process(clk)
begin
	if rising_edge(clk) then
      clear_int_flag_sig <= clear_int_flag;
	  
	  uart_int_sig(0) <= uart_int;
      uart_int_sig(1) <= uart_int_sig(0);
	  
	  timer_int_sig(0) <= timer_int;
      timer_int_sig(1) <= timer_int_sig(0);
	  
	  
    end if;
end process;

process(clk, rst)
begin
	if rst = '1' then
		interrupt_status <= (others => '0');
		hard_int_sig <= "00";
		counter <= 8;
	elsif rising_edge(clk) then
	if clear_int_flag_sig = '1' or clear_int_flag  = '1' then 
	      hard_int_sig <= "00";
	end if;
	if (uart_int_sig(1) = '1' and  interrupt_status(7) = '1') then 
		hard_int_sig <= "10";
		counter <= 7;
	elsif ((timer_int_sig(1) = '1') and (interrupt_status(7) = '1'))  then 
		hard_int_sig <= "01";
		counter <= 7;
	elsif ((counter < 8) and (counter > 0)) then 
		counter <= counter - 1;
		hard_int <= '1';
	else
		hard_int <= '0';
		counter <= 8;
	end if;
	
	if load_ISR = '1' then 
		interrupt_status <= data_in;
	else 
		interrupt_status <= interrupt_status;
	end if;
	
	
	
end if;
end process;

last_hard_int_sig <= hard_int_sig when hard_int_sig /= "00";

--hard_int <= '1' when ((hard_int_sig = "10" or hard_int_sig = "01") and interrupt_status(7) = '1') else '0';

address_for_pc <= "11001000" when last_hard_int_sig = "10" and addres_to_databus_en = '1' -- UART ROM ADDRESS 200 
		else "11100110" when  last_hard_int_sig = "01" and addres_to_databus_en = '1'    -- TIMER ROM ADDRESS 230
		else  (others => 'Z');

end;

