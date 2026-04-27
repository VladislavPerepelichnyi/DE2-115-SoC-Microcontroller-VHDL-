library ieee;
use ieee.std_logic_1164.all;

entity IR is port(
	input : in std_logic_vector(7 downto 0);
	load: in std_logic;
	clk, rst : in std_logic;
	output: out std_logic_vector(7 downto 0)
);
end; 

architecture arc of IR is 
signal temp :std_logic_vector(7 downto 0);
	begin
		process(clk, rst)
		begin
		if rst = '1' then
		temp <= (others => '0');
		elsif rising_edge(clk) then 
		if load = '1' then 
		temp<=input;
		else 
		temp <= temp;
		end if;
	end if;
end process;
output <= temp;
end;