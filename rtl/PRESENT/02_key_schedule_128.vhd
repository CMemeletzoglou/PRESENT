library ieee;
use ieee.std_logic_1164.all;

entity key_schedule_128 is
        port (
                clk               : in std_logic;
                rst               : in std_logic;
                ena               : in std_logic;
                key_load_ena      : in std_logic;
                input_key         : in std_logic_vector(127 downto 0);
                round_counter_val : in std_logic_vector(4 downto 0);
                output_key        : out std_logic_vector(127 downto 0)
        );
end entity;

architecture structural of key_schedule_128 is
        signal  mux_sel : std_logic;

        signal  shifted_vec,
                tmp,
                reg_out,
                mux_out,
                key_mux_out : std_logic_vector(127 downto 0);
begin
        key_sched_input_mux : entity work.mux
                generic map(
                        DATA_WIDTH => 128
                )
                port map(
                        input_A => reg_out,
                        input_B => input_key,                        
                        sel     => key_load_ena,
                        mux_out => mux_out
                );

        shifted_vec <= mux_out(66 downto 0) & mux_out(127 downto 67);

        sbox_1 : entity work.sbox
                port map(
                        data_in  => shifted_vec(127 downto 124),
                        data_out => tmp(127 downto 124)
                );

        sbox_2 : entity work.sbox
                port map(
                        data_in  => shifted_vec(123 downto 120),
                        data_out => tmp(123 downto 120)
                );

        tmp(66 downto 62)  <= shifted_vec(66 downto 62) xor round_counter_val;
        tmp(119 downto 67) <= shifted_vec(119 downto 67);
        tmp(61 downto 0)   <= shifted_vec(61 downto 0);

        output_mux : entity work.mux
                generic map(
                        DATA_WIDTH => 128
                )
                port map(
                        input_A => tmp,
                        input_B => input_key,
                        sel     => key_load_ena,
                        mux_out => key_mux_out
                );

        output_reg : entity work.reg
                generic map(
                        DATA_WIDTH => 128
                )
                port map(
                        clk  => clk,
                        rst  => rst,
                        ena  => ena,
                        din  => key_mux_out,
                        dout => reg_out
                );
        output_key <= reg_out;
end architecture;