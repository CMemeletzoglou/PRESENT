library ieee;
use ieee.std_logic_1164.all;

entity tristate_buffer is
        generic (
                NUM_BITS : natural
        );
        port (
                inp  : in std_logic_vector(NUM_BITS - 1 downto 0);
                ena  : in std_logic;
                outp : out std_logic_vector(NUM_BITS - 1 downto 0)
        );
end entity;

architecture tri_state of tristate_buffer is
begin
        outp <= inp when (ena = '1') else (others => 'Z');
end architecture;