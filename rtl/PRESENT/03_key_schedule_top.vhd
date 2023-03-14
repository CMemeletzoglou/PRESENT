library ieee;
use ieee.std_logic_1164.all;

entity key_schedule_top is
        port (
                clk               : in std_logic;
                rst               : in std_logic;
                ena               : in std_logic;                
                mode              : in std_logic; -- 0 for 80-bit mode, and 1 for 128-bit mode
                round_counter_val : in std_logic_vector(4 downto 0);
                input_key         : in std_logic_vector(127 downto 0);
                output_key        : out std_logic_vector(63 downto 0) -- output: round keys
        );
end entity key_schedule_top;

architecture structural of key_schedule_top is
        signal  ena_80bit,
                ena_128bit,              
                key_load_ena_80bit,
                key_load_ena_128bit,
                tristate_buf_ena : std_logic;        

        signal  key_sched_80_out : std_logic_vector(79 downto 0);

        signal  key_sched_128_out : std_logic_vector(127 downto 0);

        signal  round_key_mux_out : std_logic_vector(63 downto 0);
begin
        ena_80bit  <= '1' when (mode = '0' and ena = '1') else '0';        
        ena_128bit <= not ena_80bit and ena;

        -- pass feedback from output register or input key at the very first round, for the
        -- key schedule submodule corresponding to the selected key length (i.e. mode).
        key_load_ena_80bit <= '1' when (round_counter_val = "00000" and ena_80bit = '1') else '0';
        key_load_ena_128bit <= '1' when (round_counter_val = "00000" and ena_128bit = '1') else '0';

        key_sched_80 : entity work.key_schedule_80
                port map(
                        clk               => clk,
                        rst               => rst,
                        ena               => ena_80bit,
                        key_load_ena      => key_load_ena_80bit,
                        input_key         => input_key(79 downto 0),
                        round_counter_val => round_counter_val,
                        output_key        => key_sched_80_out
                );

        key_sched_128 : entity work.key_schedule_128
                port map(
                        clk               => clk,
                        rst               => rst,
                        ena               => ena_128bit,
                        key_load_ena      => key_load_ena_128bit,
                        input_key         => input_key,
                        round_counter_val => round_counter_val,
                        output_key        => key_sched_128_out
                );

        output_round_key_mux : entity work.mux
                generic map(
                        DATA_WIDTH => 64
                )
                port map(
                        input_A => key_sched_128_out(127 downto 64),
                        input_B => key_sched_80_out(79 downto 16),
                        sel     => ena_80bit,
                        mux_out => round_key_mux_out
                );

        tristate_buf_ena <= ena_80bit or ena_128bit;

        output_key_tri_buf : entity work.tristate_buffer
                generic map(
                        NUM_BITS => 64
                )
                port map(
                        inp  => round_key_mux_out,
                        ena  => tristate_buf_ena,
                        outp => output_key
                );
end architecture;