library ieee;
use ieee.std_logic_1164.all;

entity present_80_enc is
        generic (
                KEY_SIZE : natural := 80 -- leaves this as a generic, not fixed on  80
        );
        port (
                clk, rst, block_ena : in std_logic;
                plaintext     : in std_logic_vector(63 downto 0);
                key           : in std_logic_vector(KEY_SIZE - 1 downto 0);
                ciphertext    : out std_logic_vector(63 downto 0);
                finished_flag : out std_logic
        );
end present_80_enc;

architecture rtl of present_80_enc is
        signal  sel0,
                sel1,
                ciph_reg_enable : std_logic;

        signal  current_round_num : std_logic_vector(4 downto 0);

        signal  state_reg_mux_out,
                state : std_logic_vector(63 downto 0);

        signal  sbox_layer_input,
                pbox_layer_input,
                pbox_layer_out,
                round_key : std_logic_vector(63 downto 0);

        signal  key_reg_out,
                key_reg_mux_out,
                key_schedule_out : std_logic_vector(79 downto 0);

        constant BLOCK_SIZE : natural := 64;
begin
        sel0 <= rst AND '1';
        sel1 <= rst AND '1';

        -- 64-bit mux which drives the state register
        state_reg_mux : entity work.mux
                generic map(
                        DATA_WIDTH => BLOCK_SIZE
                )
                port map(
                        input_A => pbox_layer_out,
                        input_B => plaintext,
                        sel     => sel0,
                        mux_out => state_reg_mux_out
                );

        -- 80-bit mux which drives the key register
        key_reg_mux : entity work.mux
                generic map(
                        DATA_WIDTH => KEY_SIZE
                )
                port map(
                        input_A => key_schedule_out,
                        input_B => key,
                        sel     => sel1,
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
                        reg_ena  => block_ena,
                        din  => state_reg_mux_out,
                        dout => state
                );

        -- 80-bit key register, at each round it stores the current subkey
        key_reg : entity work.reg
                generic map(
                        DATA_WIDTH => KEY_SIZE
                )
                port map(
                        clk  => clk,
                        rst  => rst,
                        reg_ena  => block_ena,
                        din  => key_reg_mux_out,
                        dout => key_reg_out
                );

        -- current round key, it consists of the 64 leftmost bits of the key register
        round_key <= key_reg_out(79 downto 16);

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

        -- cyphertext <= sbox_layer_input;

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
                        ena   => '1', -- change this, not good practice, maybe we don't need the ena signal at all                        
                        count => current_round_num
                );

        -- key schedule module, produces the new contents of the key register
        key_schedule : entity work.key_schedule
                port map(
                        input_key     => key_reg_out,
                        round_counter => current_round_num,
                        output_key    => key_schedule_out
                );
                
        with current_round_num select
                        ciph_reg_enable <= '1' when "00000",
                        '0' when others;

        -- 64-bit ciphertext register
        ciph_reg : entity work.reg
                generic map(
                        DATA_WIDTH => BLOCK_SIZE
                )
                port map(
                        clk  => clk,
                        rst  => rst,
                        reg_ena  => ciph_reg_enable,
                        din  => sbox_layer_input,
                        dout => ciphertext
                );

        -- when round_counter overflows to "00000", we are finished
        with current_round_num select
                finished_flag <= '1' when "00000",
                'Z' when others;
end rtl;