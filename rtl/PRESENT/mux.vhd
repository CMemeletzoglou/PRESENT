library ieee;
use ieee.std_logic_1164.all;

entity mux is
        generic(
                DATA_WIDTH : NATURAL
        );
        port (
                input_A, input_B : IN std_logic_vector(DATA_WIDTH-1 downto 0);
                sel : IN std_logic;
                mux_out : OUT std_logic_vector(DATA_WIDTH-1 downto 0)
        );
end mux;

architecture structural of mux is
begin
        mux_2_gen_loop: for i in 0 to DATA_WIDTH-1 generate
                mux_2_inst : entity work.mux_2
                        port map(
                                input_A => input_A(i),
                                input_B => input_B(i),
                                sel => sel,
                                mux_2_out => mux_out(i)
                        );
        end generate mux_2_gen_loop; 
end structural ; 