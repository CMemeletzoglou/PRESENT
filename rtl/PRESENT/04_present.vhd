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
                key_mem_out     : std_logic_vector(63 downto 0);

        signal  current_round   : std_logic_vector(4 downto 0);

        signal  counter_ena,
                counter_rst,
                counter_mode    : std_logic;

        signal  enc_ena,
                dec_ena         : std_logic;

        signal  key_sched_ena,
                mem_wr_ena      : std_logic;

        signal cu_state : STATE; -- remove this , debugging signal
        signal gen_count : std_logic_vector(5 downto 0); -- remove this , debugging signal

        signal ciphertext, plaintext : std_logic_vector(63 downto 0);

        signal mem_address : std_logic_vector(4 downto 0);

        signal mux_sel : std_logic;
begin
        -- mode_sel(1) = 1 -> 128-bit key, 0 -> 80-bit key
        -- mode_sel(0) = 1 -> Decrypt, 0 -> Encrypt
        mux_sel <= mode_sel(0);

        control_unit : entity work.present_control_unit
                port map(
                        -- inputs
                        clk        => clk,
                        rst        => rst,
                        ena        => ena,
                        key_ena    => key_ena,
                        mode_sel   => mode_sel,
                        curr_round => current_round,

                        -- outputs
                        enc_ena       => enc_ena,
                        dec_ena       => dec_ena,
                        key_sched_ena => key_sched_ena,
                        mem_wr_ena    => mem_wr_ena,
                        counter_ena   => counter_ena,
                        counter_rst   => counter_rst,
                        counter_mode  => counter_mode,

                        ready         => ready,

                        cu_state => cu_state,
                        gen_count => gen_count
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
                        current_round_num => current_round
                );

        mem_address <= std_logic_vector(unsigned(current_round) - 1);
        round_key_mem : entity work.key_mem
                port map(
                        clk       => clk,
                        -- addr      => current_round,
                        addr      => mem_address,
                        data_in   => key_sched_out,
                        wr_ena    => mem_wr_ena,
                        data_out  => key_mem_out
                );

        enc_dp : entity work.present_enc
                port map(
                        clk               => clk,
                        rst               => rst,
                        ena               => enc_ena,
                        plaintext         => data_in,
                        round_key         => key_mem_out,
                        current_round_num => current_round,                        
                        ciphertext  => ciphertext
                );

        dec_dp : entity work.present_dec
                port map(
                        clk               => clk,
                        rst               => rst,
                        ena               => dec_ena,
                        ciphertext        => data_in,
                        round_key         => key_mem_out,
                        current_round_num => current_round,                        
                        plaintext => plaintext
                );
        
        -- mux that controls the output from the encryption and decryption cores
        out_mux : entity work.mux             
                generic map(
                        DATA_WIDTH => 64
                )
                port map(
                        input_A => ciphertext,
                        input_B => plaintext,
                        sel => mux_sel,
                        mux_out => data_out
                );
end architecture;