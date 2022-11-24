library ieee;
use ieee.std_logic_1164.all;

entity inv_pbox is
        port (
                data_in  : in std_logic_vector(63 downto 0);
                data_out : out std_logic_vector(63 downto 0)
        );
end entity inv_pbox;

architecture behavioral of inv_pbox is
begin
        inv_permutate_loop : for i in 0 to 62 generate
                data_out((i * 4) mod 63) <= data_in(i);
        end generate inv_permutate_loop;
        data_out(63) <= data_in(63);
end architecture;