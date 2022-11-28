library ieee;
use ieee.std_logic_1164.all;

entity present is
        port (
                clk      : in std_logic;
                rst      : in std_logic;
                ena      : in std_logic;
                key_ena  : in std_logic;
                mode_sel : in std_logic_vector(1 downto 0);
                key      : in std_logic_vector(127 downto 0);
                data_in  : in std_logic_vector(63 downto 0);
                data_out : out std_logic_vector(63 downto 0);
                ready    : out std_logic
        );
end entity present;

architecture rtl of present is

begin

end architecture;