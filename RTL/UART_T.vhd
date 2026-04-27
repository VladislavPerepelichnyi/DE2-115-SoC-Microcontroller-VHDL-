
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;



entity shift_register is port(
	din : in std_logic_vector(7 downto 0);
	rst : in std_logic;
	clk : in std_logic;
	write_din : in std_logic; -- data in enabler
	LSB : out std_logic;
	ena_shift : in std_logic; -- Enable shift register
	ena_load : in std_logic); -- Enable data load
	
end shift_register;

architecture a of shift_register is
signal s_reg :  std_logic_vector(7 downto 0);

begin
	process (clk, rst)
    begin	
	if rst = '1' then
		s_reg <= "00000000";
	elsif rising_edge(clk) then
	
		if write_din = '1' and ena_load = '1' then 
			s_reg <= din;
		end if;
		
		if ena_shift = '1' then
			s_reg <= '0'&s_reg(7 downto 1);
		end if;
	end if;
	end process;
	LSB <= s_reg(0);

end;














library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity dff_out is port(
	data : in std_logic;
	rst : in std_logic;
	clk : in std_logic;
	set_output : in std_logic; 
	ena_output : in std_logic;
	tx : out std_logic; 
	clr_output : in std_logic); 
end dff_out;

architecture a of dff_out is

begin
	process (clk, rst)
	begin
	if rst = '1' then
		--set_output <= '0';
		--ena_output <= '0';
		--clr_output <= '0';
		 tx <= '1';
		
	elsif rising_edge(clk) then
	
		if set_output = '1' then 
			tx <= '1';
		elsif clr_output = '1' then
			tx <= '0';
		elsif ena_output = '1' then	
			tx <= data;
		end if; 
	end if;
	end process;

end;












library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all; -- For integer operations

entity tcount is
    port (
        clk     : in  std_logic;  -- System clock
        rst     : in  std_logic;  -- Active-high reset
        te      : in  std_logic;  -- Timer enable
        t1      : out std_logic   -- Timer terminal count signal
    );
end tcount;

architecture a of tcount is
	 constant clk_freq : integer := 50000000;
	 constant baud : integer := 115200;
	 constant t1_count : integer := clk_freq/baud;
    -- -- Define the clock divider constant
    -- constant DIVIDER : integer := 5208; -- Example: for 9600 baud with 50 MHz clock
    signal count     : integer range 0 to t1_count-1 := 0; -- Counter signal
    signal t1_s      : std_logic := '0'; -- Internal t1 signal
	--constant t2_count : integer := t1_count/2;
begin
    -- Output assignment
    t1 <= t1_s;

    -- Timer process
    process (clk, rst)
    begin
        if rst = '1' then
            -- Reset the counter and output
            --t1 <= '0';
            t1_s <= '0';
        elsif rising_edge(clk) then
            if te = '1' then
                -- Timer is enabled
                if count = t1_count-1 then
                    -- When terminal count is reached
                    count <= 0;  -- Reset the counter
                    t1_s <= '1'; -- Generate terminal count signal
                else
                    count <= count + 1; -- Increment the counter
                    t1_s <= '0';        -- Ensure t1 is low until terminal count
                end if;
            else
                -- Timer is disabled
                count <= 0;  -- Optionally reset the counter when disabled
                t1_s <= '0';
            end if;
        end if;
    end process;
end;



















library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity controller_tx is
    port (
        rst          : in  std_logic; -- Reset signal (active low)
        clk          : in  std_logic; -- Clock signal
        t1   		   : in  std_logic; -- Timer tick signal
        write_din    : in  std_logic; -- Write request signal
        ena_shift    : out std_logic; -- Enable shift register
        ena_load     : out std_logic; -- Enable data load
        te           : out std_logic; -- Enable timer
        set_output   : out std_logic; -- Set output signal
        clr_output   : out std_logic; -- Clear output signal
        ena_output   : out std_logic  -- Enable output signal
    );
end controller_tx;

architecture a of controller_tx is

    -- State enumeration
    type sm is (idle, send_start, clear_timer, send_data, shift_count, test_eoc, send_stop);
    signal current_state, next_state : sm;

    -- Output signal defaults
    signal ena_shift_s  : std_logic := '0';
    signal ena_load_s   : std_logic := '0';
    signal te_s         : std_logic := '0';
    signal set_output_s : std_logic := '0';
    signal clr_output_s : std_logic := '0';
    signal ena_output_s : std_logic := '0';
	signal dcount : integer;

begin
    -- Assign internal signals to output ports
    ena_shift <= ena_shift_s;
    ena_load <= ena_load_s;
    te <= te_s;
    set_output <= set_output_s;
    clr_output <= clr_output_s;
    ena_output <= ena_output_s;

    -- State machine process
    process (clk, rst)
    begin
        if rst = '1' then
			-- Default signal values
			ena_shift_s  <= '0';
			ena_load_s   <= '0';
			te_s         <= '0';
			set_output_s <= '0';
			clr_output_s <= '0';
			ena_output_s <= '0';
			dcount <= 0;
            current_state <= idle; -- Reset to idle state
			
        elsif rising_edge(clk) then
        
		  
        case current_state is
            -- Idle state: Wait for `write_din` to begin transmission
            when idle =>
				set_output_s <= '1';
                ena_load_s <= '1';   -- Enable loading data into the shift register
				dcount <= 0;
				te_s <= '0';
                if write_din = '1' then
                    next_state <= send_start;
                else
                    next_state <= idle;
                end if;

            -- Send start bit state
            when send_start =>
				ena_load_s <= '0'; -- turn off load enable
				        set_output_s <= '0';
                clr_output_s <= '1'; -- Clear output signal (0 bit is start bit)
                te_s <= '1';         -- Enable the timer (tcount)
                if t1 = '1' then
                    next_state <= send_data;
                else
                    next_state <= send_start;
                end if;

            -- -- Clear timer state
            -- when clear_timer =>
                -- --clr_dcount_s <= '1'; -- Clear the bit counter (dcount)
                -- te_s <= '1';         -- Enable the timer
                -- next_state <= send_data;

            -- Send data bits state
            when send_data =>
				        clr_output_s <= '0';
                ena_output_s <= '1'; -- Enable data transmission
                te_s <= '1';         -- Enable the timer
                if t1 = '1' then
                    next_state <= shift_count;
                else
                    next_state <= send_data;
                end if;

            -- Shift count state
            when shift_count =>
                ena_shift_s <= '1'; -- Enable shifting of data
				te_s <= '1';
				dcount <= dcount + 1;
                
                next_state <= test_eoc;


            -- Test end of count state
            when test_eoc =>
				        te_s <= '1';
				        ena_shift_s <= '0';
                if dcount = 8 then
                    next_state <= send_stop; -- Proceed to send the stop bit
                else
                    next_state <= send_data; -- Continue sending data bits
                end if;

            -- Send stop bit state
            when send_stop =>
				ena_output_s <= '0';
                set_output_s <= '1'; -- Set the output signal
                te_s <= '1';         -- Enable the timer
                if t1 = '1' then
                    next_state <= idle; -- Return to idle state
                else
                    next_state <= send_stop;
                end if;

            -- Default case to handle unexpected situations
            when others =>
                next_state <= idle;
        end case;
        
		  end if;
		  current_state <= next_state; -- Transition to the next state
    end process;
end architecture;















library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_T is
    port (
        din       : in  std_logic_vector(7 downto 0); -- Input data
        rst       : in  std_logic;                   -- Reset signal
        clk       : in  std_logic;                   -- System clock
        write_din : in  std_logic;                   -- Write enable signal
        tx        : out std_logic;                   -- UART TX line
        tx_ready  : out std_logic                    -- Ready signal
    );
end UART_T;

architecture a of UART_T is
    -- Internal signals to connect the components
    signal t1          : std_logic;                  -- Timer terminal count
    signal ena_shift    : std_logic;                  -- Enable shifting for shift register
    signal ena_load     : std_logic;                  -- Enable loading data to shift register
    signal te           : std_logic;                  -- Timer enable
    signal set_output   : std_logic;                  -- Set TX output
    signal clr_output   : std_logic;                  -- Clear TX output
    signal ena_output   : std_logic;                  -- Enable TX output
    signal LSB          : std_logic;                  -- Least significant bit from shift register
    -- Component declarations
    component tcount
        port (
            clk : in std_logic;
            rst : in std_logic;
            te  : in std_logic;
            t1  : out std_logic
        );
    end component;

    component controller_tx
        port (
            rst         : in std_logic;
            clk         : in std_logic;
            t1          : in std_logic;
            write_din   : in std_logic;
            ena_shift   : out std_logic;
            ena_load    : out std_logic;
            te          : out std_logic;
            set_output  : out std_logic;
            clr_output  : out std_logic;
            ena_output  : out std_logic
        );
    end component;

    component shift_register
        port (
            din        : in std_logic_vector(7 downto 0);
            rst        : in std_logic;
            clk        : in std_logic;
            write_din  : in std_logic;
            ena_shift  : in std_logic;
            ena_load   : in std_logic;
            LSB        : out std_logic
        );
    end component;

    component dff_out
        port (
            data        : in std_logic;
            rst         : in std_logic;
            clk         : in std_logic;
            set_output  : in std_logic;
            ena_output  : in std_logic;
            tx          : out std_logic;
            clr_output  : in std_logic
        );
    end component;

	 
begin
    -- Instantiate the tcount component
       tcount_inst: tcount
        port map (
            clk => clk,
            rst => rst,
            te  => te,
            t1  => t1
        );

    controller_tx_inst: controller_tx
        port map (
            rst         => rst,
            clk         => clk,
            t1          => t1,
            write_din   => write_din,
            ena_shift   => ena_shift,
            ena_load    => ena_load,
            te          => te,
            set_output  => set_output,
            clr_output  => clr_output,
            ena_output  => ena_output
        );

    shift_register_inst: shift_register
        port map (
            din        => din,
            rst        => rst,
            clk        => clk,
            write_din  => write_din,
            ena_shift  => ena_shift,
            ena_load   => ena_load,
            LSB        => LSB
        );

    dff_out_inst: dff_out
        port map (
            data        => LSB,
            rst         => rst,
            clk         => clk,
            set_output  => set_output,
            ena_output  => ena_output,
            tx          => tx,
            clr_output  => clr_output
        );
    tx_ready <= ena_load; 


end architecture;












--library ieee;
--use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;
--
--entity tb_UART_T is
--end tb_UART_T;
--
--architecture behavior of tb_UART_T is
--    -- Component Declaration for the Unit Under Test (UUT)
--    component UART_T
--        port (
--        din       : in  std_logic_vector(7 downto 0); -- Input data
--        rst       : in  std_logic;                   -- Reset signal
--        clk       : in  std_logic;                   -- System clock
--        write_din : in  std_logic;                   -- Write enable signal
--        tx        : out std_logic;                   -- UART TX line
--        tx_ready  : out std_logic                    -- Ready signal
--    );
--	 
--    end component;
--
--    -- Signals for simulation
--	 signal din       : std_logic_vector(7 downto 0) := (others => '0');
--	 signal rst       : std_logic;
--    signal clk       : std_logic := '0';
--    signal write_din : std_logic := '0';
--    signal tx        : std_logic;
--	 signal tx_ready        : std_logic;
--
--    -- Clock period constant
--    constant clk_period : time := 10 ns;
--
--begin
--    -- Instantiate the Unit Under Test (UUT)
--    uut: UART_T
--				port map (
--				din        => din,        
--            rst        => rst,
--            clk        => clk,
--            write_din  => write_din,
--            tx         => tx,
--            tx_ready   => tx_ready
--    );
--
--    -- Clock generation process
--    clk_process: process
--    begin
--        clk <= '0';
--        wait for clk_period / 2;
--        clk <= '1';
--        wait for clk_period / 2;
--    end process;
--
--    -- Stimulus process
--    stimulus_process: process
--    begin
--        -- Reset the UART
--        rst <= '1';
--        wait for clk_period;
--        rst <= '0';
--
--        -- Test case 1: Transmit "10101010"
--        din <= "11001100"; -- Load data
--        write_din <= '1'; -- Trigger data transmission
--        
--        wait for 10*clk_period;
--        din <= "10010011";
--        wait for 5000*clk_period;
--        write_din <= '0';
--        --wait for clk_period;
--        --write_din <= '0'; -- Release the trigger
--        --wait for clk_period * 100; -- Wait for transmission to complete
--
--        -- Test case 2: Transmit "11001100"
--        --din <= "11001100"; -- Load another data
--        --write_din <= '1'; -- Trigger data transmission
--        --wait for clk_period;
--        --write_din <= '0'; -- Release the trigger
--        --wait for clk_period * 100; -- Wait for transmission to complete
--
--        -- End simulation
--        --wait;
--        wait for 10000*clk_period;
--    end process;
--
--end behavior;

