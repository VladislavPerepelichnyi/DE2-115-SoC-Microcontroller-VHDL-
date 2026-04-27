library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity tl_mcu is port(
CLOCK_50 : in std_logic;
UART_RXD : in std_logic;
UART_TXD : out std_logic;
sw : in std_logic_vector(17 downto 0);

-----------FLASH CONTROL LINES { 
fl_addr  : out std_logic_vector(22 downto 0);-- flash address
fl_dq    : inout std_logic_vector(7 downto 0);--data 8 bit 
fl_we_n  : out std_logic;--write enable = 0, write disable = 1
fl_rst_n : out std_logic;-- rst_inverted (reset when the pin = 0)
fl_wp_n  : out std_logic;  --protection writing = 0, without protection = 1(our case always one)
fl_ry    : in std_logic; --ready = 1 / busy = 0
fl_ce_n  : out std_logic; --flash chip enable = 0/ disable = 1
fl_oe_n  : out std_logic; -- flash output enable output = 0 , disable = 1
-----------FLASH CONTROL LINES } 

--for debugginig 
ledr : out std_logic_vector(15 downto 0);
ledg : out std_logic_vector(8 downto 0)

);
end;

architecture struct of tl_mcu is 

component CPUtl is port(
CLOCK_50: in std_logic;
rst : in std_logic;
switch : in std_logic_vector(7 downto 0);
rx : in std_logic;
tx : out std_logic;
address_to_RAM : out std_logic_vector(7 downto 0);
data_out_from_RAM : in std_logic_vector(23 downto 0);
ledr : out std_logic_vector(15 downto 0)
);
end component;

component Single_port_RAM_VHDL is
port(
 RAM_ADDR: in std_logic_vector(7 downto 0); -- Address to write/read RAM
 RAM_DATA_IN: in std_logic_vector(23 downto 0); -- Data to write into RAM
 RAM_WR: in std_logic; -- Write enable 
 --RAM_CLOCK: in std_logic; -- clock input for RAM
 RAM_DATA_OUT: out std_logic_vector(23 downto 0) -- Data output of RAM
);
end component;

component BOOT_LOADER is port(
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
end component;

component PROGRAMMER is port(
CLOCK_50 : in std_logic;
UART_RXD : in std_logic;
UART_TXD : out std_logic;
rst_n_programmer : in std_logic;

-----------FLASH CONTROL LINES { 
fl_addr  : out std_logic_vector(22 downto 0);-- flash address
fl_dq    : inout std_logic_vector(7 downto 0);--data 8 bit 
fl_we_n  : out std_logic;--write enable = 0, write disable = 1
fl_rst_n : out std_logic;-- rst_inverted (reset when the pin = 0)
fl_wp_n  : out std_logic;  --protection writing = 0, without protection = 1(our case always one)
fl_ry    : in std_logic; --ready = 1 / busy = 0
fl_ce_n  : out std_logic; --flash chip enable = 0/ disable = 1
fl_oe_n  : out std_logic -- flash output enable output = 0 , disable = 1
-----------FLASH CONTROL LINES } 



);
end component;
--UART signals
signal UART_RXD_prog, UART_TXD_prog, UART_RXD_MC, UART_TXD_MC : std_logic; 


--RAM signals
signal RAM_ADDR_sig : std_logic_vector(7 downto 0);
signal RAM_data_sig : std_logic_vector(23 downto 0);
signal RAM_WE_sig : std_logic;
signal RAM_data_out_sig : std_logic_vector(23 downto 0);
signal mc_address_ram_sig : std_logic_vector(7 downto 0);
--Boot signals
signal RAM_ADDR_boot_sig : std_logic_vector(7 downto 0);
signal select_address_sourse_sig : std_logic;
signal fl_addr_boot_sig  : std_logic_vector(22 downto 0); 
signal fl_dq_boot_sig    : std_logic_vector(7 downto 0);
signal fl_we_n_boot_sig  : std_logic; --write enable = 0, write disable = 1
signal fl_rst_n_boot_sig : std_logic; -- rst_inverted (reset when the pin = 0)
signal fl_ce_n_boot_sig  : std_logic;--flash chip enable = 0/ disable = 1
signal fl_oe_n_boot_sig  : std_logic;
signal rst_MMU_sig       : std_logic;

--prog signals
signal fl_addr_prog_sig  : std_logic_vector(22 downto 0); 
signal fl_dq_prog_sig    : std_logic_vector(7 downto 0);
signal fl_we_n_prog_sig  : std_logic; --write enable = 0, write disable = 1
signal fl_rst_n_prog_sig : std_logic; -- rst_inverted (reset when the pin = 0)
signal fl_ce_n_prog_sig  : std_logic;--flash chip enable = 0/ disable = 1
signal fl_oe_n_prog_sig  : std_logic; 
signal fl_ry_prog_sig    : std_logic;
signal fl_wp_n_prog_sig  : std_logic;

begin 
RAM_ADDR_sig <= mc_address_ram_sig when select_address_sourse_sig = '1' else RAM_ADDR_boot_sig;


uut_CPUtl : CPUtl  port map(
CLOCK_50 => CLOCK_50,
rst => rst_MMU_sig,
switch => sw(7 downto 0),
rx  =>UART_RXD_MC, 
tx  => UART_TXD_MC,
address_to_RAM => mc_address_ram_sig,
data_out_from_RAM => RAM_data_out_sig,
ledr =>ledr(15 downto 0)
);


uut_RAM:  Single_port_RAM_VHDL port map(
 RAM_ADDR    => RAM_ADDR_sig,  -- Address to write/read RAM
 RAM_DATA_IN =>RAM_data_sig, -- Data to write into RAM
 RAM_WR => RAM_WE_sig, -- Write enable 
 RAM_DATA_OUT => RAM_data_out_sig -- Data output of RAM
);

uut_BOOT_LOADER : BOOT_LOADER  port map(
	global_rst => not(sw(17)),
	rst_MMU => rst_MMU_sig,  -- rst mmu while loading ram
	clk => CLOCK_50, 
	select_address_sourse => select_address_sourse_sig,  -- 0 for boot loader, 1 for program counter in start mode
	RAM_WE => RAM_WE_sig, --ram write enable 
	
	
	dataout => RAM_data_sig,  --for data to RAM 
	RAM_address => RAM_ADDR_boot_sig, 
	--FLASH PART
	-----------FLASH CONTROL LINES { 
   fl_addr  => fl_addr_boot_sig, 
	fl_dq    => fl_dq, 
	fl_we_n  => fl_we_n_boot_sig, --write enable = 0, write disable = 1
	fl_rst_n => fl_rst_n_boot_sig, -- rst_inverted (reset when the pin = 0)
	fl_ry    => '1',  --ready = 1 / busy = 0
	fl_ce_n  => fl_ce_n_boot_sig, --flash chip enable = 0/ disable = 1
	fl_oe_n  => fl_oe_n_boot_sig, -- flash output enable output = 0 , disable = 1
	-----------FLASH CONTROL LINES } 
	
	ready_flag => ledg(8)
);

uut_PROGRAMMER : PROGRAMMER  port map(
CLOCK_50 => CLOCK_50,
UART_RXD => UART_RXD_prog, 
UART_TXD => UART_TXD_prog, 
rst_n_programmer     => sw(17),

-----------FLASH CONTROL LINES { 
fl_addr  => fl_addr_prog_sig, --: out std_logic_vector(22 downto 0);-- flash address
fl_dq    => fl_dq_prog_sig,--data 8 bit 
fl_we_n  => fl_we_n_prog_sig,--write enable = 0, write disable = 1
fl_rst_n => fl_rst_n_prog_sig,-- rst_inverted (reset when the pin = 0)
fl_wp_n  => fl_wp_n_prog_sig,  --protection writing = 0, without protection = 1(our case always one)
fl_ry    => fl_ry, --ready = 1 / busy = 0
fl_ce_n  => fl_ce_n_prog_sig, --flash chip enable = 0/ disable = 1
fl_oe_n  => fl_oe_n_prog_sig -- flash output enable output = 0 , disable = 1
-----------FLASH CONTROL LINES } 

--for debugginig 
--ledr : out std_logic_vector(9 downto 0);
--ledg : out std_logic_vector(8 downto 0)

);

fl_addr  <= fl_addr_prog_sig  when sw(17) = '1' else fl_addr_boot_sig; -- flash address
fl_dq    <= fl_dq_prog_sig    when sw(17) = '1' else (others => 'Z');--data 8 bit 
fl_we_n  <= fl_we_n_prog_sig  when sw(17) = '1' else fl_we_n_boot_sig;--write enable = 0, write disable = 1
fl_rst_n <= fl_rst_n_prog_sig when sw(17) = '1' else fl_rst_n_boot_sig;-- rst_inverted (reset when the pin = 0)
fl_wp_n  <= fl_wp_n_prog_sig  when sw(17) = '1' else '1';  --protection writing = 0, without protection = 1(our case always one)
--fl_ry    <= fl_ry_prog_sig when sw(17) = '1' else fl_addr_boot_sig; --ready = 1 / busy = 0
fl_ce_n  <= fl_ce_n_prog_sig when sw(17) = '1' else fl_ce_n_boot_sig; --flash chip enable = 0/ disable = 1
fl_oe_n  <= fl_oe_n_prog_sig when sw(17) = '1' else fl_oe_n_boot_sig; -- flash output enable output = 0 , disable = 1
UART_TXD <= UART_TXD_prog when sw(17) = '1' else UART_TXD_MC; 
UART_RXD_prog <= UART_RXD when sw(17) ='1' else '1';
UART_RXD_MC <= UART_RXD   when sw(17) ='0' else '1';

end;