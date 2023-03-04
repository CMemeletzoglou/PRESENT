library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.state_pkg.all; -- for STATE type declaration

entity present_control_unit is
        port (
                clk           : in std_logic;
                rst           : in std_logic; -- system-wide reset signal
                ena           : in std_logic; -- system-wide enable signal
                key_ena       : in std_logic; -- used as a key_load signal when high
                mode_sel      : in std_logic_vector(1 downto 0);
                curr_round    : in std_logic_vector(4 downto 0); -- current round from system-global round counter
                
                enc_ena       : out std_logic; -- encryption datapath enable
                dec_ena       : out std_logic; -- decryption datapath enable
                key_sched_ena : out std_logic; -- top-level key schedule module enable
                mem_wr_ena    : out std_logic; -- round keys memory write enable
                counter_ena   : out std_logic; -- enable signal for the global round counter
                counter_rst   : out std_logic; -- reset signal for the global round counter
                counter_mode  : out std_logic;                
                ready         : out std_logic; -- system-global ready signal (indicates a finished encryption or decryption process)

                -- debugging signal, remove lated
                cu_state : out STATE;
                gen_count : out std_logic_vector(5 downto 0)
        );
end entity present_control_unit;

architecture rtl of present_control_unit is
        signal curr_state, next_state : STATE;
begin
        -- mode_sel(1) = 1 -> 128-bit key, 0 -> 80-bit key
        -- mode_sel(0) = 1 -> Decrypt, 0 -> Encrypt

        cu_state <= curr_state;

        state_reg_proc : process (clk, rst, ena)
        begin
                if (rst = '1') then
                        curr_state <= RESET;
                elsif (ena = '1' and rising_edge(clk)) then
                        curr_state <= next_state; -- curr_state stored in register of width log2(#states)
                end if;
        end process state_reg_proc;

        next_state_logic : process (curr_state, ena, key_ena, mode_sel, curr_round)
                variable key_gen_clock_cycles : natural range 0 to 32;
                variable operation_cycle_count : natural range 0 to 32;
        begin
                case curr_state is
                        when RESET =>
                                counter_rst  <= '1';
                                counter_mode <= '0'; -- counter counts upwards to store generated keys
                                counter_ena  <= '0';
                                ready        <= '0';
                                key_gen_clock_cycles := 0;
                                operation_cycle_count := 0;
                                next_state <= INIT;

                        when INIT =>
                                if (ena = '1' and key_ena = '1') then
                                        if (mode_sel(1) = '0' or mode_sel(1) = '1') then
                                                next_state  <= KEY_GEN;
                                                counter_rst <= '0';
                                                counter_ena  <= '1'; -- start the counter
                                                key_sched_ena <= '1';                                                
                                        else
                                                next_state <= INVALID;
                                        end if;
                                end if;

                        when KEY_GEN =>
                                mem_wr_ena    <= '1'; -- write enable for key storage  
                                if(curr_round'event and key_gen_clock_cycles < 32) then
                                        report "here at time : " & time'image(now);
                                        key_gen_clock_cycles := key_gen_clock_cycles + 1;
                                        gen_count <= std_logic_vector(to_unsigned(key_gen_clock_cycles, 6));
                                end if;

                                if(key_gen_clock_cycles = 32) then
                                        report "here2 at time : " & time'image(now);
                                        next_state    <= KEYS_READY;    
                                end if;

                        when KEYS_READY =>
                                key_sched_ena <= '0';
                                mem_wr_ena <= '0';
                                
                                if (mode_sel(0) = '1') then -- decryption mode
                                        next_state <= OP_DEC;
                                        counter_rst <= '1';
                                        counter_ena <= '0';
                                elsif (mode_sel(0) = '0') then -- encryption mode
                                        next_state <= OP_ENC;
                                        counter_rst <= '1';
                                        counter_ena <= '0';
                                else
                                        next_state <= INVALID;
                                end if;

                        when OP_ENC =>
                                enc_ena    <= '1';
                                dec_ena    <= '0';

                                counter_rst <= '0';
                                counter_ena <= '1';

                                if(curr_round'event and operation_cycle_count < 32) then                                
                                        operation_cycle_count := operation_cycle_count + 1;
                                end if;

                                if (operation_cycle_count = 32) then
                                        enc_ena <= '0';
                                        next_state <= DONE;
                                        counter_rst <= '1';
                                        counter_ena <= '0';
                                end if;

                        when OP_DEC =>
                                dec_ena    <= '1';
                                enc_ena    <= '0';
                                
                                counter_rst <= '0';
                                counter_ena <= '1';
                        
                                if(curr_round'event and operation_cycle_count < 32) then                                
                                        operation_cycle_count := operation_cycle_count + 1;
                                end if;

                                if (operation_cycle_count = 32) then
                                        dec_ena <= '0';
                                        next_state <= DONE;
                                        counter_rst <= '1';
                                        counter_ena <= '0';
                                end if;

                        when DONE =>
                                ready <= '1';                                
                                next_state <= DONE;

                        when INVALID =>
                                next_state <= INVALID;

                        when others =>
                                next_state <= INVALID;
                end case;
        end process next_state_logic;
end architecture;