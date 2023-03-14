library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity present_tb is
end;

architecture bench of present_tb is

        component present
                port (
                        clk      : in std_logic;
                        rst      : in std_logic;
                        ena      : in std_logic;
                        key_ena  : in std_logic;
                        mode_sel : in std_logic_vector(1 downto 0);
                        key      : in std_logic_vector(127 downto 0);
                        data_in  : in std_logic_vector(63 downto 0);
                        data_out : out std_logic_vector(63 downto 0);
                        ready    : out std_logic
                );
        end component;

        -- Clock period
        constant clk_period : time := 2 ns;
        -- Generics

        -- Ports
        signal clk      : std_logic;
        signal rst      : std_logic;
        signal ena      : std_logic;
        signal key_ena  : std_logic;
        signal mode_sel : std_logic_vector(1 downto 0);
        signal key      : std_logic_vector(127 downto 0);
        signal data_in  : std_logic_vector(63 downto 0);
        signal data_out : std_logic_vector(63 downto 0);
        signal ready    : std_logic;

begin

        present_inst : present
        port map(
                clk      => clk,
                rst      => rst,
                ena      => ena,
                key_ena  => key_ena,
                mode_sel => mode_sel,
                key      => key,
                data_in  => data_in,
                data_out => data_out,
                ready    => ready
        );

        clk_process : process
        begin
                clk <= '1';
                wait for clk_period/2;
                clk <= '0';
                wait for clk_period/2;
        end process clk_process;

        rst <= '1', '0' after clk_period;

        stimuli_proc : process begin
                wait until rst <= '0';
                
                ena <= '1';
                key_ena <= '1';
                mode_sel <= b"10"; -- encryption
                key <= x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";
                data_in <= x"FFFFFFFFFFFFFFFF";

                -- wait for keygen to finish, that is 32 cycles
                wait for 32 * clk_period;

                -- wait for decryption to finish, that is 34 cycles -> we then are in DONE
                -- but we need to wait for one more clock cycle.
                wait for 34 * clk_period;
                wait for clk_period/2;

                mode_sel <= b"11";
                data_in <= x"628d9fbd4218e5b4";

                wait; -- halt the simulation
        end process stimuli_proc;
end;