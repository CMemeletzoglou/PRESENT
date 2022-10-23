library ieee;
use ieee.std_logic_1164.all;

entity sbox_layer is
        port (
                sbox_layer_in  : in std_logic_vector(63 downto 0);
                sbox_layer_out : out std_logic_vector(63 downto 0)
        );
end sbox_layer;

architecture structural of sbox_layer is
begin
        sbox_gen : for i in 0 to 15 generate
                sbox : entity work.sbox
                        port map(
                                data_in  => sbox_layer_in((4 * i + 3) downto 4 * i),
                                data_out => sbox_layer_out((4 * i + 3) downto 4 * i)
                        );
        end generate sbox_gen;
end structural;