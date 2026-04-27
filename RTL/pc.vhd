library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity pc is port(
clk, rst, en, inc : in std_logic;
data_in : in std_logic_vector(7 downto 0);
output: out std_logic_vector(7 downto 0)
);
end;

architecture ar_pc of pc is
signal output_s :  std_logic_vector(7 downto 0);
begin 
process(clk, rst)
begin 
	if rst = '1' then 
	output_s <="00000000";
	elsif rising_edge(clk) then 
		if en = '1' then 
		output_s <= data_in;
		elsif inc = '1' then 
		output_s <= output_s + '1';
		end if;
	end if;
output <= output_s;
	end process;

end;
