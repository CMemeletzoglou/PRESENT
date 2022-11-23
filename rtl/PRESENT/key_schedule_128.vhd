library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity key_schedule_128 is
        port (
                input_key     : in std_logic_vector(127 downto 0);
                round_counter : in std_logic_vector(4 downto 0);
                ena           : in std_logic;
                output_key    : out std_logic_vector(127 downto 0)
        );
end entity;

architecture structural of key_schedule_128 is
        signal shifted_vec : std_logic_vector(127 downto 0);

        -- new
        signal tmp : std_logic_vector(127 downto 0);
begin
        shifted_vec <= input_key(66 downto 0) & input_key(127 downto 67);

        sbox_1 : entity work.sbox
                port map(
                        data_in  => shifted_vec(127 downto 124),
                        data_out => tmp(127 downto 124)
                );

        sbox_2 : entity work.sbox
                port map(
                        data_in  => shifted_vec(123 downto 120),
                        data_out => tmp(123 downto 120)
                );

        tmp(66 downto 62)  <= shifted_vec(66 downto 62) xor round_counter;
        tmp(119 downto 67) <= shifted_vec(119 downto 67);
        tmp(61 downto 0)   <= shifted_vec(61 downto 0);

        -- new
        output_key <= tmp when (ena = '1') else (others => 'Z');        
end architecture;