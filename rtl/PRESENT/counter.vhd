library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
        generic(
                COUNTER_WIDTH : NATURAL := 5
        );
        port (
                clk, rst, ena : IN std_logic;
                count : OUT std_logic_vector(COUNTER_WIDTH-1 downto 0)
        ) ;
end counter;

architecture behavioral of counter is
begin
        process (clk, rst) -- asynchronous reset
        begin
                if rst then
                        count <= (count'low => '1', others => '0'); -- init to decimal 1
                elsif rising_edge(clk) then
                        if ena then
                                count <= std_logic_vector(unsigned(count) + 1);
                        end if;
                end if;
        end process ;
end behavioral ;