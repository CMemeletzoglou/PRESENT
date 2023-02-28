library ieee;
use ieee.std_logic_1164.all;

entity present_dec is
        port (
                clk               : in std_logic;
                rst               : in std_logic;
                ena               : in std_logic;
                ciphertext        : in std_logic_vector(63 downto 0);
                round_key         : in std_logic_vector(63 downto 0);
                current_round_num : out std_logic_vector(4 downto 0);
                plaintext         : out std_logic_vector(63 downto 0);
                ready             : out std_logic
        );
end present_dec;

architecture structural of present_dec is
        constant BLOCK_SIZE : natural := 64;

        signal  mux_sel,
                plain_enable : std_logic;

        signal  state_reg_mux_out,
                state : std_logic_vector(BLOCK_SIZE - 1 downto 0);

        signal  inv_pbox_layer_input,
                inv_sbox_layer_input,
                inv_sbox_layer_out : std_logic_vector(BLOCK_SIZE - 1 downto 0);

        signal key_reg_out : std_logic_vector(63 downto 0);
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
        -- 64-bit key register, it stores the current round key retrieved from the round keys memory
        -- TODO : unecessary (??)
        key_reg : entity work.reg
                generic map(
                        DATA_WIDTH => 64
                )
                port map(
                        clk  => clk,
                        rst  => rst,
                        ena  => ena,
                        din  => round_key,
                        dout => key_reg_out
                );

        -- 64-bit xor to add current round key to state
        xor_64 : entity work.xor_n
                generic map(
                        DATA_WIDTH => BLOCK_SIZE
                )
                port map(
                        a => state,
                        b => key_reg_out,
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
                generic map(
                        COUNTER_WIDTH => 5
                )
                port map(
                        clk    => clk,
                        rst    => rst,
                        ena    => ena,
                        updown => '1', -- count downwards
                        count  => current_round_num
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
        -- small issue though.. the ready flag is also raised during the first decryption
        -- process' second cycle (counter = 000001)
end structural;