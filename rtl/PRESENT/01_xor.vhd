library ieee;
use ieee.std_logic_1164.all;

entity xor_n is
        generic (
                DATA_WIDTH : natural
        );
        port (
                a : in std_logic_vector(DATA_WIDTH - 1 downto 0);
                b : in std_logic_vector(DATA_WIDTH - 1 downto 0);
                y : out std_logic_vector(DATA_WIDTH - 1 downto 0)
        );
end xor_n;

architecture structural of xor_n is
begin
        xor_2_gen_loop : for i in 0 to DATA_WIDTH - 1 generate
                xor_2_inst : entity work.xor_2
                        port map(
                                a => a(i),
                                b => b(i),
                                y => y(i)
                        );
        end generate xor_2_gen_loop;
end structural;