library ieee;
use ieee.std_logic_1164.all;

entity key_schedule_top is
        port (
                input_key     : in std_logic_vector(127 downto 0);
                round_counter : in std_logic_vector(4 downto 0);
                ena           : in std_logic;
                mode          : in std_logic;
                output_key    : out std_logic_vector(127 downto 0)
        );
end entity key_schedule_top;

architecture structural of key_schedule_top is
        signal  ena_80bit,
                ena_128bit : std_logic;

        signal key_sched_80_out  : std_logic_vector(79 downto 0);
        signal key_sched_128_out : std_logic_vector(127 downto 0);

        signal key_out : std_logic_vector(127 downto 0);
begin
        ena_80bit <= '1' when (mode = '0' and ena = '1') else '0';
        ena_128bit <= NOT ena_80bit when (ena = '1') else '0';

        key_sched_80 : entity work.key_schedule_80
                port map(
                        input_key     => input_key(79 downto 0),
                        round_counter => round_counter,
                        ena           => ena_80bit,
                        output_key    => key_sched_80_out
                );

        key_sched_128 : entity work.key_schedule_128
                port map(
                        input_key     => input_key,
                        round_counter => round_counter,
                        ena           => ena_128bit,
                        output_key    => key_sched_128_out
                );

        tri_buf : entity work.tristate_buffer
                generic map(
                        NUM_BITS => 128
                )
                port map(
                        inp => key_out,
                        ena => ena,
                        outp => output_key
                );

        key_out <= "000000000000000000000000000000000000000000000000" & key_sched_80_out when (ena_80bit = '1')
                else key_sched_128_out when (ena_128bit = '1')
                else (others => 'Z');
end architecture;