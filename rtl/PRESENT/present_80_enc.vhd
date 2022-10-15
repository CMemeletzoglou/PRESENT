library ieee;
use ieee.std_logic_1164.all;

entity present_80_enc is
        port (
                clk, rst : IN std_logic;
                plaintext : IN std_logic_vector(63 downto 0);
                key : IN std_logic_vector(79 downto 0);
                cyphertext : OUT std_logic_vector(63 downto 0)
        ) ;
end present_80_enc;

architecture rtl of present_80_enc is
        signal state_reg_mux_out, state : std_logic_vector(63 downto 0);
        signal sbox_layer_input, pbox_layer_input, pbox_layer_out, round_key : std_logic_vector(63 downto 0);

        signal key_reg_out, key_reg_mux_out, key_schedule_out : std_logic_vector(79 downto 0);

        signal current_round_num : std_logic_vector(4 downto 0);

begin
        -- 64-bit mux which drives the state register
        state_reg_mux : entity work.mux
                generic map(
                        DATA_WIDTH => 64
                )
                port map(
                        input_A => pbox_layer_out,
                        input_B => plaintext,
                        sel => rst,
                        mux_out => state_reg_mux_out
                );

        -- 80-bit mux which drives the key register
        key_reg_mux : entity work.mux
                generic map(
                        DATA_WIDTH => 80
                )
                port map(
                        input_A => key_schedule_out,
                        input_B => key,
                        sel => rst,
                        mux_out => key_reg_mux_out
                );

        -- 64-bit state register
        state_reg : entity work.reg
                generic map(
                        DATA_WIDTH => 64
                )
                port map(
                        clk => clk,
                        rst => rst,
                        din => state_reg_mux_out,
                        dout => state
                );

        -- 80-bit key register, at each round it stores the current subkey
        key_reg : entity work.reg
                generic map(
                        DATA_WIDTH => 80
                )
                port map(
                        clk => clk,
                        rst => rst,
                        din => key_reg_mux_out,
                        dout => key_reg_out
                );
        
        -- current round key, it consists of the 64 leftmost bits of the key register
        round_key <= key_reg_out(79 downto 16);
        
        -- 64-bit xor to add current round key to state
        xor_64 : entity work.xor_n
                generic map(
                        DATA_WIDTH => 64
                )
                port map(
                        a => state,
                        b => round_key,
                        y => sbox_layer_input
                );
        
        cyphertext <= sbox_layer_input;

        -- S-Box layer (16 S-Boxes in parallel), the *confusion* layer
        sbox_layer : entity work.sbox_layer
                port map(
                        sbox_layer_in => sbox_layer_input,
                        sbox_layer_out => pbox_layer_input
                );
        
        -- P-Box layer, the *diffusion* layer
        pbox_layer : entity work.pbox 
                port map(
                        pbox_in => pbox_layer_input,
                        pbox_out => pbox_layer_out
                );

        -- round counter, incremented by 1 at each network round
        round_counter : entity work.counter
                port map(
                        clk => clk,
                        rst => rst,
                        ena => '1', -- change this, not good practice, maybe we don't need the ena signal at all
                        count => current_round_num
                );
        
        -- key schedule module, produces the new contents of the key register
        key_schedule : entity work.key_schedule
                port map(
                        input_key => key_reg_out,
                        round_counter => current_round_num,
                        output_key => key_schedule_out
                );
end rtl ; 