library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
        generic (
                COUNTER_WIDTH : natural := 5
        );
        port (
                clk     : in std_logic;
                cnt_ena : in std_logic;
                rst     : in std_logic;                
                count   : out std_logic_vector(COUNTER_WIDTH - 1 downto 0)
        );
end counter;

architecture behavioral of counter is        
        signal curr_count : unsigned(COUNTER_WIDTH - 1 downto 0);
begin                  
        process (clk, rst)             
        begin
                if (rst = '1') then     -- asynchronous reset    
                        curr_count <= (others => '0');                        
                elsif (rst = '0') then
                        if rising_edge(clk) then
                                if (cnt_ena = '1') then                                        
                                        curr_count <= curr_count + 1;
                                end if;
                        end if;
                end if;
        end process;

        count <= std_logic_vector(curr_count);
end behavioral;