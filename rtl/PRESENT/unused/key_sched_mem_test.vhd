library ieee;
use ieee.std_logic_1164.all;

-- test file to test the interaction between the top-level key schedule module
-- and the round keys memory

entity key_sched_mem_test is
        port (
                clk        : in std_logic;
                rst        : in std_logic;
                ena        : in std_logic;
                mode       : in std_logic; -- 0 for 80-bit mode, and 1 for 128-bit mode
                input_key  : in std_logic_vector(127 downto 0);
                key_sched_out : out std_logic_vector(63 downto 0);
                curr_round : out std_logic_vector(4 downto 0);
                mem_output : out std_logic_vector(63 downto 0)                
        );
end entity key_sched_mem_test;

architecture rtl of key_sched_mem_test is
        signal round_num : std_logic_vector(4 downto 0);

        signal mem_out : std_logic_vector(63 downto 0);

        signal curr_key : std_logic_vector(63 downto 0);
begin
        key_sched_top : entity work.key_schedule_top
                port map(
                        clk => clk,
                        rst => rst,
                        ena => ena,
                        mode => mode,
                        input_key => input_key,
                        output_key => curr_key,
                        round_num => round_num
                );
        curr_round <= round_num;
        key_sched_out <= curr_key;

        round_keys_mem : entity work.key_mem
                port map(
                        clk => clk,
                        addr => round_num,
                        data_in => curr_key,
                        wr_en => ena,
                        data_out => mem_out
                );
        mem_output <= mem_out;
end architecture;