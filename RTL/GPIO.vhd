LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY GPIO IS
	GENERIC (
	n: INTEGER :=8; -- Number of bits of the registers
	k: INTEGER :=3 -- Number of registers   0=DIR  1=INPUT_VAL 2=OUTPUT_VAL
	);
	PORT (
			-- Writing Pins
			Data_In: in std_logic_vector (n-1 downto 0);
			W: in std_logic;
			
			-- Reading Pins
			Data_Out: out std_logic_vector (n-1 downto 0);
			R: in std_logic;
			
			--Adress
			
			Reg_Add: integer range 0 to k-1;
			
			-- Others Pins
			clk: in std_logic;
			reset: in std_logic;
			PIN : inout std_logic_vector (n-1 downto 0)
			
		);
END GPIO;

ARCHITECTURE behavior of GPIO is

	type registerFile is array(0 to k-1) of std_logic_vector(n-1 downto 0);
	signal registers : registerFile;
	
begin

	--Logic of the registers

process(clk,Data_In,W,Reg_Add,R,registers,reset,PIN)

     begin
	  
	if (reset = '1') then
		registers(0) <= (others => '0'); -- DIR get everything as input
		registers(2) <= (others => '0'); -- Output_VAL => 0
			
	elsif rising_edge(clk) then 
		if(W = '1') then
		    if (Reg_Add = 1) then --Making sure that does not write in register INPUT_VAL
		    else
			registers(Reg_Add) <= Data_In;
		    end if;
           	end if;	
			
		registers (1) <= PIN;
			    
	end if;
			
		
	if(R = '1') then
		Data_Out <= registers(Reg_Add);
	else
		Data_Out <= (others => '0');
	end if;
			
				
end process;
		
		--Behavior of PIN
		
process(PIN, registers)
	
	begin
		
	for i in (n-1) downto 0 LOOP
		if (registers(0)(i) = '0') then -- If is input
			PIN(i) <= 'Z';
				
		else  --If is output
			PIN(i) <= registers(2)(i);  --Get OUTPUT_VALUE 
		end if;
	end loop;
			
end process;
	

	
end behavior;