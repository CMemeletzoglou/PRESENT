library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.key_length_pack.all;

-- double port memory
entity key_mem is
        port (
                clk        : in std_logic;

                -- port A
                addr_a     : in std_logic_vector(4 downto 0);
                data_in_a  : in std_logic_vector(63 downto 0);
                wr_en_a    : in std_logic;
                data_out_a : out std_logic_vector(63 downto 0);

                -- port B
                addr_b     : in std_logic_vector(4 downto 0);
                data_in_b  : in std_logic_vector(63 downto 0);
                wr_en_b    : in std_logic;
                data_out_b : out std_logic_vector(63 downto 0)
        );
end entity key_mem;

architecture behavioral of key_mem is
        subtype ROUND_KEY_T is std_logic_vector(63 downto 0);

        type ROUND_KEY_MEM is array (0 to 31) of ROUND_KEY_T;

        signal ram_block : ROUND_KEY_MEM := (others => (others => '0'));
begin
        port_A : process (clk)
        begin
                if rising_edge(clk) then
                        if (wr_en_a = '1') then -- Port A write operation
                                ram_block(to_integer(unsigned(addr_a))) <= data_in_a;
                        elsif (wr_en_a = '0') then -- Port A read operation
                                data_out_a <= ram_block(to_integer(unsigned(addr_a)));
                        end if;

                        if (wr_en_b = '1') then -- Port B write operation
                                ram_block(to_integer(unsigned(addr_b))) <= data_in_b;
                        elsif (wr_en_b = '0') then
                                data_out_b <= ram_block(to_integer(unsigned(addr_b)));
                        end if;
                end if;
        end process  port_A;

--        -- port B
--        port_B : process (clk)
--        begin
--                if rising_edge(clk) then
--                        if (wr_en_b = '1') then --write operation
--                                ram_block(to_integer(unsigned(addr_b))) <= data_in_b;
--                        elsif (wr_en_b = '0') then -- read operation
--                                data_out_b <= ram_block(to_integer(unsigned(addr_b)));
--                        end if;
--                end if;
--        end process port_B;        
end architecture;