library ieee;
use ieee.std_logic_1164.all;

library work;
use work.key_length_pack.all;

entity present_enc is      
        port (
                clk, rst, ena : in std_logic;
                plaintext     : in std_logic_vector(63 downto 0);
                key           : in std_logic_vector(KEY_LENGTH - 1 downto 0);
                ciphertext    : out std_logic_vector(63 downto 0);
                finished_flag : out std_logic
        );
end present_enc;

architecture structural of present_enc is
        signal  mux_sel,
                ciph_enable : std_logic;

        signal  current_round_num : std_logic_vector(4 downto 0);

        signal  state_reg_mux_out,
                state : std_logic_vector(63 downto 0);

        signal  sbox_layer_input,
                pbox_layer_input,
                pbox_layer_out,
                round_key : std_logic_vector(63 downto 0);

        signal  key_reg_out,
                key_reg_mux_out,
                key_schedule_out : std_logic_vector(KEY_LENGTH-1 downto 0);

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
                        input_A => pbox_layer_out,
                        input_B => plaintext,
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
        round_key <= key_reg_out(KEY_LENGTH-1 downto KEY_LENGTH-64);

        -- 64-bit xor to add current round key to state
        xor_64 : entity work.xor_n
                generic map(
                        DATA_WIDTH => BLOCK_SIZE
                )
                port map(
                        a => state,
                        b => round_key,
                        y => sbox_layer_input
                );

        -- S-Box layer (16 S-Boxes in parallel), the *confusion* layer
        sbox_layer : entity work.sbox_layer
                port map(
                        sbox_layer_in  => sbox_layer_input,
                        sbox_layer_out => pbox_layer_input
                );

        -- P-Box layer, the *diffusion* layer
        pbox_layer : entity work.pbox
                port map(
                        pbox_in  => pbox_layer_input,
                        pbox_out => pbox_layer_out
                );

        -- round counter, incremented by 1 at each network round
        round_counter : entity work.counter
                port map(
                        clk   => clk,
                        rst   => rst,
                        count => current_round_num
                );

        -- key schedule module, produces the new contents of the key register
        key_schedule : entity work.key_schedule
                port map(
                        input_key     => key_reg_out,
                        round_counter => current_round_num,
                        output_key    => key_schedule_out
                );
      
        -- 64-bit ciphertext register
        ciph_reg : entity work.reg
                generic map(
                        DATA_WIDTH => BLOCK_SIZE
                )
                port map(
                        clk  => clk,
                        rst  => rst,
                        ena  => ciph_enable,
                        din  => sbox_layer_input,
                        dout => ciphertext
                );
        
        -- ciphertext register enable signal, must be activated when the
        -- round_counter overflows to "00000". Since the output of the
        -- round_counter is a signal, the value read from it is one cycle behind.
        -- So the round_counter is found to be "00000", during the first round of
        -- the next encryption cycle. So we need 31 cycle for the actual encryption
        -- + 1 cycle to get the encrypted plaintext on the ciphertext output bus
        with current_round_num select
                ciph_enable <=  '1' when "00000",
                                '0' when others;

        -- when round_counter overflows to "00000", we are finished
        -- so raise the finished flag, indicating that the contents of
        -- the ciphertext output are valid and correspond to the 
        -- encrypted plaintext. Compare the round_counter to "00001" and not to
        -- "00000" as in the select statement above, in order to give the ciphertext
        -- register, the necessary cycle to pass the ciphertext from its input to its 
        -- output
        with current_round_num select
                finished_flag <= '1' when "00001",
                '0' when others;
end structural;