library ieee;
use ieee.std_logic_1164.all;

library work;
use work.key_length_pack.all;

entity present_dec is
        port (
                clk, rst, ena : in std_logic;
                ciphertext    : in std_logic_vector(63 downto 0);
                key           : in std_logic_vector(KEY_LENGTH - 1 downto 0);
                plaintext     : out std_logic_vector(63 downto 0);
                ready         : out std_logic
        );
end present_dec;

architecture structural of present_dec is
        signal  mux_sel,
                plain_enable : std_logic;

        signal  current_round_num : std_logic_vector(4 downto 0);

        signal  state_reg_mux_out,
                state : std_logic_vector(63 downto 0);

        signal  inv_pbox_layer_input,
                inv_sbox_layer_input,
                inv_sbox_layer_out,
                round_key : std_logic_vector(63 downto 0);

        signal  key_reg_out,
                key_reg_mux_out,
                key_schedule_out : std_logic_vector(KEY_LENGTH - 1 downto 0);

        constant BLOCK_SIZE : natural := 64;
begin
        -- control signal for the multiplexers controlling the input of
        -- State and Key registers
        mux_sel <= '1' when (current_round_num = "00000") else '0';

        -- 64-bit mux which drives the state register
        state_reg_mux : entity work.mux
                generic map(
                        DATA_WIDTH => BLOCK_SIZE
                )
                port map(
                        input_A => inv_sbox_layer_out,
                        input_B => ciphertext,
                        sel     => mux_sel,
                        mux_out => state_reg_mux_out
                );

        -- 80-bit/128-bit mux which drives the key register
        key_reg_mux : entity work.mux
                generic map(
                        DATA_WIDTH => KEY_LENGTH
                )
                port map(
                        input_A => key_schedule_out,
                        input_B => key,
                        sel     => mux_sel,
                        mux_out => key_reg_mux_out
                );

        -- 64-bit state register
        state_reg : entity work.reg
                generic map(
                        DATA_WIDTH => BLOCK_SIZE
                )
                port map(
                        clk  => clk,
                        rst  => rst,
                        ena  => ena,
                        din  => state_reg_mux_out,
                        dout => state
                );

        -- 80-bit/128-bit key register, at each round it stores the current subkey
        key_reg : entity work.reg
                generic map(
                        DATA_WIDTH => KEY_LENGTH
                )
                port map(
                        clk  => clk,
                        rst  => rst,
                        ena  => ena,
                        din  => key_reg_mux_out,
                        dout => key_reg_out
                );

        -- current round key, it consists of the 64 leftmost bits of the key register
        round_key <= key_reg_out(KEY_LENGTH - 1 downto KEY_LENGTH - 64);

        -- 64-bit xor to add current round key to state
        xor_64 : entity work.xor_n
                generic map(
                        DATA_WIDTH => BLOCK_SIZE
                )
                port map(
                        a => state,
                        b => round_key,
                        y => inv_pbox_layer_input
                );

        -- Inverse P-Box layer, the *diffusion* removal layer
        inv_pbox_layer : entity work.inv_pbox
                port map(
                        data_in  => inv_pbox_layer_input,
                        data_out => inv_sbox_layer_input
                );

        -- Inverse S-Box layer (16 inv S-Boxes in parallel), the *confusion* removal layer
        inv_sbox_layer : entity work.inv_sbox_layer
                port map(
                        inv_sbox_layer_in  => inv_sbox_layer_input,
                        inv_sbox_layer_out => inv_sbox_layer_out
                );

        -- round counter, incremented by 1 at each network round
        round_counter : entity work.counter
                generic map (
                        COUNTER_WIDTH => 5
                )
                port map(
                        clk   => clk,
                        rst   => rst,
                        updown => '1', -- count downwards
                        count => current_round_num
                );

        -- key schedule module, produces the new contents of the key register
        inv_key_schedule : entity work.inv_key_schedule
                port map(
                        input_key     => key_reg_out,
                        round_counter => current_round_num,
                        output_key    => key_schedule_out
                );

        -- 64-bit plaintext register
        plain_reg : entity work.reg
                generic map(
                        DATA_WIDTH => BLOCK_SIZE
                )
                port map(
                        clk  => clk,
                        rst  => rst,
                        ena  => plain_enable,
                        din  => inv_pbox_layer_input,
                        dout => plaintext
                );

        -- plaintext register enable signal, must be activated when the
        -- round_counter overflows to "00000". Since the output of the
        -- round_counter is a signal, the value read from it is one cycle behind.
        -- So the round_counter is found to be "00000", during the first round of
        -- the next decryption cycle. So we need 31 cycles for the actual decryption
        -- + 1 cycle to get the decrypted plaintext on the plaintext output bus
        with current_round_num select
                plain_enable <= '1' when "00000",
                '0' when others;

        -- when round_counter overflows to "11111", we are finished
        -- so raise the finished flag, indicating that the contents of
        -- the plaintext output are valid and correspond to the 
        -- decrypted plaintext. Compare the round_counter to "00001" and not to
        -- "00000" as in the select statement above, in order to give the ciphertext
        -- register, the necessary cycle to pass the ciphertext from its input to its 
        -- output
        with current_round_num select
                ready <= '1' when "11111",
                '0' when others;
        -- small issue though.. the ready flag is also raised during the first encryption
        -- process' second cycle (counter = 000001)
end structural;