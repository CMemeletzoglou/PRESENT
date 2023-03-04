library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

entity key_sched_mem_test_tb is
end;

architecture bench of key_sched_mem_test_tb is

        component key_sched_mem_test
                port (
                        clk           : in std_logic;
                        rst           : in std_logic;
                        ena           : in std_logic;
                        mode          : in std_logic;
                        input_key     : in std_logic_vector(127 downto 0);
                        key_sched_out : out std_logic_vector(63 downto 0);
                        curr_round    : out std_logic_vector(4 downto 0);
                        mem_output    : out std_logic_vector(63 downto 0)
                );
        end component;

        -- Clock period
        constant clk_period : time := 2 ns;
        -- Generics

        -- Ports
        signal clk           : std_logic;
        signal rst           : std_logic;
        signal ena           : std_logic;
        signal mode          : std_logic;
        signal input_key     : std_logic_vector(127 downto 0);
        signal key_sched_out : std_logic_vector(63 downto 0);
        signal curr_round    : std_logic_vector(4 downto 0);
        signal mem_output    : std_logic_vector(63 downto 0);

begin
        key_sched_mem_test_inst : key_sched_mem_test
        port map(
                clk           => clk,
                rst           => rst,
                ena           => ena,
                mode          => mode,
                input_key     => input_key,
                key_sched_out => key_sched_out,
                curr_round    => curr_round,
                mem_output    => mem_output
        );

        clk_process : process
        begin
                clk <= '1';
                wait for clk_period/2;
                clk <= '0';
                wait for clk_period/2;
        end process clk_process;

        rst <= '1', '0' after 2*clk_period;
        input_key <= x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

        stimuli_gen : process begin
                wait until rst = '0';
                
                wait for clk_period/2;                
                mode <= '0'; -- 128-bit test
                ena <= '1';

                wait for 33*clk_period;
                
                wait for 33*clk_period;

                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now) 
                        severity failure;

                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;

                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                
                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;

                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;

                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                
                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;
               
                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;
               
                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;
               
                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;

                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;

                wait for clk_period;                
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;

                wait for clk_period;                 
                assert mem_output = key_sched_out
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                        
                wait for clk_period;
                assert now = 200ns
                        report "all assertions passed!"
                        severity note;
                
                wait;

        end process stimuli_gen;

end;