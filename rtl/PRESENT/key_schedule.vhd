library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.key_length_pack.all;

entity key_schedule is         
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
        
        -- 80-bit key
        KEY_80_BIT : if (KEY_LENGTH = 80) generate
                shifted_vec <= input_key(18 downto 0) & input_key(79 downto 19);

                sbox : entity work.sbox
                        port map(
                                data_in  => shifted_vec(79 downto 76),
                                data_out => output_key(79 downto 76)
                        );

                output_key(19 downto 15) <= shifted_vec(19 downto 15) xor round_counter;
                output_key(75 downto 20) <= shifted_vec(75 downto 20);
                output_key(14 downto 0)  <= shifted_vec(14 downto 0);
        end generate KEY_80_BIT;

        -- 128-bit key
        KEY_128_BIT : if (KEY_LENGTH = 128) generate
                shifted_vec <= input_key(66 downto 0) & input_key(127 downto 67);

                sbox_1 : entity work.sbox
                        port map(
                                data_in => shifted_vec(127 downto 124),
                                data_out => output_key(127 downto 124)
                        );
                
                sbox_2 : entity work.sbox
                        port map(
                                data_in => shifted_vec(123 downto 120),
                                data_out => output_key(123 downto 120)
                        );
                
                output_key(66 downto 62) <= shifted_vec(66 downto 60) xor round_counter;
                output_key(119 downto 67) <= shifted_vec(119 downto 67);
                output_key(61 downto 0) <= shifted_vec(61 downto 0);
        end generate KEY_128_BIT;
end structural;