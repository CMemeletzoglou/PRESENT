library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.key_length_pack.all;

entity present_enc_tb is
end;

architecture bench of present_enc_tb is

        component present_enc
                port (
                        clk           : in std_logic;
                        rst           : in std_logic;
                        ena           : in std_logic;
                        plaintext     : in std_logic_vector(63 downto 0);
                        key           : in std_logic_vector(KEY_LENGTH - 1 downto 0);
                        ciphertext    : out std_logic_vector(63 downto 0);
                        finished_flag : out std_logic
                );
        end component;

        -- Clock period
        constant clk_period : time := 2 ns;
        -- Generics

        -- Ports
        signal clk           : std_logic;
        signal rst           : std_logic;
        signal ena           : std_logic;
        signal plaintext     : std_logic_vector(63 downto 0);
        signal key           : std_logic_vector(KEY_LENGTH - 1 downto 0);
        signal ciphertext    : std_logic_vector(63 downto 0);
        signal finished_flag : std_logic;

begin
        present_enc_inst : present_enc
        port map(
                clk           => clk,
                rst           => rst,
                ena           => ena,
                plaintext     => plaintext,
                key           => key,
                ciphertext    => ciphertext,
                finished_flag => finished_flag
        );

        clk_process : process
        begin
                clk <= '1';
                wait for clk_period/2;
                clk <= '0';
                wait for clk_period/2;
        end process clk_process;

        stimuli_gen : process begin
                if (KEY_LENGTH = 80) then
                        -------------------------------------------------
                        ------------- TEST VECTOR 1 ---------------------
                        -------------------------------------------------
                        rst <= '1', '0' after clk_period;
                        ena <= '0',  '1' after clk_period;

                        -- expected ciphertext is 0x5579C1387B228445
                        plaintext <= x"0000_0000_0000_0000";
                        key <= x"0000_0000_0000_0000_0000";

                        -------------------------------------------------
                        ------------- TEST VECTOR 2 ---------------------
                        -------------------------------------------------
                        wait for (34 * clk_period);
                        rst <= '1', '0' after clk_period;
                        ena <= '0', '1' after clk_period;

                        -- expected ciphertext is 0xE72C46C0F5945049
                        plaintext <= x"0000_0000_0000_0000";
                        key <= x"FFFF_FFFF_FFFF_FFFF_FFFF";

                        -------------------------------------------------
                        ------------- TEST VECTOR 3 ---------------------
                        -------------------------------------------------
                        wait for (34 * clk_period);
                        rst <= '1', '0' after clk_period;
                        ena <= '0', '1' after clk_period;

                        -- expected ciphertext is 0xA112FFC72F68417B
                        plaintext <= x"FFFF_FFFF_FFFF_FFFF";
                        key <= x"0000_0000_0000_0000_0000";

                        -------------------------------------------------
                        ------------- TEST VECTOR 4 ---------------------
                        -------------------------------------------------
                        wait for (34 * clk_period);
                        rst <= '1', '0' after clk_period;
                        ena <= '0', '1' after clk_period;

                        -- expected ciphertext is 0x3333DCD3213210D2
                        plaintext <= x"FFFF_FFFF_FFFF_FFFF";
                        key <= x"FFFF_FFFF_FFFF_FFFF_FFFF";
                
                        wait; -- end test vector application

                elsif (KEY_LENGTH = 128) then
                        -------------------------------------------------
                        ------------- TEST VECTOR 1 ---------------------
                        -------------------------------------------------
                        rst <= '1', '0' after clk_period;
                        ena <= '0',  '1' after clk_period;

                        -- expected ciphertext is 0x96db702a2e6900af
                        plaintext <= x"0000_0000_0000_0000";
                        key <= x"0000_0000_0000_0000_0000_0000_0000_0000";

                        -------------------------------------------------
                        ------------- TEST VECTOR 2 ---------------------
                        -------------------------------------------------                   
                        wait for (34 * clk_period);
                        rst <= '1', '0' after clk_period;
                        ena <= '0', '1' after clk_period;

                        -- expected ciphertext is 0x13238c710272a5d8
                        plaintext <= x"0000_0000_0000_0000";
                        key <= x"FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF";


                        -------------------------------------------------
                        ------------- TEST VECTOR 3 ---------------------
                        -------------------------------------------------                       
                        wait for (34 * clk_period);
                        rst <= '1', '0' after clk_period;
                        ena <= '0', '1' after clk_period;

                        -- expected ciphertext is 0x3c6019e5e5edd563
                        plaintext <= x"FFFF_FFFF_FFFF_FFFF";
                        key <= x"0000_0000_0000_0000_0000_0000_0000_0000";


                        -------------------------------------------------
                        ------------- TEST VECTOR 4 ---------------------
                        -------------------------------------------------  
                        wait for (34 * clk_period);
                        rst <= '1', '0' after clk_period;
                        ena <= '0', '1' after clk_period;

                        -- expected ciphertext is 0x628d9fbd4218e5b4
                        plaintext <= x"FFFF_FFFF_FFFF_FFFF";
                        key <= x"FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF";


                        wait; -- end test vector application
                end if;
        end process;
end;