library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM is
    port (
        clk          : in  std_logic;
        address      : in  std_logic_vector(7 downto 0); 
        data_in      : in  std_logic_vector(7 downto 0); 
        read_enable  : in  std_logic;
        write_enable : in  std_logic;
        data_out     : out std_logic_vector(7 downto 0) 
    );
end entity;

architecture Behavioral of RAM is
  
    type memory_array is array (0 to 255) of std_logic_vector(7 downto 0);
    signal ram : memory_array := (others => (others => '0')); 
    signal temp_data_out : std_logic_vector(7 downto 0) := (others => 'Z'); 
begin

    process(clk)
    begin
        if rising_edge(clk) then
         
            if write_enable = '1' then
                ram(to_integer(unsigned(address))) <= data_in;
            end if;

 
                temp_data_out <= ram(to_integer(unsigned(address)));

        end if;
    end process;

   
    data_out <= temp_data_out when read_enable = '1' else (others => 'Z');

end architecture;