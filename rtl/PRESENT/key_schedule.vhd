library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity key_schedule is
        generic (
                KEY_LENGTH : natural := 80
        );
        port (
                input_key     : in std_logic_vector(KEY_LENGTH - 1 downto 0);
                round_counter : in std_logic_vector(4 downto 0);
                output_key    : out std_logic_vector(KEY_LENGTH - 1 downto 0)
        );
end key_schedule;

architecture structural of key_schedule is
        signal shifted_vec : std_logic_vector(KEY_LENGTH - 1 downto 0);
begin
        --      shifted_vec <= input_key ROL 61;
        --      Instead of using ROL on a std_logic_vector, which requires VHDL-2008 support
        --      perform the circular shift/rotation using bit slicing and concatenation

        shifted_vec <= input_key(18 downto 0) & input_key(79 downto 19);

        sbox : entity work.sbox
                port map(
                        data_in  => shifted_vec(79 downto 76),
                        data_out => output_key(79 downto 76)
                );

        output_key(19 downto 15) <= shifted_vec(19 downto 15) xor round_counter;
        output_key(75 downto 20) <= shifted_vec(75 downto 20);
        output_key(14 downto 0)  <= shifted_vec(14 downto 0);
end structural;