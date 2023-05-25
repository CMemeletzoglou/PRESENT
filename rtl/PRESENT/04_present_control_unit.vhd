library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity present_control_unit is
        port (
                clk                     : in std_logic;
                rst                     : in std_logic; -- system-wide reset signal
                ena                     : in std_logic; -- system-wide enable signal                
                op_sel                  : in std_logic;

                round_counter_val       : out std_logic_vector(4 downto 0);
                mem_addr                : out std_logic_vector(4 downto 0);
                mem_wr_ena              : out std_logic; -- round keys memory write enable

                enc_ena                 : out std_logic; -- encryption datapath enable
                dec_ena                 : out std_logic; -- decryption datapath enable
                load_ena                : out std_logic; -- sent to the encryption/decryption datapath and when high it enables loading the input data into the state register

                key_sched_ena           : out std_logic; -- top-level key schedule module enable
                out_ena                 : out std_logic; -- allow the output register to capture enc/dec datapath output
                ready                   : out std_logic -- system-global ready signal (indicates a finished encryption or decryption process)
        );
end entity present_control_unit;

architecture fsm of present_control_unit is
        type STATE is (INIT, KEY_GEN, CRYPTO_OP, DONE);
        signal  fsm_state : STATE;

        signal  counter_rst,
                counter_ena : std_logic;

        signal  current_round : std_logic_vector(4 downto 0);
begin
        -- op_sel = 1 -> Decrypt, 0 -> Encrypt
        fsm_process : process (clk, rst)
        begin
                if (rst = '1') then
                        fsm_state <= INIT;

                        -- reset FSM output signals
                        mem_addr      <= "00000";
                        mem_wr_ena    <= '0';
                        enc_ena       <= '0';
                        dec_ena       <= '0';
                        load_ena      <= '0';
                        key_sched_ena <= '0';
                        out_ena       <= '0';
                        ready         <= '0';

                        -- reset internal counter
                        counter_rst <= '1';
                        counter_ena <= '0';

                elsif rising_edge(clk) then
                        mem_addr <= current_round;

                        case fsm_state is
                                when INIT =>
                                        if (ena = '1') then
                                                if (op_sel = '0' or op_sel = '1') then
                                                        key_sched_ena <= '1';

                                                        -- restart counter
                                                        counter_rst <= '0';
                                                        counter_ena <= '1';

                                                        fsm_state <= KEY_GEN;
                                                end if;
                                        end if;

                                when KEY_GEN =>
                                        mem_wr_ena <= '1';
                                        if (current_round = "11111") then
                                                load_ena <= '1';

                                                fsm_state <= CRYPTO_OP;

                                                if (op_sel = '0') then
                                                        enc_ena <= '1';

                                                elsif (op_sel = '1') then
                                                        dec_ena <= '1';

                                                end if;
                                        end if;

                                when CRYPTO_OP =>
                                        load_ena      <= '0';
                                        key_sched_ena <= '0';
                                        mem_wr_ena    <= '0';
                                        ready         <= '0';

                                        -- No updown counter is needed if we use an up counter and
                                        -- during the decryption operation we index the round keys 
                                        -- memory using (31 - current_round) as the memory address
                                        if (op_sel = '1') then
                                                mem_addr <= std_logic_vector(31 - unsigned(current_round));
                                        end if;

                                        if (current_round = "11111") then
                                                out_ena     <= '1';
                                                counter_ena <= '0';
                                                fsm_state   <= DONE;
                                        end if;

                                when DONE =>
                                        enc_ena <= '0';
                                        dec_ena <= '0';
                                        ready   <= '1';
                                        out_ena <= '0';

                                        load_ena <= '1';

                                        counter_ena <= '1';
                                        fsm_state   <= CRYPTO_OP;

                                        if (op_sel = '0') then
                                                enc_ena <= '1';

                                        elsif (op_sel = '1') then
                                                dec_ena <= '1';
                                        end if;

                                when others =>
                                        fsm_state <= INIT;
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
                        count   => current_round
                );

        round_counter_val <= current_round;
end architecture;