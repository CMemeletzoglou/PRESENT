library ieee;
use ieee.std_logic_1164.all;

library work;
use work.state_pack.all;

entity present_control_unit_tb is
end;

architecture bench of present_control_unit_tb is

        component present_control_unit
                port (
                        clk           : in std_logic;
                        rst           : in std_logic; -- system-wide reset signal
                        ena           : in std_logic; -- system-wide enable signal
                        key_ena       : in std_logic; -- used as a key_load signal when high
                        mode_sel      : in std_logic_vector(1 downto 0);
                        curr_round    : in std_logic_vector(4 downto 0); -- current round from system-global round counter
                        enc_ready     : in std_logic;
                        dec_ready     : in std_logic;
                        enc_ena       : out std_logic; -- encryption datapath enable
                        dec_ena       : out std_logic; -- decryption datapath enable
                        key_sched_ena : out std_logic; -- top-level key schedule module enable
                        mem_wr_en     : out std_logic; -- round keys memory write enable
                        counter_ena   : out std_logic; -- enable signal for the global round counter
                        counter_rst   : out std_logic; -- reset signal for the global round counter
                        counter_mode  : out std_logic;
                        ready         : out std_logic -- system-global ready signal (indicates a finished encryption or decryption process)
                );
        end component;

        -- Clock period
        constant clk_period : time := 2 ns;
        -- Generics

        -- Ports
        signal clk           : std_logic;
        signal rst           : std_logic; -- system-wide reset signal
        signal ena           : std_logic; -- system-wide enable signal
        signal key_ena       : std_logic; -- used as a key_load signal when high
        signal mode_sel      : std_logic_vector(1 downto 0);
        signal curr_round    : std_logic_vector(4 downto 0); -- current round from system-global round counter
        signal enc_ready     : std_logic;
        signal dec_ready     : std_logic;
        signal enc_ena       : std_logic; -- encryption datapath enable
        signal dec_ena       : std_logic; -- decryption datapath enable
        signal key_sched_ena : std_logic; -- top-level key schedule module enable
        signal mem_wr_en     : std_logic; -- round keys memory write enable
        signal counter_ena   : std_logic; -- enable signal for the global round counter
        signal counter_rst   : std_logic; -- reset signal for the global round counter
        signal counter_mode  : std_logic;
        signal ready         : std_logic; -- system-global ready signal (indicates a finished encryption or decryption process)
begin

        round_counter : entity work.counter
                generic map(
                        COUNTER_WIDTH => 5
                )
                port map(
                        clk    => clk,
                        rst    => counter_rst,
                        ena    => counter_ena,
                        updown => counter_mode,
                        count  => curr_round
                );

        present_control_unit_inst : present_control_unit
        port map(
                clk           => clk,
                rst           => rst,
                ena           => ena,
                key_ena       => key_ena,
                mode_sel      => mode_sel,
                curr_round    => curr_round,
                enc_ready     => enc_ready,
                dec_ready     => dec_ready,
                enc_ena       => enc_ena,
                dec_ena       => dec_ena,
                key_sched_ena => key_sched_ena,
                mem_wr_en     => mem_wr_en,
                counter_ena   => counter_ena,
                counter_rst   => counter_rst,
                counter_mode  => counter_mode,
                ready         => ready
        );

        clk_process : process
        begin
                clk <= '1';
                wait for clk_period/2;
                clk <= '0';
                wait for clk_period/2;
        end process clk_process;

        -- raise reset
        rst <= '1', '0' after 2 * clk_period;

        stimuli_proc : process begin    
                -- RESET
                
                wait until rst = '0';

                ena <= '1'; -- goto INIT state

                -- INIT               
                key_ena <= '1'; -- goto KEY_GEN state
                mode_sel(1) <= '1';

                -- KEY_GEN, wait for 33 cycles for key generation
                -- after 33 cycles -> goto KEYS_READY state
                
                -- KEYS_READY 
                 mode_sel(0) <= '0'; -- encryption mode

                -- OP_ENC, wait for 33 cycles until enc is done -> done state
        
                -- DONE state        
                wait;
        end process stimuli_proc;

end;