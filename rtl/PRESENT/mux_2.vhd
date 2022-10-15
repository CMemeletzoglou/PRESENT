library ieee;
use ieee.std_logic_1164.all;

entity mux_2 is
        generic (
                DATA_WIDTH : NATURAL
        );
        port (
                input_A, input_B : IN std_logic_vector(DATA_WIDTH-1 downto 0),
                sel : IN std_logic
                mux_2_out : OUT std_logic_vector(DATA_WIDTH-1 downto 0)
        ) ;
end mux_2;

architecture behav of mux_2 is
begin
        process(all) begin
                case sel is
                        when '0' => mux_2_out <= input_A;
                        when '1' => mux_2_out <= input_B;
                        when others => mux_2_out <= (others => 'Z');
                end case;
        end process;
end behav; 