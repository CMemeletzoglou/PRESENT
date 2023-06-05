library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all; --needed for uniform PRNG

entity present_Trojan2_tb is
end;

architecture bench of present_Trojan2_tb is

        component present_Trojan2
                port (
                        clk      : in std_logic;
                        rst      : in std_logic;
                        ena      : in std_logic;
                        mode_sel : in std_logic_vector(1 downto 0);
                        key      : in std_logic_vector(127 downto 0);
                        data_in  : in std_logic_vector(63 downto 0);
                        data_out : out std_logic_vector(63 downto 0);
                        ready    : out std_logic
                );
        end component;

        -- Clock period
        constant clk_period : time := 5 ns;
        -- Generics

        -- Ports
        signal clk      : std_logic;
        signal rst      : std_logic;
        signal ena      : std_logic;
        signal mode_sel : std_logic_vector(1 downto 0);
        signal key      : std_logic_vector(127 downto 0);
        signal data_in  : std_logic_vector(63 downto 0);
        signal data_out : std_logic_vector(63 downto 0);
        signal ready    : std_logic;
begin
        present_Trojan2_inst : present_Trojan2
        port map(
                clk      => clk,
                rst      => rst,
                ena      => ena,
                mode_sel => mode_sel,
                key      => key,
                data_in  => data_in,
                data_out => data_out,
                ready    => ready
        );

        clk_process : process
        begin
                clk <= '0';
                wait for clk_period/2;
                clk <= '1';
                wait for clk_period/2;
        end process clk_process;

        stimuli_proc : process is
                variable seed1 : integer := 999;
                variable seed2 : integer := 123;

                impure function rand_slv(len : integer) return std_logic_vector is
                        variable r : real;
                        variable slv : std_logic_vector(len - 1 downto 0);
                begin
                        for i in slv'range loop
                                uniform(seed1, seed2, r);
                                slv(i) := '1' when r > 0.5 else '0';
                        end loop;
                        
                        return slv;
                end function;
        begin
                -- rst <= '1', '0' after clk_period;
                -- ena <= '0', '1' after clk_period;

                mode_sel <= b"10";
                
                rand_key_loop : for k in 0 to 3 loop
                        rst <= '1', '0' after clk_period;
                        ena <= '0', '1' after clk_period;
                        key <= rand_slv(128);

                        rand_slv_gen_loop : for i in 0 to 2047 loop                                                                                  
                                wait for 33 * clk_period;
                                
                                if i = 0 then
                                        -- wait for 33 clock cycles (1 cycle to transition into state KEY_GEN and 32 cycles to generate the round keys)                                
                                        wait for 33 * clk_period;
                                end if;
                                
                                data_in <= rand_slv(64);

                                if i = 2047 then
                                        wait for 34 * clk_period;
                                end if;
                        end loop rand_slv_gen_loop;
                end loop rand_key_loop;

                wait; -- halt the simulation
        end process stimuli_proc;
end;