library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.key_length_pkg.all;

entity inv_key_schedule is  
        port (
                input_key     : in std_logic_vector(KEY_LENGTH - 1 downto 0);
                round_counter : in std_logic_vector(4 downto 0);
                output_key    : out std_logic_vector(KEY_LENGTH - 1 downto 0)
        );
end inv_key_schedule;

architecture structural of inv_key_schedule is
        signal shifted_vec, tmp : std_logic_vector(KEY_LENGTH - 1 downto 0);
begin
        --      Instead of using ROR on a std_logic_vector, which requires VHDL-2008 support
        --      perform the circular shift/rotation using bit slicing and concatenation
        
        -- Inverse 80-bit key schedule
        KEY_80_BIT : if (KEY_LENGTH = 80) generate
                -- inverse key schedule, so first xor the round_counter
                tmp(19 downto 15) <= input_key(19 downto 15) xor round_counter;

                -- then pass bits 79:76 through the inverse S-Box
                inv_sbox : entity work.inv_sbox
                        port map(
                                data_in  => input_key(79 downto 76),
                                data_out => tmp(79 downto 76)
                        );

                -- emplace the unaffected bits into the resulting vector
                tmp(75 downto 20) <= input_key(75 downto 20);
                tmp(14 downto 0)  <= input_key(14 downto 0);

                -- Circular right shift  ROR 61
                shifted_vec <= tmp(60 downto 0) & tmp(79 downto 61);

                output_key <= shifted_vec;
        end generate KEY_80_BIT;

        -- Inverse 128-bit key schedule
        KEY_128_BIT : if (KEY_LENGTH = 128) generate
                tmp(66 downto 62) <= input_key(66 downto 62) xor round_counter;

                inv_sbox_1 : entity work.inv_sbox
                        port map(
                                data_in => input_key(127 downto 124),
                                data_out => tmp(127 downto 124)
                        );
                
                inv_sbox_2 : entity work.inv_sbox
                        port map(
                                data_in => input_key(123 downto 120),
                                data_out => tmp(123 downto 120)
                        );
                
                tmp(119 downto 67) <= input_key(119 downto 67);
                tmp(61 downto 0) <= input_key(61 downto 0);

                shifted_vec <= tmp(60 downto 0) & tmp(127 downto 61);

                output_key <= shifted_vec;
        end generate KEY_128_BIT;
end structural;