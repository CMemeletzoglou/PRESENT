library ieee;
use ieee.std_logic_1164.all;

entity key_schedule_80 is
        port (
                clk           : in std_logic; -- new signal 
                rst           : in std_logic; -- new signal 
                ena           : in std_logic;
                input_key     : in std_logic_vector(79 downto 0);
                round_counter : in std_logic_vector(4 downto 0);
                output_key    : out std_logic_vector(79 downto 0)

        );
end entity key_schedule_80;

architecture structural of key_schedule_80 is
        signal  mux_sel : std_logic;

        signal  shifted_vec,
                tmp,
                reg_out,
                mux_out,
                key_mux_out : std_logic_vector(79 downto 0);
begin
        -- mux_sel <= '1' when (round_counter = "00001") else '0';
        mux_sel <= '1' when (round_counter = "00000" and ena = '1') else '0';

        -- pass feedback from output register or input key at the very first round
        key_sched_input_mux : entity work.mux
                generic map(
                        DATA_WIDTH => 80
                )
                port map(
                        input_A => reg_out,
                        input_B => input_key,
                        sel     => mux_sel,
                        mux_out => mux_out
                );

        shifted_vec <= mux_out(18 downto 0) & mux_out(79 downto 19);

        sbox : entity work.sbox
                port map(
                        data_in  => shifted_vec(79 downto 76),
                        data_out => tmp(79 downto 76)
                );

        tmp(19 downto 15) <= shifted_vec(19 downto 15) xor round_counter;
        tmp(75 downto 20) <= shifted_vec(75 downto 20);
        tmp(14 downto 0)  <= shifted_vec(14 downto 0);

        output_mux : entity work.mux
                generic map(
                        DATA_WIDTH => 80 -- 64 in the future?
                )
                port map(
                        input_A => tmp,
                        input_B => input_key,
                        sel     => mux_sel,
                        mux_out => key_mux_out
                );

        output_reg : entity work.reg
                generic map(
                        DATA_WIDTH => 80
                )
                port map(
                        clk  => clk,
                        rst  => rst,
                        ena  => ena,
                        din  => key_mux_out,
                        dout => reg_out
                );

        output_key <= reg_out;


        -- tri_buf : entity work.tristate_buffer
        --         generic map(
        --                 NUM_BITS => 80
        --         )
        --         port map(
        --                 inp  => tmp,
        --                 ena  => ena,
        --                 outp => output_key
        --         );
end architecture;