library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.key_length_pack.all;

entity key_mem is
        port (
                addr     : in std_logic_vector(4 downto 0);
                wr_en    : in std_logic;
                data_in  : in std_logic_vector(KEY_LENGTH - 1 downto 0);
                clk      : in std_logic;
                data_out : out std_logic_vector(KEY_LENGTH - 1 downto 0)
        );
end entity key_mem;

architecture rtl of key_mem is
        type ROUND_KEY_T is array(63 downto 0) of std_logic;

        type ROUND_KEY_MEM is array (0 to 31) of ROUND_KEY_T;

        signal ram_block : ROUND_KEY_MEM;
begin
        process (clk)
        begin
                if rising_edge(clk) then
                        if(wr_en = '1') then --write operation
                                ram_block(to_integer(unsigned(addr))) <= data_in;
                        elsif(wr_en = '0') then -- read operation
                                data_out <= ram_block(to_integer(unsigned(addr)));
                        end if;
                end if;
        end process;
end architecture;