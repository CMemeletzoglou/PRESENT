library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
        generic (
                COUNTER_WIDTH : natural
        );
        port (
                clk    : in std_logic;
                rst    : in std_logic;
                ena    : in std_logic;
                updown : in std_logic;
                count  : out std_logic_vector(COUNTER_WIDTH - 1 downto 0)
        );
end counter;

architecture behavioral of counter is
        signal curr_count : unsigned(COUNTER_WIDTH - 1 downto 0) := (others => '0');
begin
        process (clk, rst, ena, updown) -- asynchronous reset
                variable count_step : integer;
        begin
                if (rst = '1') then
                        -- curr_count <= (others => '0');
                        if (updown = '0') then
                                curr_count <= (others => '0');
                                count_step := 1;
                        elsif (updown = '1') then
                                curr_count <= (others => '1');
                                count_step := -1;
                        end if;
                elsif (rst = '0') then
                        if rising_edge(clk) then
                                if (ena = '1') then
                                        -- up/down functionality
                                        curr_count <= curr_count + count_step;
                                end if;
                        end if;
                end if;
        end process;

        count <= std_logic_vector(curr_count);
end behavioral;