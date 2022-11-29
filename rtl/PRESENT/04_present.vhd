library ieee;
use ieee.std_logic_1164.all;

entity present is
        port (
                clk      : in std_logic;
                rst      : in std_logic;
                ena      : in std_logic;
                key_ena  : in std_logic;
                mode_sel : in std_logic_vector(1 downto 0);
                key      : in std_logic_vector(127 downto 0);
                data_in  : in std_logic_vector(63 downto 0);
                data_out : out std_logic_vector(63 downto 0);
                ready    : out std_logic
        );
end entity present;

architecture rtl of present is
        signal  enc_ena,
                dec_ena : std_logic;

        -- signal enc_dp_out : std_logic_vector(63 downto 0);

        signal key_sched_out : std_logic_vector(127 downto 0);

        signal current_round : std_logic_vector(4 downto 0);

        signal key_mem_out : std_logic_vector(63 downto 0);
begin
        -- mode_sel(1) = 1 -> 128-bit key, 0 -> 80-bit key
        -- mode_sel(0) = 1 -> Decrypt, 0 -> Encrypt

        enc_ena <= NOT mode_sel(0);
        dec_ena <= mode_sel(0);

        -- the encryption and decryption units must be modified
        -- They don't need to contain an embedded key schedule unit,
        -- they will just read the round keys from the memory.
        -- 
        -- Therefore, their interface must change.. 
        -- They must be configured to accept a 128 bit key input vector
        -- and use the lowest 80 bits if needed, in respect to the value
        -- of mode_sel(1), which also needs to be passed to them as
        -- a 'mode' std_logic signal
        enc_dp : entity work.present_enc
                port map(
                        clk => clk,
                        rst => rst,
                        ena => enc_ena,
                        plaintext => data_in,
                        key => key,
                        ciphertext => data_out,
                        ready => ready
                );

        dec_dp : entity work.present_dec
                port map(
                        clk => clk,
                        rst => rst,
                        ena => dec_ena,
                        ciphertext => data_in,
                        key => key,
                        plaintext => data_out,
                        ready => ready
                );

        key_sched : entity work.key_schedule_top
                port map(
                        clk => clk,
                        rst => rst, 
                        ena => key_ena,
                        input_key => key,
                        mode => mode_sel(1),
                        output_key => key_sched_out,
                        round_num => current_round
                );

        round_key_mem : entity work.key_mem
                port map(
                        clk => clk,
                        addr => current_round,
                        data_in => key_sched_out,
                        wr_en => '1', -- always?
                        data_out => key_mem_out
                );
		




end architecture;