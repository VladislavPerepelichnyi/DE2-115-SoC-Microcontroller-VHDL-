library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity ALU is port(
	a, b : in std_logic_vector(7 downto 0);
	clk : in std_logic;
	oper : in std_logic_vector(7 downto 0);
	ouput_enable : in std_logic;
	result : out std_logic_vector(7 downto 0);
	carry : out std_logic;
	zero : out std_logic);
end;

architecture A_ALU of ALU is
signal result_with_carry :  std_logic_vector(8 downto 0);
begin 
process(clk)
begin 
if rising_edge(clk) then
	case oper is
	  
	  when "00000010" => --add
	      result_with_carry <= std_logic_vector(unsigned('0' & a) + unsigned('0' & b)); 
	      
		when "00000101" => --or
	      for i in 0 to 7 loop 
			    result_with_carry(i) <= a(i) or b(i);
		    end loop;
	 	   	result_with_carry(8) <= '0';
		
		when "00000110" => --and
	      for i in 0 to 7 loop 
		      	result_with_carry(i) <= a(i) and b(i);
		    end loop;
		
		when "00000111" => --not
	      result_with_carry <='1'& not(a);
	      
		when "00001000" => -- xor
	      for i in 0 to 7 loop 
		      	result_with_carry(i) <= a(i) xor b(i);
		    end loop;
	     	result_with_carry(8) <= '1';
	     	
		when "00001001" => -- srl
	      result_with_carry <= "00"&a(7 downto 1);
	      
		when "00001010" => --sll
	      result_with_carry <= '0'&a(6 downto 0)&'0';
	      
		when "00001100" => --sub
	      result_with_carry <= std_logic_vector(unsigned('0' & a) - unsigned('0' & b));
	  
		when "00010000" => --inc
		    result_with_carry <= std_logic_vector(unsigned('0' & a) + 1);
	      
		when "00010001" => --dec
		    result_with_carry <= std_logic_vector(unsigned('0' & a) - 1);
	      
		when "00010010" => --cmp
		    if a = b then
		      result_with_carry <= "000000001";
		    else
		      result_with_carry <= "000000000";
		    end if;
		
		when "00010011" => --lrot
		    result_with_carry <= '0'&a(6 downto 0)&a(7);
		  
		when "00010100" => --rrot
		    result_with_carry <= '0'&a(0)&a(7 downto 1);
		  
		when others =>
	      result_with_carry <= std_logic_vector(unsigned('0' & a));
	end case;     
end if;		
end process;

		result <= result_with_carry(7 downto 0) when ouput_enable = '1' else
		(others => 'Z');
		carry <= result_with_carry(8);
	   	--zero <= '1' when result_with_carry = "000000000" else '0';
		zero <= '1' when a = "00000000" else '0';

end;