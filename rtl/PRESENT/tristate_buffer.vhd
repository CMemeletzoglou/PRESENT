LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY tristate_buffer IS
        generic (
                NUM_BITS: natural
        );
        PORT(
                inp: IN std_logic_vector(NUM_BITS-1 DOWNTO 0);
                ena: IN std_logic;
                outp: OUT std_logic_vector(NUM_BITS-1 DOWNTO 0)
        );
END ENTITY;

ARCHITECTURE tri_state of tristate_buffer IS
BEGIN
        outp <= inp WHEN (ena = '1') ELSE (others => 'Z');
END ARCHITECTURE;

