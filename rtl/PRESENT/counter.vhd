library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
        generic (
                COUNTER_WIDTH : natural := 5
        );
        port (
                clk, rst, updown        : in std_logic;
                count                   : out std_logic_vector(COUNTER_WIDTH - 1 downto 0)
        );
end counter;

architecture behavioral of counter is
        signal curr_count : unsigned(4 downto 0) := "00000";        
begin
        process (clk, rst, updown) -- asynchronous reset
        variable count_step : integer;
        begin        
                if (rst = '1') then
                        -- count <= (count'low => '1', others => '0'); -- init to decimal 1
                        -- curr_count <= "00001";
                        curr_count <= "00000";
                        if (updown = '0') then
                                count_step := 1;
                        elsif (updown = '1') then
                                count_step := -1;
                        end if;
                elsif rising_edge(clk) then
                        -- if (ena = '1') then
                        -- end if;

                        -- curr_count <= curr_count + 1;

                        -- up/down functionality
                        curr_count <= curr_count + count_step;
                end if;
        end process;

        count <= std_logic_vector(curr_count);
end behavioral;