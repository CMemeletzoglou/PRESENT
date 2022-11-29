library ieee;
use ieee.std_logic_1164.all;

entity key_schedule_top is
        port (
                clk        : in std_logic;
                rst        : in std_logic;
                ena        : in std_logic;
                input_key  : in std_logic_vector(127 downto 0);
                mode       : in std_logic;
                output_key : out std_logic_vector(63 downto 0); -- output: round keys
                round_num  : out std_logic_vector(4 downto 0)
        );
end entity key_schedule_top;

architecture structural of key_schedule_top is
        signal  ena_80bit,
                ena_128bit : std_logic;

        signal  current_round_num : std_logic_vector(4 downto 0);

        signal  key_sched_80_out : std_logic_vector(79 downto 0);

        signal  key_sched_128_out : std_logic_vector(127 downto 0);

        signal  round_key_mux_out : std_logic_vector(63 downto 0);
begin
        ena_80bit  <= '1' when (mode = '0' and ena = '1') else '0';
        ena_128bit <= '0' xor (not ena_80bit and ena);

        round_counter : entity work.counter
                generic map(
                        COUNTER_WIDTH => 5
                )
                port map(
                        clk    => clk,
                        rst    => rst,
                        updown => '0',
                        count  => current_round_num
                );

        key_sched_80 : entity work.key_schedule_80
                port map(
                        clk           => clk,
                        rst           => rst,
                        ena           => ena_80bit,
                        input_key     => input_key(79 downto 0),
                        round_counter => current_round_num,
                        output_key    => key_sched_80_out
                );

        key_sched_128 : entity work.key_schedule_128
                port map(
                        clk           => clk,
                        rst           => rst,
                        ena           => ena_128bit,
                        input_key     => input_key,
                        round_counter => current_round_num,
                        output_key    => key_sched_128_out
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

        output_key_tri_buf : entity work.tristate_buffer
                generic map(
                        NUM_BITS => 64
                )
                port map(
                        inp  => round_key_mux_out,
                        ena  => (ena_80bit or ena_128bit),
                        outp => output_key
                );
         round_num <= current_round_num;
end architecture;