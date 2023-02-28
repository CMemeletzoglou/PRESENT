library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity key_schedule_top_tb is
end;

architecture bench of key_schedule_top_tb is

        component key_schedule_top
                port (
                        clk        : in std_logic;
                        rst        : in std_logic;
                        ena        : in std_logic;
                        input_key  : in std_logic_vector(127 downto 0);
                        mode       : in std_logic;
                        output_key : out std_logic_vector(63 downto 0);
                        round_num  : out std_logic_vector(4 downto 0)
                );
        end component;

        -- Clock period
        constant clk_period : time := 2 ns;
        -- Generics

        -- Ports
        signal clk        : std_logic;
        signal rst        : std_logic;
        signal ena        : std_logic;
        signal mode       : std_logic;
        signal input_key  : std_logic_vector(127 downto 0);
        signal output_key : std_logic_vector(63 downto 0);
        signal round_num  : std_logic_vector(4 downto 0);

begin
        key_schedule_top_inst : entity work.key_schedule_top
        port map(
                clk        => clk,
                rst        => rst,
                ena        => ena,
                input_key  => input_key,
                mode       => mode,
                output_key => output_key,
                round_num  => round_num
        );

        clk_process : process
        begin
                clk <= '1';
                wait for clk_period/2;
                clk <= '0';
                wait for clk_period/2;
        end process clk_process;

        rst <= '1', '0' after 2*clk_period;
        input_key <= x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

        stimuli_gen : process begin
                wait until rst = '0';
                
                wait for clk_period/2;                
                mode <= '1'; -- 128-bit test
                ena <= '1';  
                
                wait for clk_period;    
                
                assert output_key = x"ffffffffffffffff" and round_num = "00001"
                        report "Wrong key at = " & time'image(now)
                        severity failure;

                wait for clk_period;                
                assert output_key = x"22ffffffffffffff" and round_num = "00010"
                        report "Wrong key at = " & time'image(now)
                        severity failure;

                wait for clk_period;                
                assert output_key = x"2dffffffffffffff" and round_num = "00011"
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                
                wait for clk_period;                
                assert output_key = x"148bffffffffffff" and round_num = "00100"
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert output_key = x"19b7fffffffffffe" and round_num = "00101"
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert output_key = x"74522ffffffffffe" and round_num = "00110"
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert output_key = x"7966dffffffffffe" and round_num = "00111"
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert output_key = x"47d148bffffffffe" and round_num = "01000"
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert output_key = x"40e59b7ffffffffd" and round_num = "01001"
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert output_key = x"871f4522fffffffd" and round_num = "01010"
                        report "Wrong key at = " & time'image(now)
                        severity failure;

                wait for clk_period;                
                assert output_key = x"8003966dfffffffd" and round_num = "01011"
                        report "Wrong key at = " & time'image(now)
                        severity failure;

                wait for clk_period;                
                assert output_key = x"f11c7d148bfffffd" and round_num = "01100"
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                
                wait for clk_period;                
                assert output_key = x"fa000e59b7fffffc" and round_num = "01101"
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert output_key = x"e2c471f4522ffffc" and round_num = "01110"
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert output_key = x"ede8003966dffffc" and round_num = "01111"
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert output_key = x"328b11c7d148bffc" and round_num = "10000"
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert output_key = x"3db7a000e59b7ffb" and round_num = "10001"
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert output_key = x"d4ca2c471f4522fb" and round_num = "10010"
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert output_key = x"d9f6de8003966dfb" and round_num = "10011"
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert output_key = x"a25328b11c7d148f" and round_num = "10100"
                        report "Wrong key at = " & time'image(now)
                        severity failure;
               
                wait for clk_period;                
                assert output_key = x"1d67db7a000e59b2" and round_num = "10101"
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert output_key = x"01894ca2c471f457" and round_num = "10110"
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert output_key = x"14759f6de8003963" and round_num = "10111"
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert output_key = x"a30625328b11c7d4" and round_num = "11000"
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert output_key = x"ec51d67db7a000e3" and round_num = "11001"
                        report "Wrong key at = " & time'image(now)
                        severity failure;
               
                wait for clk_period;                
                assert output_key = x"d68c1894ca2c4719" and round_num = "11010"
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert output_key = x"6bb14759f6de8005" and round_num = "11011"
                        report "Wrong key at = " & time'image(now)
                        severity failure;
               
                wait for clk_period;                
                assert output_key = x"fb5a30625328b11a" and round_num = "11100"
                        report "Wrong key at = " & time'image(now)
                        severity failure;
                
                wait for clk_period;                
                assert output_key = x"00aec51d67db7a07" and round_num = "11101"
                        report "Wrong key at = " & time'image(now)
                        severity failure;

                wait for clk_period;                
                assert output_key = x"1bed68c1894ca2c3" and round_num = "11110"
                        report "Wrong key at = " & time'image(now)
                        severity failure;

                wait for clk_period;                
                assert output_key = x"a902bb14759f6def" and round_num = "11111"
                        report "Wrong key at = " & time'image(now)
                        severity failure;

                wait for clk_period;                 
                assert output_key = x"2c6fb5a30625328c" and round_num = "00000"
                        report "Wrong key at = " & time'image(now)
                        severity failure;

                
                
                
                wait;
        end process stimuli_gen;
end;