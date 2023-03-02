library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.state_pack.all; -- for STATE type declaration

entity present_control_unit is
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
end entity present_control_unit;

architecture rtl of present_control_unit is
        signal curr_state, next_state : STATE;
begin
        -- mode_sel(1) = 1 -> 128-bit key, 0 -> 80-bit key
        -- mode_sel(0) = 1 -> Decrypt, 0 -> Encrypt

        state_reg_proc : process (clk, rst)
        begin
                if (rst = '1') then
                        curr_state <= RESET;
                elsif rising_edge(clk) then
                        curr_state <= next_state; -- curr_state stored in register of width log2(#states)
                end if;
        end process state_reg_proc;

        -- next_state_logic : process (curr_state, enc_ready, dec_ready)
        next_state_logic : process (curr_state, curr_round)
                variable keys_count : natural range 0 to 32;
        begin
                case curr_state is
                        when RESET =>
                                counter_rst  <= '1';
                                counter_mode <= '0'; -- counter counts upwards to store generated keys
                                counter_ena  <= '0';
                                ready        <= '0';
                                keys_count := 0;
                                next_state <= INIT;

                        when INIT =>
                                if (ena = '1' and key_ena = '1') then
                                        if (mode_sel(1) = '0' or mode_sel(1) = '1') then
                                                next_state  <= KEY_GEN;
                                                counter_rst <= '0';
                                                -- counter_ena  <= '1'; -- start the counter
                                        else
                                                next_state <= INVALID;
                                        end if;
                                end if;

                        when KEY_GEN =>
                                key_sched_ena <= '1';
                                counter_ena   <= '1'; -- start the counter
                                mem_wr_en     <= '1'; -- write enable for key storage  

                                keys_count := keys_count + 1;

                                if (keys_count = 32) then -- key generation finished
                                        next_state    <= KEYS_READY;
                                        key_sched_ena <= '0';

                                        -- counter_rst <= '1'; -- reset the counter
                                        -- counter_mode <= mode_sel(0); -- set the counter to the proper mode
                                        -- counter_ena <= '0';

                                        mem_wr_en <= '0';
                                end if;

                        when KEYS_READY =>
                                if (mode_sel(0) = '1') then -- decryption mode
                                        next_state <= OP_DEC;
                                        dec_ena    <= '1';
                                        enc_ena    <= '0';

                                        counter_rst <= '0';
                                        counter_ena <= '1'; -- start the counter
                                elsif (mode_sel(0) = '0') then -- encryption mode
                                        next_state <= OP_ENC;
                                        enc_ena    <= '1';
                                        dec_ena    <= '0';

                                        counter_rst <= '0';
                                        counter_ena <= '1'; -- start the counter
                                else
                                        next_state <= INVALID;
                                end if;

                        when OP_ENC =>
                                counter_rst <= '0';
                                if (enc_ready = '1') then
                                        next_state <= DONE;
                                end if;

                        when OP_DEC =>
                                counter_rst <= '0';
                                if (dec_ready = '1') then
                                        next_state <= DONE;
                                end if;

                        when DONE =>
                                next_state <= DONE;
                                ready      <= '1';

                        when INVALID =>
                                next_state <= INVALID;

                        when others =>
                                next_state <= INVALID;
                end case;
        end process next_state_logic;
end architecture;