library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------
-- Entity: flash_write_8
-- Purpose: Demonstrate single-byte program flow for S29GLxxxN in x8 mode.
-- 
-- In 8-bit mode:
--  - Unlock addresses are 0x555 and 0x2AA (instead of 0xAAA/0x555 in word mode).
--  - Data bus is 8 bits wide.
-------------------------------------------------------------------------------
entity flash_write_8 is
  port (
    -- Clock & reset
    clk      : in  std_logic;
    rst_n    : in  std_logic;  -- active-low reset
	 rst_command : in std_logic;
    -- Control signals
    start    : in  std_logic;           -- begin a program operation
	 erase_sector : in  std_logic; 
    tgt_addr : in  std_logic_vector(19 downto 0); -- target address
    tgt_data : in  std_logic_vector(7 downto 0);  -- data byte to program
    done     : out std_logic;           -- high => operation complete

    -- S29GLxxxN flash (8-bit mode)
    fl_addr  : out std_logic_vector(19 downto 0);
    fl_dq    : inout std_logic_vector(7 downto 0);
    fl_ce_n  : out std_logic;
    fl_oe_n  : out std_logic;
    fl_we_n  : out std_logic;
    fl_rst_n : out std_logic;
    fl_wp_n  : out std_logic;
    fl_ry : in std_logic           -- RY/BY# pin (active-low)
  );
end flash_write_8;

architecture rtl of flash_write_8 is
--(AAA, AA)(555, 55)(AAA, A0)(PA, PD)
  ------------------------------------------------------------------------
  -- Unlock addresses for 8-bit mode:
  --   0x555, 0x2AA
  ------------------------------------------------------------------------
  constant ADDR_AAA : std_logic_vector(19 downto 0) := x"00AAA";
  constant ADDR_555 : std_logic_vector(19 downto 0) := x"00555";
  constant ADDR_000 : std_logic_vector(19 downto 0) := x"00000";

  -- Unlock data bytes
  constant DATA_AA  : std_logic_vector(7 downto 0) := x"AA";
  constant DATA_55  : std_logic_vector(7 downto 0) := x"55";
  constant DATA_A0  : std_logic_vector(7 downto 0) := x"A0";
  constant DATA_80  : std_logic_vector(7 downto 0) := x"80";
  constant DATA_30  : std_logic_vector(7 downto 0) := x"30";
  
  constant DATA_RESET : std_logic_vector(7 downto 0) := x"F0";
  --constant time_delay : integer 
  signal counter_of_state : integer := 0;

  type state_type is (
    ST_IDLE,
    ST_AAA_AA,   -- write 0xAA -> 0xAAA
    ST_555_55,  -- write 0x55 -> 0x555
    ST_AAA_A0, -- write 0xA0 -> 0xAAA
    ST_PAPD,    -- write 'tgt_data' -> 'tgt_addr'
    ST_WAIT,     -- wait for fl_ry_by_n=1
	 RESET_STATE,
	 ST_AAA_80,
	 ST_SA_30,
	 ST_AAA_AA2,
	 ST_555_552
	 
  );
signal curr_state: state_type;
signal start_flag, reset_flag : std_logic:='0';
signal cnt_ce, cnt_rst : integer := 0 ;
signal erase_sector_flag : std_logic:='0';
  -- Internal registers for driving the flash
--  signal fl_addr_s   : std_logic_vector(19 downto 0) := (others => '0');
--  signal fl_dq_s     : std_logic_vector(7 downto 0)  := (others => '0');
--  signal fl_ce_n_s   : std_logic := '1';
--  signal fl_oe_n_s   : std_logic := '1';
--  signal fl_we_n_s   : std_logic := '1';
--  signal fl_rst_n_s  : std_logic := '1';
--  signal fl_wp_n_s   : std_logic := '1';



begin
process(clk, rst_n, start, rst_command, erase_sector)
begin
if rst_n = '0' then 
	fl_ce_n <= '1'; -- chip desible
	fl_oe_n <= '1';--output desible 
	fl_we_n <= '1'; --write desible
	fl_rst_n <= '0';-- flash reset
	fl_wp_n <= '1';--dont protect
	start_flag <= '0';
	curr_state <= ST_IDLE;
	counter_of_state <= 0;
	done<='1';
	cnt_ce <= 0; 
	cnt_rst <= 0;
	erase_sector_flag <= '0';
elsif rst_command = '0'  then 
		reset_flag <= '1';
		curr_state <= RESET_STATE;
		fl_rst_n <= '1';
		fl_ce_n <= '0';
		done<='0';
		cnt_rst <= 0;
elsif start = '0' then
		start_flag <= '1';
		erase_sector_flag <= '0';
		curr_state <= ST_IDLE;
		fl_rst_n <= '1';
		fl_ce_n <= '0';
		done<='0';
		counter_of_state <= 0;
elsif erase_sector = '0' then
		erase_sector_flag <= '1';
		curr_state <= ST_IDLE;
		fl_rst_n <= '1';
		fl_ce_n <= '0';
		done<='0';
		counter_of_state <= 0;
		
elsif rising_edge(clk) then 
	if start_flag = '1' and counter_of_state < 80 then 
		case curr_state is 
			when ST_IDLE =>if (cnt_ce < 10) then
									curr_state <= ST_IDLE;
									cnt_ce <= cnt_ce + 1;
								else
									curr_state <= ST_AAA_AA;
									counter_of_state <= counter_of_state + 1;
									cnt_ce <= 0;
								end if;
			when ST_AAA_AA =>if(counter_of_state < 20) then 
									curr_state <= ST_AAA_AA;
									if(counter_of_state <5) then 
										  fl_we_n <= '1'; --write desible
									elsif(counter_of_state < 15 and counter_of_state>= 5) then 
											fl_we_n <= '0';
									elsif (counter_of_state >=15) then
											fl_we_n <= '1';
									end if;
								  else curr_state <= ST_555_55;
								  end if;
								  counter_of_state <= counter_of_state + 1;
								  
			when ST_555_55 =>if(counter_of_state < 40) then 
									curr_state <= ST_555_55;
									if(counter_of_state <25) then 
										  fl_we_n <= '1'; --write desible
									elsif(counter_of_state < 35 and counter_of_state>= 25) then 
											fl_we_n <= '0';
									elsif (counter_of_state >=35) then
											fl_we_n <= '1';
									end if;
								  else curr_state <= ST_AAA_A0;
								  end if;
								  counter_of_state <= counter_of_state + 1;
			
			
			when ST_AAA_A0 =>if(counter_of_state < 60) then 
									curr_state <= ST_AAA_A0;
									if(counter_of_state <45) then 
										  fl_we_n <= '1'; --write desible
									elsif(counter_of_state < 55 and counter_of_state>= 45) then 
											fl_we_n <= '0';
									elsif (counter_of_state >=55) then
											fl_we_n <= '1';
									end if;
								  else curr_state <= ST_PAPD;
								  end if;
								  counter_of_state <= counter_of_state + 1;
			
			
			when ST_PAPD =>if(counter_of_state < 90) then 
									curr_state <= ST_PAPD;
									if(counter_of_state <65) then 
										  fl_we_n <= '1'; --write desible
									elsif(counter_of_state < 75 and counter_of_state>= 65) then 
											fl_we_n <= '0';
									elsif (counter_of_state >=75) then
											fl_we_n <= '1';
									end if;
								  else curr_state <= ST_WAIT;
								  end if;
								  counter_of_state <= counter_of_state + 1;
			
			
			when ST_WAIT => if(fl_ry = '1') then 
										curr_state <= ST_IDLE;
										done<='1';
										
								 else curr_state <= ST_WAIT;	
								 end if;
								 start_flag <= '0';
								 counter_of_state <=0;
								 
			when others => curr_state <= ST_IDLE;
								start_flag <= '0';
								counter_of_state <=0;
		end case;
		-------------------------------------------------------------------
		-- AAA AA    555 55   AAA 80   AAA AA   555 55   SA 30
		-----------------------------------------------------------------
		elsif erase_sector_flag = '1' and counter_of_state < 130 then 
		case curr_state is 
			when ST_IDLE =>if (cnt_ce < 10) then
									curr_state <= ST_IDLE;
									cnt_ce <= cnt_ce + 1;
								else
									curr_state <= ST_AAA_AA;
									counter_of_state <= counter_of_state + 1;
									cnt_ce <= 0;
								end if;
			when ST_AAA_AA =>if(counter_of_state < 20) then 
									curr_state <= ST_AAA_AA;
									if(counter_of_state <5) then 
										  fl_we_n <= '1'; --write desible
									elsif(counter_of_state < 15 and counter_of_state>= 5) then 
											fl_we_n <= '0';
									elsif (counter_of_state >=15) then
											fl_we_n <= '1';
									end if;
								  else curr_state <= ST_555_55;
								  end if;
								  counter_of_state <= counter_of_state + 1;
								  
			when ST_555_55 =>if(counter_of_state < 40) then 
									curr_state <= ST_555_55;
									if(counter_of_state <25) then 
										  fl_we_n <= '1'; --write desible
									elsif(counter_of_state < 35 and counter_of_state>= 25) then 
											fl_we_n <= '0';
									elsif (counter_of_state >=35) then
											fl_we_n <= '1';
									end if;
								  else curr_state <= ST_AAA_80;
								  end if;
								  counter_of_state <= counter_of_state + 1;
			
			
			when ST_AAA_80 =>if(counter_of_state < 60) then 
									curr_state <= ST_AAA_80;
									if(counter_of_state <45) then 
										  fl_we_n <= '1'; --write desible
									elsif(counter_of_state < 55 and counter_of_state>= 45) then 
											fl_we_n <= '0';
									elsif (counter_of_state >=55) then
											fl_we_n <= '1';
									end if;
								  else curr_state <= ST_AAA_AA2;
								  end if;
								  counter_of_state <= counter_of_state + 1;
			
			
			when ST_AAA_AA2 =>if(counter_of_state < 80) then 
									curr_state <= ST_AAA_AA2;
									if(counter_of_state < 65) then 
										  fl_we_n <= '1'; --write desible
									elsif(counter_of_state < 75 and counter_of_state>= 65) then 
											fl_we_n <= '0';
									elsif (counter_of_state >=75) then
											fl_we_n <= '1';
									end if;
								  else curr_state <= ST_555_552;
								  end if;
								  counter_of_state <= counter_of_state + 1;
								  
			when ST_555_552 =>if(counter_of_state < 100) then 
									curr_state <= ST_555_552;
									if(counter_of_state <85) then 
										  fl_we_n <= '1'; --write desible
									elsif(counter_of_state < 95 and counter_of_state>= 85) then 
											fl_we_n <= '0';
									elsif (counter_of_state >=95) then
											fl_we_n <= '1';
									end if;
								  else curr_state <= ST_SA_30;
								  end if;
								  counter_of_state <= counter_of_state + 1;
								  
								  
			when ST_SA_30 =>if(counter_of_state < 120) then 
									curr_state <= ST_SA_30;
									if(counter_of_state <105) then 
										  fl_we_n <= '1'; --write desible
									elsif(counter_of_state < 115 and counter_of_state>= 105) then 
											fl_we_n <= '0';
									elsif (counter_of_state >=115) then
											fl_we_n <= '1';
									end if;
								  else curr_state <= ST_WAIT;
								  end if;
								  counter_of_state <= counter_of_state + 1;
			
			
			when ST_WAIT => if(fl_ry = '1') then 
										curr_state <= ST_IDLE;
										done<='1';
										
								 else curr_state <= ST_WAIT;	
								 end if;
								 erase_sector_flag <= '0';
								 counter_of_state <=0;
								 
			when others => curr_state <= ST_IDLE;
								erase_sector_flag <= '0';
								counter_of_state <=0;
		end case;
	
	elsif(reset_flag = '1') then 

				if cnt_rst < 10 then 
					
					fl_we_n <= '1';
				elsif(cnt_rst >= 10 and cnt_rst < 20 ) then 
					
					fl_we_n <= '0';
				elsif(cnt_rst >= 20 and cnt_rst < 30)then
				fl_we_n <= '1';
				elsif(cnt_rst >= 30) then
				cnt_rst <= 0;
				reset_flag <= '0';
				curr_state <= ST_IDLE;
				end if;
		cnt_rst <= cnt_rst + 1;
		
		
	     
	else 						 
		
		curr_state <= ST_IDLE;
		start_flag <= '0';
		erase_sector_flag <= '0';
		done<='1';
		counter_of_state <=0;
		cnt_rst <= 0;
		reset_flag <= '0';
	end if;
end if;	
end process;
--    done     : out std_logic;           -- high => operation complete
--    fl_addr  : out std_logic_vector(19 downto 0);
--    fl_dq    : inout std_logic_vector(7 downto 0);
--    fl_ce_n  : out std_logic;
--    fl_oe_n  : out std_logic;
--    fl_we_n  : out std_logic;
--    fl_rst_n : out std_logic;
--    fl_wp_n  : out std_logic;

process(curr_state)
begin
	if curr_state = ST_IDLE then 
		--fl_ce_n <= '0'; -- chip enible
		--fl_oe_n <= '1';--output desible 
		--fl_rst_n <= '1';-- flash not reset
		--fl_wp_n <= '1';--dont protect

		fl_addr <= (others => '0');
		fl_dq   <= (others => '0');
		
	elsif curr_state = ST_AAA_AA or curr_state = ST_AAA_AA2 then

		
		fl_addr <= ADDR_AAA;
		fl_dq   <= DATA_AA;
		
	elsif curr_state = ST_555_55 or curr_state = ST_555_552 then

		
		fl_addr <= ADDR_555;
		fl_dq   <= DATA_55;
		
	elsif curr_state = ST_AAA_A0 then

		
		fl_addr <= ADDR_AAA;
		fl_dq   <= DATA_A0;
		
	elsif curr_state = ST_PAPD then

		
		fl_addr <= tgt_addr;
		fl_dq   <= tgt_data;
	
	elsif curr_state = ST_AAA_80 then

		
		fl_addr <= ADDR_AAA;
		fl_dq   <= DATA_80;
		
	elsif curr_state = ST_SA_30 then

		
		fl_addr <= ADDR_000;
		fl_dq   <= DATA_30;
		
	elsif curr_state = ST_WAIT then
	
	elsif curr_state = RESET_STATE then 
	fl_dq <= DATA_RESET;
	end if;
		
		
end process;
end architecture;

