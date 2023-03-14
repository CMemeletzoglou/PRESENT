library ieee;
use ieee.std_logic_1164.all;

-- D Flip-Flop with active high enable and reset signals.
entity dflip_flop is
        port (
                clk : in std_logic;
                ena : in std_logic;
                rst : in std_logic;
                d   : in std_logic;
                q   : out std_logic
        );
end entity dflip_flop;

architecture rtl of dflip_flop is
begin
        process (clk, rst)
        begin
                if (rst = '1') then -- asynchronous reset
                        q <= '0';
                elsif (rst = '0') then
                        if rising_edge(clk) then
                                if (ena = '1') then
                                        q <= d;
                                end if;
                        end if;
                end if;
        end process;
end architecture;