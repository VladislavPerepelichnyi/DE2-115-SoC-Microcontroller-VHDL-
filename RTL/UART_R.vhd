
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;



entity shift_register_r is port(
	din : in std_logic;
	rst : in std_logic;
	clk : in std_logic;
	d_out : out std_logic_vector (7 downto 0);
	ena_shift : in std_logic; -- Enable shift register
	ena_load_out : in std_logic); -- Enable data load
	
end shift_register_r;

architecture a of shift_register_r is
signal s_reg :  std_logic_vector(7 downto 0);

begin
	process (clk, rst)
    begin	
	if rst = '1' then
		s_reg <= "00000000";
	elsif rising_edge(clk) then
		
		if ena_shift = '1' then
			s_reg <= din & s_reg(7 downto 1);
		end if;
		
		if ena_load_out = '1' then
			d_out <= s_reg;
		end if;
		
	end if;
	end process;
end;




library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all; -- For integer operations

entity tcount_r is
    port (
        clk     : in  std_logic;  -- System clock
        rst     : in  std_logic;  -- Active-high reset
        te      : in  std_logic;  -- Timer enable
        t1      : out std_logic;   -- Timer terminal count signal
		  t2      : out std_logic;   -- Timer terminal count signal
		  t3      : out std_logic
    );
end tcount_r;

architecture a of tcount_r is
	 constant clk_freq : integer := 50000000;
	 constant baud : integer := 115200;
	 constant t1_count : integer := clk_freq/baud;
	 constant t2_count : integer := t1_count/2;
	 constant t3_count : integer := t1_count/16;
    -- -- Define the clock divider constant
    -- constant DIVIDER : integer := 5208; -- Example: for 9600 baud with 50 MHz clock
    signal count     : integer range 0 to t1_count-1 := 0; -- Counter signal
    signal t1_s      : std_logic := '0';
  	 signal t2_s      : std_logic := '0';
	 signal t3_s      : std_logic := '0';	-- Internal t1 signal
begin
    -- Output assignment
    t1 <= t1_s;
	 t2 <= t2_s;
	 t3 <= t3_s;

    -- Timer process
    process (clk, rst)
    begin
        if rst = '1' then
            t1_s <= '0';
				t2_s <= '0';
				t3_s <= '0';
				
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
					 
					 if count = t2_count then
						  t2_s <= '1';
					 else
						  t2_s <= '0';
					 end if;
					 
					 if (count > t2_count) and ((count - t2_count) mod t3_count = 0) then
						  t3_s <= '1';
					 else
						  t3_s <= '0';
					 end if;
					 
            else
                -- Timer is disabled
                count <= 0;  
                t1_s <= '0';
            end if;
        end if;
    end process;
end;




library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity controller_r is
    port (
        rst       		   : in  std_logic; -- Reset signal (active low)
        clk       		   : in  std_logic; -- Clock signal
        t1   				   : in  std_logic; -- Timer tick signal
		  t2   				   : in  std_logic;
		  t3   				   : in  std_logic;
        rx         		   : in  std_logic; -- Write request signal
        ena_shift  		   : out std_logic; -- Enable shift register
        ena_dout    		   : out std_logic; -- Enable data load
        te          		   : out std_logic; -- Enable timer
        dout_new  		   : out std_logic; -- Set output signal
        
		  rx_ready           : out std_logic;  -- Enable output signal
		  bit_for_transfer   : out std_logic;
		  rx_sync            : out  std_logic); -- Write request signal
		  
end controller_r;

architecture a of controller_r is

    -- State enumeration
    type sm is (idle, receive_start, receive_data, shift, sample, test_eoc, output);
    signal current_state, next_state : sm;

    -- Output signal defaults
    signal ena_shift_s  : std_logic := '0';
    signal ena_dout_s   : std_logic := '0';
    signal te_s         : std_logic := '0';
    signal dout_new_s : std_logic := '0';
    signal rx_ready_s : std_logic := '0';
	 signal rx_sync_s : std_logic := '1';
	 
	 signal dcount : integer;
	 signal t3_counter : integer := 5; -- might need defaulting
	 signal sample_counter : integer := 0;
	 signal bit_for_transfer_s : std_logic := '0';

begin
    
    ena_shift <= ena_shift_s;
    ena_dout <= ena_dout_s;
    te <= te_s;
    dout_new <= dout_new_s;
    rx_ready <= rx_ready_s;
	 bit_for_transfer <= bit_for_transfer_s;
	 rx_sync <= rx_sync_s;

	 
	 
	 
	 process(clk) -- for syncing
    begin
        if rising_edge(clk) then
            rx_sync_s <= rx;
        end if;
    end process;
	 
	 

    -- State machine process
    process (clk, rst)
    begin
        if rst = '1' then
			-- Default signal values
			
			ena_shift_s  <= '0';
			ena_dout_s   <= '0';
			te_s         <= '0';
			dout_new_s   <= '0';
			rx_ready_s   <= '0';
			dcount <= 0;
			
         current_state <= idle; -- Reset to idle state
			
        elsif rising_edge(clk) then
        
		  
        case current_state is
		  
            when idle =>
				
					ena_shift_s  <= '0';
					ena_dout_s   <= '0';
					te_s         <= '0';
					dout_new_s   <= '0';
					rx_ready_s   <= '1';
					dcount       <= 0;
					t3_counter   <= 5;
					sample_counter <= 0;
					
               if rx_sync_s = '1' then
                  next_state <= idle;
               else
                  next_state <= receive_start;
                end if;

            -- Send start bit state
            when receive_start =>
				
					 ena_shift_s  <= '0';
				 	 ena_dout_s   <= '0';
				 	 te_s         <= '1';
					 dout_new_s   <= '0';
					 rx_ready_s   <= '0';
					 
                if t1 = '1' then
                    next_state <= receive_data;
                else
                    next_state <= receive_start;
                end if;


            -- Send data bits state
            when receive_data =>
					 
					 ena_shift_s  <= '0';
				  	 ena_dout_s   <= '0';
					 te_s         <= '1';
					 dout_new_s   <= '0';
					 rx_ready_s   <= '0';

                if t1 = '1' then
                    next_state <= shift;
                else if t2 = '1' then
						  next_state <= sample;
					 else
                    next_state <= receive_data;
					 end if;
                end if;
					 
				when sample =>
					 
					 ena_shift_s  <= '0';
				  	 ena_dout_s   <= '0';
					 te_s         <= '1';
					 dout_new_s   <= '0';
					 rx_ready_s   <= '0';

                if (t3 = '1') and (t3_counter > 0) then
						  t3_counter <= (t3_counter - 1);
                    next_state <= sample;
						  if rx_sync_s = '1' then
						  sample_counter <= sample_counter + 1;
						  end if;
                elsif t3 = '1' and (t3_counter = 0) then
						  if sample_counter > 2 then
								bit_for_transfer_s <= '1';
						  else
								bit_for_transfer_s <= '0';
						  end if;
						  next_state <= receive_data;
						  t3_counter     <= 5;
					     sample_counter <= 0;
					 end if;

            -- Shift state
            when shift =>
					 
					 ena_shift_s  <= '1';
				  	 ena_dout_s   <= '0';
					 te_s         <= '1';
					 dout_new_s   <= '0';
					 rx_ready_s   <= '0';
					 
					 dcount <= dcount + 1;
                next_state <= test_eoc;


            -- Test end of count state
            when test_eoc =>
				        
					 ena_shift_s  <= '0';
					 ena_dout_s   <= '0';
			    	 te_s         <= '1';
					 dout_new_s   <= '0';
					 rx_ready_s   <= '0';
						  
                if dcount = 8 then
                    next_state <= output; -- Proceed to send the stop bit
                else
                    next_state <= receive_data; -- Continue sending data bits
                end if;

            -- Send stop bit state
            when output =>
				
					 ena_shift_s  <= '0';
					 ena_dout_s   <= '1';
			    	 te_s         <= '1';
					 dout_new_s   <= '1';
					 rx_ready_s   <= '0';
					 

                next_state <= idle; -- Return to idle state


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

entity UART_R is
    port (
        clk        : in  std_logic;  -- System clock
        rst        : in  std_logic;  -- Active-high reset
        rx         : in  std_logic;  -- Asynchronous UART RX line
        
        data_out   : out std_logic_vector(7 downto 0); -- Received byte
        dout_new   : out std_logic;                     -- Pulses when a byte is ready
		  rx_ready   : out std_logic
    );
end UART_R;

architecture a of UART_R is

    ----------------------------------------------------------------------------
    -- Internal signals that wire sub-entities together
    ----------------------------------------------------------------------------
    signal t1_s, t2_s, t3_s               : std_logic := '0';
    signal ena_shift_s, ena_dout_s, te_s  : std_logic := '0';
    signal rx_ready_s                     : std_logic := '0';
    signal bit_for_transfer_s             : std_logic := '0';
	 signal rx_sync_s                      : std_logic;
	 
component shift_register_r is port(
	din : in std_logic;
	rst : in std_logic;
	clk : in std_logic;
	d_out : out std_logic_vector (7 downto 0);
	ena_shift : in std_logic; -- Enable shift register
	ena_load_out : in std_logic); -- Enable data load
	
end component;
	 
	 
	 
component tcount_r is
    port (
        clk     : in  std_logic;  -- System clock
        rst     : in  std_logic;  -- Active-high reset
        te      : in  std_logic;  -- Timer enable
        t1      : out std_logic;   -- Timer terminal count signal
		  t2      : out std_logic;   -- Timer terminal count signal
		  t3      : out std_logic
    );
end component;

component controller_r is
    port (
        rst       		   : in  std_logic; -- Reset signal (active low)
        clk       		   : in  std_logic; -- Clock signal
        t1   				   : in  std_logic; -- Timer tick signal
		  t2   				   : in  std_logic;
		  t3   				   : in  std_logic;
        rx         		   : in  std_logic; -- Write request signal
        ena_shift  		   : out std_logic; -- Enable shift register
        ena_dout    		   : out std_logic; -- Enable data load
        te          		   : out std_logic; -- Enable timer
        dout_new  		   : out std_logic; -- Set output signal
        
		  rx_ready           : out std_logic;  -- Enable output signal
		  bit_for_transfer   : out std_logic;
		  rx_sync            : out  std_logic); -- Write request signal
		  
end component;

begin


	 rx_ready <= rx_ready_s;

    ----------------------------------------------------------------------------
    -- 1) Direct instantiation of tcount_r
    ----------------------------------------------------------------------------
    tcount_inst : tcount_r
        port map (
            clk => clk,
            rst => rst,
            te  => te_s,
            t1  => t1_s,
            t2  => t2_s,
            t3  => t3_s
        );

    ----------------------------------------------------------------------------
    -- 2) Direct instantiation of controller_r
    ----------------------------------------------------------------------------
    f : controller_r
        port map (
            rst              => rst,
            clk              => clk,
            t1               => t1_s,
            t2               => t2_s,
            t3               => t3_s,
            rx               => rx,
            ena_shift        => ena_shift_s,
            ena_dout         => ena_dout_s,
            te               => te_s,
            dout_new         => dout_new,
            rx_ready         => rx_ready_s,
            bit_for_transfer => bit_for_transfer_s,
				rx_sync          => rx_sync_s
        );

    ----------------------------------------------------------------------------
    -- 3) Direct instantiation of shift_register_r
    ----------------------------------------------------------------------------
    shift_reg_inst : shift_register_r
        port map (
            din          => bit_for_transfer_s,
            rst          => rst,
            clk          => clk,
            d_out        => data_out,
            ena_shift    => ena_shift_s,
            ena_load_out => ena_dout_s
        );
end architecture a;








--library ieee;
--use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;
--
--entity tb_UART_R is
--end entity tb_UART_R;
--
--architecture behavior of tb_UART_R is
--
--    ----------------------------------------------------------------------------
--    -- 1) Testbench Constants
--    ----------------------------------------------------------------------------
--    constant CLK_PERIOD  : time := 20 ns;   -- 50 MHz clock
--    -- For 115,200 baud => bit ~8.68 us. But let's approximate or shorten:
--    constant BIT_PERIOD  : time := 8.68 us;   -- close to real timing or modify as needed
--
--    ----------------------------------------------------------------------------
--    -- 2) Signals for DUT
--    ----------------------------------------------------------------------------
--    signal clk       : std_logic := '0';
--    signal rst       : std_logic := '0';
--    signal rx        : std_logic := '1';  -- idle high
--    signal data_out  : std_logic_vector(7 downto 0);
--    signal dout_new  : std_logic;
--
--begin
--
--    ----------------------------------------------------------------------------
--    -- 3) Clock Generation
--    ----------------------------------------------------------------------------
--    clk_process: process
--    begin
--        clk <= '0';
--        wait for clk_period / 2;
--        clk <= '1';
--        wait for clk_period / 2;
--    end process;
--
--    ----------------------------------------------------------------------------
--    -- 4) Instantiate the DUT (UART_R)
--    ----------------------------------------------------------------------------
--    DUT : entity work.UART_R
--        port map (
--            clk      => clk,
--            rst      => rst,
--            rx       => rx,
--            data_out => data_out,
--            dout_new => dout_new
--        );
--
--    ----------------------------------------------------------------------------
--    -- 5) Stimulus Process
--    ----------------------------------------------------------------------------
--    stim_process : process
--        -- We'll create a small procedure to transmit a byte on 'rx'
--        
--    begin
--        ------------------------------------------------------------------------
--        -- 5.1) Reset pulse
--        ------------------------------------------------------------------------
--            rst <= '1';
--            wait for clk_period;
--            rst <= '0';
--            --------------------------------------------------------------------
--            -- Send start bit (0)
--            wait for clk_period*10;
--            rx <= '0';
--            wait for BIT_PERIOD;
--            --data bits
--            rx <= '1';
--            wait for BIT_PERIOD;
--            rx <= '1';
--            wait for BIT_PERIOD;
--            rx <= '0';
--            wait for BIT_PERIOD;
--            rx <= '0';
--            wait for BIT_PERIOD;
--            rx <= '1';
--            wait for BIT_PERIOD;
--            rx <= '1';
--            wait for BIT_PERIOD;
--            rx <= '0';
--            wait for BIT_PERIOD;
--            rx <= '0';
--            wait for BIT_PERIOD;
--            --stop bit
--            rx <= '1';
--            wait for BIT_PERIOD;
--            
--            --start bit
--            rx <= '0';
--            wait for BIT_PERIOD;
--            --data bits
--            rx <= '1';
--            wait for BIT_PERIOD;
--            rx <= '0';
--            wait for BIT_PERIOD;
--            rx <= '1';
--            wait for BIT_PERIOD;
--            rx <= '0';
--            wait for BIT_PERIOD;
--            rx <= '1';
--            wait for BIT_PERIOD;
--            rx <= '0';
--            wait for BIT_PERIOD;
--            rx <= '1';
--            wait for BIT_PERIOD;
--            rx <= '0';
--            wait for BIT_PERIOD;
--            --stop bit
--            rx <= '1';
--            wait for BIT_PERIOD;
--
--        wait for 1 ms;
--    end process;
--
--end architecture behavior;


