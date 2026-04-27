library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity timer is port(
	rst, clk, load_ctr, load_cdr : in std_logic;
	data_in : in std_logic_vector(7 downto 0);
	timer_interrupt : out std_logic
);
end;

architecture a of timer is 
component DR  port(
		input : in std_logic_vector(7 downto 0);
		load, en: in std_logic;
		clk, rst : in std_logic;
		output: out std_logic_vector(7 downto 0)
		);
end component; 
signal cmp_flag : std_logic; 
signal out_ctr, out_cdr,freq_dev, cnt : std_logic_vector(15 downto 0);

begin
CTR : DR port map(input => data_in, load => load_ctr, en => '1', clk =>clk, rst => rst, output => out_ctr(15 downto 8));
CDR : DR port map(input => data_in, load => load_cdr, en => '1', clk =>clk, rst => rst, output => out_cdr(15 downto 8));
process(clk, rst)
begin
if rst = '1' then 
	freq_dev <= (others => '0');
	cnt <= (others => '0');
	cmp_flag <= '0';
	timer_interrupt <= '0';
	out_ctr(7 downto 0) <= (others => '0');
	out_cdr(7 downto 0) <= (others => '0');
elsif rising_edge(clk) then 
	if cmp_flag  = '1' then cmp_flag <= '0'; end if;
	if freq_dev < '0'&out_ctr(14 downto 0) then
		freq_dev <= freq_dev + 1;
	else 
		freq_dev <= (others => '0');
		if cnt < out_cdr then  cnt <= cnt + 1;
		else cnt <= (others => '0'); cmp_flag <='1';
		end if;
	end if;
	if cmp_flag = '1' and out_ctr(15) = '1' then 
		--cmp_flag <= '0';
		timer_interrupt <= '1';
	else
		--cmp_flag <= '0';
		timer_interrupt <= '0';
	end if;
end if;
end process;
end;


		
	



