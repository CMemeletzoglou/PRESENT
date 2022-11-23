library ieee;
use ieee.std_logic_1164.all;

entity key_schedule_80 is
        port (
                input_key     : in std_logic_vector(79 downto 0);
                round_counter : in std_logic_vector(4 downto 0);
                ena           : in std_logic;
                output_key    : out std_logic_vector(79 downto 0)

        );
end entity key_schedule_80;

architecture structural of key_schedule_80 is
        signal shifted_vec : std_logic_vector(79 downto 0);

        -- new 
        signal tmp : std_logic_vector(79 downto 0);
begin
        shifted_vec <= input_key(18 downto 0) & input_key(79 downto 19);

        sbox : entity work.sbox
                port map(
                        data_in  => shifted_vec(79 downto 76),
                        data_out => tmp(79 downto 76)
                );

        tmp(19 downto 15) <= shifted_vec(19 downto 15) xor round_counter;
        tmp(75 downto 20) <= shifted_vec(75 downto 20);
        tmp(14 downto 0)  <= shifted_vec(14 downto 0);

        -- new
        tri_buf : entity work.tristate_buffer
                generic map(
                        NUM_BITS => 80
                )
                port map(
                        inp => tmp,
                        ena => ena,
                        outp => output_key
                );
end architecture;