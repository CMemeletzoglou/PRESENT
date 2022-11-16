library ieee;
use ieee.std_logic_1164.all;

entity inv_sbox_layer is
        port (
                inv_sbox_layer_in  : in std_logic_vector(63 downto 0);
                inv_sbox_layer_out : out std_logic_vector(63 downto 0)
        );
end inv_sbox_layer;

architecture structural of inv_sbox_layer is
begin
        sbox_gen : for i in 0 to 15 generate
                inv_sbox : entity work.inv_sbox
                        port map(
                                data_in  => inv_sbox_layer_in((4 * i + 3) downto 4 * i),
                                data_out => inv_sbox_layer_out((4 * i + 3) downto 4 * i)
                        );
        end generate sbox_gen;
end structural;