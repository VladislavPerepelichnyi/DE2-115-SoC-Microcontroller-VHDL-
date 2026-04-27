library ieee;
use ieee.std_logic_1164.all;

entity Stack is
    port (
        data_in   : in  std_logic_vector(7 downto 0); -- Input data for push
        push      : in  std_logic;                   -- Push signal
        pop       : in  std_logic;                   -- Pop signal
        clk       : in  std_logic;                   -- Clock
        rst       : in  std_logic;                   -- Reset signal
        en        : in  std_logic;                   -- Enable signal for output
        data_out  : out std_logic_vector(7 downto 0) -- Tri-state output
    );
end Stack;

architecture Behavioral of Stack is
    type memory_array is array (0 to 15) of std_logic_vector(7 downto 0); -- 16 registers
    signal stack_mem : memory_array := (others => (others => '0'));      -- Stack memory
    signal sp : integer range 0 to 15 := 0;                              -- Stack pointer
    signal temp_out : std_logic_vector(7 downto 0);                      -- Internal output signal
begin
    -- Stack operations: push, pop, and reset
    process(clk, rst)
    begin
        if rst = '1' then
            -- Reset stack memory and pointer
            stack_mem <= (others => (others => '0'));
            sp <= 0;
            temp_out <= (others => '0');
        elsif rising_edge(clk) then
            if push = '1' and sp < 15 then
                -- Push data onto the stack
                stack_mem(sp) <= data_in;
                sp <= sp + 1;
            elsif pop = '1' and sp > 0 then
                -- Pop data from the stack
                sp <= sp - 1;
            end if;

            -- Update the internal output signal
            if sp > 0 then
                temp_out <= stack_mem(sp - 1); -- Show the value at the top
            else
                temp_out <= (others => '0');  -- Stack is empty
            end if;
        end if;
    end process;

    -- Tri-state output logic
    data_out <= temp_out when en = '1' else (others => 'Z');

end Behavioral;

