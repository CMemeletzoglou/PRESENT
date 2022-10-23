library ieee;
use ieee.std_logic_1164.all;

entity reg is
        generic (
                DATA_WIDTH : natural
        );
        port (
                clk, rst : in std_logic;
                ena      : in std_logic;
                din      : in std_logic_vector(DATA_WIDTH - 1 downto 0);
                dout     : out std_logic_vector(DATA_WIDTH - 1 downto 0)
        );
end reg;

architecture rtl of reg is
begin
        process (clk, rst, ena) -- asynchronous active high reset
        begin
                if (rst = '1') then
                        dout <= (others => '0');
                elsif rising_edge(clk) then
                        if (ena = '1') then
                                dout <= din;
                        end if;
                end if;
        end process;
end rtl;