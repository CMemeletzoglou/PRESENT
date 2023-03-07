library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.state_pkg.all; -- for STATE type declaration

entity present is
        port (
                clk      : in std_logic;
                rst      : in std_logic;
                ena      : in std_logic;
                key_ena  : in std_logic;
                mode_sel : in std_logic_vector(1 downto 0);
                key      : in std_logic_vector(127 downto 0);
                data_in  : in std_logic_vector(63 downto 0);
                data_out : out std_logic_vector(63 downto 0);
                ready    : out std_logic
        );
end entity present;

architecture rtl of present is
        signal  key_sched_out,
                key_mem_out : std_logic_vector(63 downto 0);

        signal  current_round : std_logic_vector(4 downto 0);

        signal  counter_ena,
                counter_rst,
                counter_mode : std_logic;

        signal  enc_ena,
                dec_ena : std_logic;

        signal  key_sched_ena,
                mem_wr_ena : std_logic;

        signal  cu_state  : STATE; -- remove this , debugging signal
        signal  gen_count : std_logic_vector(5 downto 0); -- remove this , debugging signal

        signal  ciphertext,
                plaintext : std_logic_vector(63 downto 0);

        signal  mem_address : std_logic_vector(4 downto 0);

        signal  mux_sel,
                key_gen_finished,
                mem_address_mode,
                out_ena : std_logic;
begin
        -- mode_sel(1) = 1 -> 128-bit key, 0 -> 80-bit key
        -- mode_sel(0) = 1 -> Decrypt, 0 -> Encrypt
        mux_sel <= mode_sel(0);

        control_unit : entity work.present_control_unit
                port map(
                        -- inputs
                        clk               => clk,
                        rst               => rst,
                        ena               => ena,
                        key_ena           => key_ena,
                        mode_sel          => mode_sel,
                        round_counter_val => current_round,

                        -- outputs
                        enc_ena       => enc_ena,
                        dec_ena       => dec_ena,

                        out_ena   => out_ena,

                        key_sched_ena => key_sched_ena,
                        mem_wr_ena    => mem_wr_ena,
                        counter_ena   => counter_ena,
                        counter_rst   => counter_rst,
                        counter_mode  => counter_mode,

                        ready => ready,

                        -- debugging signals
                        cu_state  => cu_state,
                        gen_count => gen_count,

                        -- testing signals
                        key_gen_finished => key_gen_finished,
                        mem_address_mode => mem_address_mode
                );

        round_counter : entity work.counter
                generic map(
                        COUNTER_WIDTH => 5
                )
                port map(
                        clk    => clk,
                        rst    => counter_rst,
                        ena    => counter_ena,
                        updown => counter_mode,
                        count  => current_round
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

        -- this "-1" in the value of the round counter, is needed during the KEY_GEN phase, due to the
        -- 1 cycle delay introduced by the register in the output of the top-level key schedule module.
        -- However, when an Encryption or a Decryption starts, we don't actually need this "-1" logic,
        -- since we then need to address the round keys memory, using the exact value of the round counter.

        -- mem_address <= std_logic_vector(unsigned(current_round) - 1) when (key_gen_finished = '0')
        --                 else current_round;
        -- mem_address <= std_logic_vector(unsigned(current_round) - 1);

        mem_address_control_adder : entity work.prog_adder
                generic map(
                        DATA_WIDTH => 5
                )
                port map(
                        input_A => current_round,
                        input_B => "00001",
                        mode    => mem_address_mode,
                        out_val => mem_address
                );

        round_key_mem : entity work.key_mem
                port map(
                        clk => clk,
                        -- addr      => current_round,
                        addr     => mem_address,
                        data_in  => key_sched_out,
                        wr_ena   => mem_wr_ena,
                        data_out => key_mem_out
                );

        enc_dp : entity work.present_enc
                port map(
                        clk               => clk,
                        rst               => rst,
                        ena               => enc_ena,
                        out_ena           => out_ena,
                        plaintext         => data_in,
                        round_key         => key_mem_out,
                        round_counter_val => current_round,
                        ciphertext        => ciphertext
                );

        dec_dp : entity work.present_dec
                port map(
                        clk               => clk,
                        rst               => rst,
                        ena               => dec_ena,
                        out_ena           => out_ena,
                        ciphertext        => data_in,
                        round_key         => key_mem_out,
                        round_counter_val => current_round,
                        plaintext         => plaintext
                );

        -- mux that controls the output from the encryption and decryption cores
        out_mux : entity work.mux
                generic map(
                        DATA_WIDTH => 64
                )
                port map(
                        input_A => ciphertext,
                        input_B => plaintext,
                        sel     => mux_sel,
                        mux_out => data_out
                );
end architecture;