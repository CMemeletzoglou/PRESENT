library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.state_pkg.all;

entity present_tb is
end;

architecture bench of present_tb is
        component present
                  port (
                           clk : in std_logic;
                           rst : in std_logic;
                           ena : in std_logic;
                           mode_sel : in std_logic_vector(1 downto 0);
                           key : in std_logic_vector(127 downto 0);
                           data_in : in std_logic_vector(63 downto 0);
                           data_out : out std_logic_vector(63 downto 0);
                           ready : out std_logic;
                           curr_state : out STATE
                  );
         end component;

         -- Clock period
         constant clk_period : time := 5 ns;
         -- Generics

         -- Ports
         signal clk : std_logic;
         signal rst : std_logic;
         signal ena : std_logic;
         signal mode_sel : std_logic_vector(1 downto 0);
         signal key : std_logic_vector(127 downto 0);
         signal data_in : std_logic_vector(63 downto 0);
         signal data_out : std_logic_vector(63 downto 0);
         signal ready : std_logic;
         signal curr_state : STATE;

begin

        present_inst : present
        port map(
                clk => clk,
                rst => rst,
                ena => ena,
                mode_sel => mode_sel,
                key => key,
                data_in => data_in,
                data_out => data_out,
                ready => ready,
                curr_state => curr_state
        );

        clk_process : process
        begin
                clk <= '0';
                wait for clk_period/2;
                clk <= '1';
                wait for clk_period/2;
        end process clk_process;

        stimuli_proc : process begin
                rst <= '1', '0' after clk_period;
                ena <= '0', '1' after clk_period;

                mode_sel <= b"10"; -- 128-bit encryption
                data_in <= x"FFFFFFFFFFFFFFFF";
                key <= x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

                wait for 65 * clk_period;

                data_in <= x"0000000000000000";

                wait for 2*clk_period;

                assert data_out = x"628d9fbd4218e5b4"
                        report "Encryption failed for input data 0xFFFFFFFFFFFFFFFF @ " & time'image(now)
                        severity failure;

                wait for 32 * clk_period;
                
                mode_sel <= b"11"; -- 128-bit decryption
                
                data_in <= x"628d9fbd4218e5b4";
                
                wait for clk_period;
                assert data_out = x"13238c710272a5d8"
                        report "Encryption failed for input data 0x0000000000000000 !!"
                        severity failure;
                
                wait for 32 * clk_period;
                
                data_in <= x"13238c710272a5d8";


                wait;
        end process;
end;