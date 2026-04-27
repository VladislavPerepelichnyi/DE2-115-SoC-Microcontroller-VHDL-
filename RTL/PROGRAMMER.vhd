library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity PROGRAMMER is port(
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

--for debugginig 
--ledr : out std_logic_vector(9 downto 0);
--ledg : out std_logic_vector(8 downto 0)

);
end; 

architecture a of PROGRAMMER is 

		
component UART_R
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        rx        : in  std_logic;
        data_out  : out std_logic_vector(7 downto 0);
        dout_new  : out std_logic;
		  rx_ready   : out std_logic
    );
end component;

component UART_T is
    port (
        din       : in  std_logic_vector(7 downto 0); -- Input data
        rst       : in  std_logic;                   -- Reset signal
        clk       : in  std_logic;                   -- System clock
        write_din : in  std_logic;                   -- Write enable signal
        tx        : out std_logic;                   -- UART TX line
        tx_ready  : out std_logic                    -- Ready signal
    );
end component;

component programmer_controller is port(
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
end component;

component flash_write_8 is
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
end component;

--CONNECTIONS BETWEEN PROGRAM CONTROLLER AND RECIVER 
signal data_out_sig: std_logic_vector(7 downto 0);
signal data_new_sig : std_logic;
---------------------------------------------------

--CONNECTIONS BETWEEN PROGRAM CONTROLLER AND TRANSMITTER 
signal din_sig : std_logic_vector(7 downto 0);
signal write_din_sig : std_logic;
---------------------------------------------------

--CONNECTIONS BETWEEN PROGRAM CONTROLLER AND FLASH WRITER
signal	 rst_command_sig :  std_logic;
signal    start_sig           :  std_logic;           -- begin a program operation
signal	 erase_sector_sig    :   std_logic; 
signal    tgt_addr_sig        :  std_logic_vector(19 downto 0); -- target address
signal    tgt_data_sig        :  std_logic_vector(7 downto 0);
---------------------------------------------------
signal fl_dq_sig : std_logic_vector(7 downto 0);
signal fl_addr_sig : std_logic_vector(19 downto 0);
begin
uut_rx: UART_R
    port map (
        clk       => CLOCK_50,
        rst       => not(rst_n_programmer),
        rx        => UART_RXD,
        data_out  => data_out_sig,
        dout_new  => data_new_sig,
		  rx_ready  => open 
    );

uut_tx : UART_T
	  port map(
	  din => din_sig,
	  rst       => not(rst_n_programmer), 
	  clk       => CLOCK_50, 
	  write_din => write_din_sig, 
	  tx        => UART_TXD ,                   -- UART TX line
     tx_ready  => open	
		);

controller_programmer : programmer_controller 
   port map(
	clk => CLOCK_50, 
	rst => rst_n_programmer, 
	-- uart_r
	data_in  =>  data_out_sig, 
   data_new =>  data_new_sig,                      
	-- uart_t
	data_out_uart_t => din_sig, -- Input data
   write_dout      => write_din_sig,                   -- Write enable signal
	-- Control signals
	rst_command =>  rst_command_sig, 
   start       =>   start_sig,             -- begin a program operation
	erase_sector  => erase_sector_sig,  
	data_out_flash => tgt_data_sig,
	addr_out_flash => tgt_addr_sig -- target address
);

Flash_write_comp : flash_write_8
  port map(
    -- Clock & reset
    clk          => CLOCK_50,
    rst_n        => rst_n_programmer,   -- active-low reset
	 rst_command  => rst_command_sig, 
    -- Control signals
    start        => start_sig,           -- begin a program operation
	 erase_sector => erase_sector_sig,  
    tgt_addr     => tgt_addr_sig, -- target address
    tgt_data     =>tgt_data_sig,   -- data byte ton program
    done         => open  ,        -- high => operation complete

    -- S29GLxxxN flash (8-bit mode)
    fl_addr   =>fl_addr_sig,
    fl_dq     =>fl_dq_sig,
    fl_ce_n   =>fl_ce_n,
    fl_oe_n   =>fl_oe_n,
    fl_we_n   =>fl_we_n,
    fl_rst_n  =>fl_rst_n,
    fl_wp_n   =>fl_wp_n,
    fl_ry     =>fl_ry       -- RY/BY# pin (active-low)
  );

fl_addr(22 downto 20) <= "000"; 
fl_addr(19 downto 0) <= fl_addr_sig;
fl_dq <= fl_dq_sig when(rst_n_programmer= '1') else (others => 'Z');
--ledg(7 downto 0)  <= tgt_data_sig;
--ledr <= tgt_addr_sig(9 downto 0);
--ledg(8) <= start_sig;
end;