library ieee;
use ieee.std_logic_1164.all;

entity reg is
        generic(
                DATA_WIDTH : NATURAL
        );
        port (
                clk, rst : IN std_logic;
                din : IN std_logic_vector(DATA_WIDTH-1 downto 0);
                q : OUT std_logic_vector(DATA_WIDTH-1 downto 0)
        ) ;
end reg;

architecture rtl of reg is
begin
        process(clk, rst) -- asynchronous active high reset
        begin
                if rst then
                        q <= (others => '0');
                elsif rising_edge(clk) then
                        q <= din;
                end if;
        end process;
end rtl ; 