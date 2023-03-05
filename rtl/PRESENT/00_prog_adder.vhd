library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity prog_adder is
        generic (
                DATA_WIDTH : natural
        );
        port (
                input_A : in std_logic_vector(DATA_WIDTH - 1 downto 0);
                input_B : in std_logic_vector(DATA_WIDTH - 1 downto 0);
                mode    : in std_logic;
                out_val : out std_logic_vector(DATA_WIDTH - 1 downto 0)
        );
end entity prog_adder;

architecture behavioral of prog_adder is
        signal a, b, res : unsigned(DATA_WIDTH - 1 downto 0);
begin
        a <= unsigned(input_A);
        b <= unsigned(input_B);

        with mode select
                res <= a + b when '0',
                           a - b when '1',
                           (others => 'Z') when others;
        
        out_val <= std_logic_vector(res);
end architecture;