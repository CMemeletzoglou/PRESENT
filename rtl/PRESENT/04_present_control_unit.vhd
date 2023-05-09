library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.state_pkg.all; -- for STATE type declaration

entity present_control_unit is
        port (
                clk               : in std_logic;
                rst               : in std_logic; -- system-wide reset signal
                ena               : in std_logic; -- system-wide enable signal                
                mode_sel          : in std_logic_vector(1 downto 0);

                round_counter_val : out std_logic_vector(4 downto 0);
                mem_addr          : out std_logic_vector(4 downto 0);
                mem_wr_ena        : out std_logic; -- round keys memory write enable

                enc_ena           : out std_logic; -- encryption datapath enable (maybe merge these two into one signal?)
                dec_ena           : out std_logic; -- encryption datapath enable (maybe merge these two into one signal?)
                load_ena          : out std_logic; -- sent to the encryption/decryption datapath and when high it enables loading the input data into the state register

                key_sched_ena     : out std_logic; -- top-level key schedule module enable
                out_ena           : out std_logic; -- allow the output register to capture enc/dec datapath output
                ready             : out std_logic; -- system-global ready signal (indicates a finished encryption or decryption process)

                -- debugging signal, remove later
                cu_state          : out STATE
        );
end entity present_control_unit;

architecture rtl of present_control_unit is
        signal fsm_state : STATE;
        
        signal  counter_rst,
                counter_ena,
                counter_mode : std_logic;
        
        signal  current_round : std_logic_vector(4 downto 0);
begin
        -- mode_sel(1) = 1 -> 128-bit key, 0 -> 80-bit key
        -- mode_sel(0) = 1 -> Decrypt, 0 -> Encrypt

        cu_state <= fsm_state; -- debugging signal

        fsm_process : process (clk, rst)
        begin
                if (rst = '1') then
                        fsm_state <= INIT;

                        -- reset FSM output signals
                        mem_addr <= "00000";
                        mem_wr_ena <= '0';
                        enc_ena <= '0';
                        dec_ena <= '0';
                        load_ena <= '0';
                        key_sched_ena <= '0';
                        out_ena <= '0';
                        ready <= '0';

                        -- reset internal counter
                        counter_rst <= '1';
                        counter_ena <= '0';

                elsif rising_edge(clk) then
                        
                        case fsm_state is
                                when INIT =>
                                        mem_addr <= "00000";
                                        mem_wr_ena <= '0';
                                        enc_ena <= '0';
                                        dec_ena <= '0';
                                        load_ena <= '0';
                                        key_sched_ena <= '0';
                                        out_ena <= '0';
                                        ready <= '0';

                                        -- reset internal counter
                                        counter_rst <= '1';
                                        counter_ena <= '0';

                                        if (ena = '1') then
                                                if (mode_sel(1) = '0' or mode_sel(1) = '1') then
                                                        fsm_state     <= KEY_GEN;
                                                        counter_rst   <= '0';
                                                        counter_ena   <= '1'; -- start the counter
                                                        counter_mode <= '0';
                                                        key_sched_ena <= '1';
                                                end if;
                                        end if;
                                        
        
                                when KEY_GEN =>                                        
                                        mem_addr <= current_round;
                                        mem_wr_ena <= '1';
                                        enc_ena <= '0';
                                        dec_ena <= '0';
                                        load_ena <= '0';
                                        key_sched_ena <= '1';
                                        out_ena <= '0';
                                        ready <= '0';

                                        if (current_round = "11111") then                                                
                                                if (mode_sel(0) = '0') then
                                                        fsm_state <= OP_ENC;
                                                        enc_ena <= '1';
                                                        load_ena <= '1';
                                                        counter_mode <= '0';
                                                elsif (mode_sel(0) = '1') then
                                                        fsm_state <= OP_DEC;
                                                        dec_ena <= '1';
                                                        load_ena <= '0';
                                                        counter_mode <= '1';
                                                end if;
                                        end if;

                                
                                when OP_ENC =>
                                        mem_addr <= current_round;
                                        mem_wr_ena <= '0';
                                        enc_ena <= '1';
                                        dec_ena <= '0';
                                        load_ena <= '0';
                                        key_sched_ena <= '0';
                                        out_ena <= '0';
                                        ready <= '0';

                                        if (current_round = "11111") then
                                                fsm_state <= DONE;
                                                out_ena <= '1';

                                                -- reset counter
                                                counter_rst <= '1';
                                                counter_ena <= '0';
                                        end if;


                                when OP_DEC =>
                                        mem_addr <= current_round;
                                        mem_wr_ena <= '0';
                                        enc_ena <= '1';
                                        dec_ena <= '0';
                                        load_ena <= '0';
                                        key_sched_ena <= '0';
                                        out_ena <= '0';
                                        ready <= '0';

                                        if (current_round = "00000") then
                                                fsm_state <= DONE;
                                                out_ena <= '1';

                                                -- reset counter
                                                counter_rst <= '1';
                                                counter_ena <= '0';
                                        end if;

                                when DONE =>
                                        ready <= '1';
                                        out_ena <= '0';
                                        load_ena <= '1';

                                        counter_rst <= '0';
                                        counter_ena <= '1';

                                        if (mode_sel(0) = '0') then
                                                counter_mode <= '0';
                                                fsm_state <= OP_ENC;
                                        
                                        elsif (mode_sel(0) = '1') then
                                                counter_mode <= '1';
                                                fsm_state <= OP_DEC;
                                        end if;
                                        
        
                                when INVALID =>
                                        fsm_state <= INVALID;
        
                                when others =>
                                        fsm_state <= INVALID;
                        end case;
                end if;
        end process;

        
        round_counter : entity work.counter
                generic map(
                        COUNTER_WIDTH => 5
                )
                port map(
                        clk     => clk,
                        rst     => counter_rst,
                        cnt_ena => counter_ena,
                        updown  => counter_mode,
                        count   => current_round
                );
        
        round_counter_val <= current_round;        
end architecture;