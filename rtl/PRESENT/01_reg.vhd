library ieee;
use ieee.std_logic_1164.all;

entity reg is
        generic (
                DATA_WIDTH : natural
        );
        port (
                clk  : in std_logic;
                ena  : in std_logic;
                rst  : in std_logic;
                din  : in std_logic_vector(DATA_WIDTH - 1 downto 0);
                dout : out std_logic_vector(DATA_WIDTH - 1 downto 0)
        );
end reg;

architecture structural of reg is
begin
        dff_gen_loop : for i in 0 to DATA_WIDTH - 1 generate
                dff_inst : entity work.dflip_flop
                        port map(
                                clk => clk,
                                ena => ena,
                                rst => rst,
                                d   => din(i),
                                q   => dout(i)
                        );
        end generate;
end architecture;