library ieee;
use ieee.std_logic_1164.all;

entity DAO_REG is port(
	input : in std_logic_vector(7 downto 0);
	load, en: in std_logic;
	clk, rst : in std_logic;
	output: out std_logic_vector(7 downto 0)
);
end; 

architecture arc of DAO_REG is 
signal temp :std_logic_vector(7 downto 0);
	begin
		process(clk, rst, load)
		begin
		if rst = '0' then
		temp <= (others => '0');
		elsif load = '1' then temp<=input;
		elsif rising_edge(clk) then 
		
 
		temp <= temp;
		
	end if;
end process;

output <= temp when en = '1' else (others => 'Z');

end;