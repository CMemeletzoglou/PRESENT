library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.state_pkg.all; -- for STATE type declaration

entity present_control_unit is
        port (
                clk               : in std_logic;
                rst               : in std_logic; -- system-wide reset signal
                ena               : in std_logic; -- system-wide enable signal
                key_ena           : in std_logic; -- used as a key_load signal when high
                mode_sel          : in std_logic_vector(1 downto 0);
                round_counter_val : in std_logic_vector(4 downto 0); -- current round from system-global round counter

                enc_ena           : out std_logic; -- encryption datapath enable
                dec_ena           : out std_logic; -- decryption datapath enable
                load_ena          : out std_logic; -- sent to the encryption/decryption datapath and when high it enables loading the input data into the state register
                out_ena           : out std_logic; -- new signal to allow the encryption datapath to write on the shared data_out bus
                key_sched_ena     : out std_logic; -- top-level key schedule module enable

                mem_ena           : out std_logic;
                mem_wr_ena        : out std_logic; -- round keys memory write enable
                counter_ena       : out std_logic; -- enable signal for the global round counter
                counter_rst       : out std_logic; -- reset signal for the global round counter
                counter_mode      : out std_logic;
                ready             : out std_logic; -- system-global ready signal (indicates a finished encryption or decryption process)

                -- debugging signal, remove later
                cu_state          : out STATE;

                mem_address_mode  : out std_logic
        );
end entity present_control_unit;

architecture rtl of present_control_unit is
        signal curr_state, next_state : STATE;
begin
        -- mode_sel(1) = 1 -> 128-bit key, 0 -> 80-bit key
        -- mode_sel(0) = 1 -> Decrypt, 0 -> Encrypt

        cu_state <= curr_state; -- debugging signal

        state_reg_proc : process (clk, rst, ena)
        begin
                if (rst = '1') then
                        curr_state <= INIT;
                elsif (ena = '1' and rising_edge(clk)) then
                        curr_state <= next_state; -- curr_state stored in register of width log2(#states)
                end if;
        end process state_reg_proc;

        next_state_logic : process (curr_state, rst, ena, key_ena, mode_sel, round_counter_val)
                -- The following helper variables have 33 possible values, due to their usage in the KEY_GEN phase
                -- and the OP_ENC/OP_DEC phases, respectively, where there is one clock cycle delay introduced by
                -- certain registers in the involved submodules. Specifically :
                --                 
                --   a) key_gen_clock_cycles : this variable is used during the KEY_GEN phase, where 
                --      (32 + 1) clock cycles are needed in order to generate the 32 keys, due to the one clock
                --      cycle delay introduced by the output register of the top-level key schedule module.
                --      
                --   b) op_cycles : this variable is used during the OP_ENC/OP_DEC phases, where
                --      initially one clock cycle is needed for the plaintext/ciphertext to be loaded
                --      into the state register.
                --      Then, since there are 32 round keys stored in the round keys memory, we need 32 cycles
                --      for the actual encryption/decryption operation. Thus, we stay in the OP_ENC/OP_DEC phase
                --      for 1 + 32 = 33 clock cycles. This is what the helper variable op_cycles counts.
                variable key_gen_clock_cycles : natural range 0 to 32;
                variable op_cycles            : natural range 0 to 32;

                -- Helper variable to store the previous value of the round counter, in order to compare it
                -- with the current one (round_counter_val input signal).
                -- This way, we implement the logic of the "round_counter_val'event" check, but without
                -- using the event attribute on the std_logic_vector, which poses a non-synthesizable solution.                
                variable prev_round_counter_val : unsigned(4 downto 0);
        begin
                case curr_state is
                        when INIT =>
                                if (rst = '1') then -- while rst is high stay in the "reset" state
                                        next_state   <= INIT;
                                        counter_rst  <= '1';
                                        counter_mode <= '0'; -- counter counts upwards to store generated keys
                                        counter_ena  <= '0';
                                        ready        <= '0';
                                        key_gen_clock_cycles := 0;
                                        op_cycles            := 0;

                                        mem_address_mode <= '1';
                                        out_ena          <= '0';

                                        enc_ena <= '0';
                                        dec_ena <= '0';

                                        load_ena <= '0';

                                        key_sched_ena <= '0';
                                        mem_wr_ena    <= '0';
                                        mem_ena <= '0';

                                elsif (ena = '1' and key_ena = '1') then
                                        if (mode_sel(1) = '0' or mode_sel(1) = '1') then
                                                next_state    <= KEY_GEN;
                                                counter_rst   <= '0';
                                                counter_ena   <= '1'; -- start the counter
                                                key_sched_ena <= '1';

                                                prev_round_counter_val := "00000";
                                        else
                                                next_state <= INVALID;
                                        end if;
                                end if;

                        when KEY_GEN =>
                                mem_wr_ena <= '1'; -- write enable for key storage      
                                mem_ena <= '1';                              

                                -- check for a change in the value of the round counter, without using the event attribute
                                -- if (round_counter_val'event and key_gen_clock_cycles < 32) then
                                if (unsigned(round_counter_val) /= prev_round_counter_val and key_gen_clock_cycles < 32) then
                                        key_gen_clock_cycles := key_gen_clock_cycles + 1;

                                        -- the current value of the round counter is the next previous one
                                        prev_round_counter_val := unsigned(round_counter_val);
                                end if;

                                if (key_gen_clock_cycles = 32) then
                                        if (mode_sel(0) = '1') then -- decryption mode
                                                next_state   <= OP_DEC;
                                                counter_rst  <= '1';
                                                counter_mode <= '1'; -- count downwards
                                                counter_ena  <= '0';

                                                -- prev_round_counter_val := "11111";
                                                prev_round_counter_val := "00000";

                                                dec_ena  <= '1';
                                                load_ena <= '1';

                                        elsif (mode_sel(0) = '0') then -- encryption mode
                                                next_state   <= OP_ENC;
                                                counter_rst  <= '1';
                                                counter_mode <= '0'; -- count upwards     
                                                counter_ena  <= '0';

                                                prev_round_counter_val := "00000";

                                                enc_ena  <= '1';
                                                load_ena <= '1';
                                        else
                                                next_state <= INVALID;
                                        end if;
                                end if;

                        when OP_ENC =>
                                key_sched_ena <= '0';
                                mem_wr_ena    <= '0';

                                enc_ena <= '1';
                                dec_ena <= '0';

                                counter_rst <= '0';
                                counter_ena <= '1';

                                ready            <= '0';
                                mem_address_mode <= '1';

                                -- check for a change in the value of the round counter, without using the event attribute
                                -- if (round_counter_val'event and op_cycles < 32) then
                                if (unsigned(round_counter_val) /= prev_round_counter_val and op_cycles < 32) then
                                        op_cycles := op_cycles + 1;

                                        -- the current value of the round counter is the next previous one
                                        prev_round_counter_val := unsigned(round_counter_val);
                                        load_ena <= '0';
                                end if;

                                if (op_cycles = 32) then
                                        next_state  <= DONE;
                                        enc_ena     <= '0';
                                        counter_rst <= '1';
                                        counter_ena <= '0';
                                        out_ena     <= '1';
                                end if;

                        when OP_DEC =>
                                key_sched_ena <= '0';
                                mem_wr_ena    <= '0';

                                dec_ena <= '1';
                                enc_ena <= '0';

                                counter_rst <= '0';
                                counter_ena <= '1';

                                ready            <= '0';
                                mem_address_mode <= '0';

                                -- check for a change in the value of the round counter, without using the event attribute
                                -- if (round_counter_val'event and op_cycles < 32) then
                                if (unsigned(round_counter_val) /= prev_round_counter_val and op_cycles < 32) then
                                        op_cycles := op_cycles + 1;

                                        -- the current value of the round counter is the next previous one
                                        prev_round_counter_val := unsigned(round_counter_val);
                                        load_ena <= '0';
                                end if;

                                if (op_cycles = 32) then
                                        next_state  <= DONE;
                                        dec_ena     <= '0';
                                        counter_rst <= '1';
                                        counter_ena <= '0';
                                        out_ena     <= '1';
                                end if;

                        when DONE =>
                                ready <= '1';
                                op_cycles := 0;
                                out_ena <= '0';

                                load_ena <= '1';

                                -- start a new encryption decryption
                                if (mode_sel(0) = '0') then -- start encryption
                                        next_state <= OP_ENC;
                                        prev_round_counter_val := b"00000";
                                        counter_mode <= '0';
                                elsif (mode_sel(0) = '1') then
                                        next_state <= OP_DEC;
                                        prev_round_counter_val := b"00000"; -- use this if the counter is always reset to zero
                                        -- prev_round_counter_val := b"11111";
                                        counter_mode <= '1';
                                else
                                        next_state <= DONE;
                                end if;

                        when INVALID =>
                                next_state <= INVALID;

                        when others =>
                                next_state <= INVALID;
                end case;
        end process next_state_logic;
end architecture;