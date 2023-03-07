library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity present_dec_tb is
end;

architecture bench of present_dec_tb is

        component present_dec
                port (
                        clk               : in std_logic;
                        rst               : in std_logic;
                        ena               : in std_logic;
                        ciphertext        : in std_logic_vector(63 downto 0);
                        round_key         : in std_logic_vector(63 downto 0);
                        current_round_num : in std_logic_vector(4 downto 0);
                        plaintext         : out std_logic_vector(63 downto 0)
                );
        end component;

        -- Clock period
        constant clk_period : time := 2 ns;
        -- Generics

        -- Ports
        signal clk               : std_logic;
        signal rst               : std_logic;
        signal ena               : std_logic;
        signal ciphertext        : std_logic_vector(63 downto 0);
        signal round_key         : std_logic_vector(63 downto 0);
        signal current_round_num : std_logic_vector(4 downto 0);
        signal plaintext         : std_logic_vector(63 downto 0);

begin

        present_dec_inst : present_dec
        port map(
                clk               => clk,
                rst               => rst,
                ena               => ena,
                ciphertext        => ciphertext,
                round_key         => round_key,
                current_round_num => current_round_num,
                plaintext         => plaintext
        );

        clk_process : process
        begin
                clk <= '1';
                wait for clk_period/2;
                clk <= '0';
                wait for clk_period/2;
        end process clk_process;

        rst <= '1', '0' after clk_period;

        stimuli_proc : process begin
                wait until rst = '0';
                ena <= '1';
                ciphertext <= x"628d9fbd4218e5b4";
                current_round_num <= b"11111";

                wait for clk_period;

                round_key <= x"2c6fb5a30625328c";
                wait for clk_period;

                current_round_num <= b"11110";
                round_key <= x"a902bb14759f6def";
                wait for clk_period;

                current_round_num <= b"11101";
                round_key <= x"1bed68c1894ca2c3";
                wait for clk_period;

                current_round_num <= b"11100";
                round_key <= x"00aec51d67db7a07";
                wait for clk_period;

                current_round_num <= b"11011";
                round_key <= x"fb5a30625328b11a";
                wait for clk_period;

                current_round_num <= b"11010";
                round_key <= x"6bb14759f6de8005";
                wait for clk_period;

                current_round_num <= b"11001";
                round_key <= x"d68c1894ca2c4719";
                wait for clk_period;

                current_round_num <= b"11000";
                round_key <= x"ec51d67db7a000e3";
                wait for clk_period;

                current_round_num <= b"10111";
                round_key <= x"a30625328b11c7d4";
                wait for clk_period;

                current_round_num <= b"10110";
                round_key <= x"14759f6de8003963";
                wait for clk_period;

                current_round_num <= b"10101";
                round_key <= x"01894ca2c471f457";
                wait for clk_period;

                current_round_num <= b"10100";
                round_key <= x"1d67db7a000e59b2";
                wait for clk_period;

                current_round_num <= b"10011";
                round_key <= x"a25328b11c7d148f";
                wait for clk_period;

                current_round_num <= b"10010";
                round_key <= x"d9f6de8003966dfb";
                wait for clk_period;

                current_round_num <= b"10001";
                round_key <= x"d4ca2c471f4522fb";
                wait for clk_period;

                current_round_num <= b"10000";
                round_key <= x"3db7a000e59b7ffb";
                wait for clk_period;

                current_round_num <= b"01111";
                round_key <= x"328b11c7d148bffc";
                wait for clk_period;

                current_round_num <= b"01110";
                round_key <= x"ede8003966dffffc";
                wait for clk_period;

                current_round_num <= b"01101";
                round_key <= x"e2c471f4522ffffc";
                wait for clk_period;

                current_round_num <= b"01100";
                round_key <= x"fa000e59b7fffffc";
                wait for clk_period;

                current_round_num <= b"01011";
                round_key <= x"f11c7d148bfffffd";
                wait for clk_period;

                current_round_num <= b"01010";
                round_key <= x"8003966dfffffffd";
                wait for clk_period;

                current_round_num <= b"01001";
                round_key <= x"871f4522fffffffd";
                wait for clk_period;

                current_round_num <= b"01000";
                round_key <= x"40e59b7ffffffffd";
                wait for clk_period;

                current_round_num <= b"00111";
                round_key <= x"47d148bffffffffe";
                wait for clk_period;

                current_round_num <= b"00110";
                round_key <= x"7966dffffffffffe";
                wait for clk_period;

                current_round_num <= b"00101";
                round_key <= x"74522ffffffffffe";
                wait for clk_period;

                current_round_num <= b"00100";
                round_key <= x"19b7fffffffffffe";
                wait for clk_period;

                current_round_num <= b"00011";
                round_key <= x"148bffffffffffff";
                wait for clk_period;

                current_round_num <= b"00010";
                round_key <= x"2dffffffffffffff";
                wait for clk_period;

                current_round_num <= b"00001";
                round_key <= x"22ffffffffffffff";
                wait for clk_period;

                current_round_num <= b"00000";
                round_key <= x"ffffffffffffffff";
                wait for clk_period;

                
                
                wait;
        end process;

end;