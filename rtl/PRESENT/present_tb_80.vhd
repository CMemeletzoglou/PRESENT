library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity present_tb_80 is
end;

architecture bench of present_tb_80 is
        component present
                port (
                        clk      : in std_logic;
                        rst      : in std_logic;
                        ena      : in std_logic;
                        mode_sel : in std_logic_vector(1 downto 0);
                        key      : in std_logic_vector(127 downto 0);
                        data_in  : in std_logic_vector(63 downto 0);
                        data_out : out std_logic_vector(63 downto 0);
                        ready    : out std_logic
                );
        end component;

        -- Clock period
        constant clk_period : time := 5 ns;
        -- Generics

        -- Ports
        signal clk      : std_logic;
        signal rst      : std_logic;
        signal ena      : std_logic;
        signal mode_sel : std_logic_vector(1 downto 0);
        signal key      : std_logic_vector(127 downto 0);
        signal data_in  : std_logic_vector(63 downto 0);
        signal data_out : std_logic_vector(63 downto 0);
        signal ready    : std_logic;
begin
        present_inst : present
        port map(
                clk      => clk,
                rst      => rst,
                ena      => ena,
                mode_sel => mode_sel,
                key      => key,
                data_in  => data_in,
                data_out => data_out,
                ready    => ready
        );

        clk_process : process
        begin
                clk <= '1';
                wait for clk_period/2;
                clk <= '0';
                wait for clk_period/2;
        end process clk_process;

        stimuli_proc : process begin
                rst <= '1', '0' after clk_period;
                ena <= '0', '1' after clk_period;

                mode_sel <= b"00"; -- 80-bit encryption
                key      <= x"00000000000000000000000000000000";
                data_in  <= x"FFFFFFFFFFFFFFFF";

                -- wait for 66 clock cycles (1 cycle to transition into state KEY_GEN, 
                -- 32 for KEY_GEN, 32 for CRYPTO_OP and 1 for the output register to store the data)
                wait for 66 * clk_period;

                -- input new data for encryption
                data_in <= x"0000000000000000";

                -- wait one clock cycle for the data to appear on the bus, otherwise the bus' contents
                -- are compare to the expected value at the rising edge of the same cycle as the one
                -- that the ready flag goes high and thus the data are available
                wait for clk_period;

                assert data_out = x"A112FFC72F68417B"
                report "Encryption failed for input data=0xFFFFFFFFFFFFFFFF and key = 0x00000000000000000000000000000000 \\ @ " & time'image(now)
                        severity failure;

                wait for 32 * clk_period;

                -- switch mode to decryption and the previously encrypted ciphertext
                mode_sel <= "01";
                data_in  <= x"A112FFC72F68417B";

                wait for clk_period;

                -- after 32 cycles they encrypted data are available, however in order for the assertion to succeed
                -- we need to wait for one more clock cycle, as explained above
                assert data_out = x"5579C1387B228445"
                report "Encryption failed for input data=0x0000000000000000 and key = 0x00000000000000000000000000000000 \\ @ " & time'image(now)
                        severity failure;

                wait for 32 * clk_period;

                data_in <= x"5579C1387B228445";

                wait for clk_period;

                assert data_out = x"FFFFFFFFFFFFFFFF"
                report "Decryption failed for input data=0xA112FFC72F68417B and key = 0x00000000000000000000000000000000 \\ @ " & time'image(now)
                        severity failure;

                wait for 33 * clk_period;

                assert data_out = x"0000000000000000"
                report "Decryption failed for input data=0x5579C1387B228445 and key = 0x00000000000000000000000000000000 \\ @ " & time'image(now)
                        severity failure;

                --------------------------------------------------------------------------------------
                ----------------------- do the same as above for key 0xFFFF...FFFF -------------------
                --------------------------------------------------------------------------------------
                rst      <= '1', '0' after clk_period;
                ena      <= '0', '1' after clk_period;
                mode_sel <= b"00"; -- 80-bit encryption 
                data_in  <= x"FFFFFFFFFFFFFFFF";
                key      <= x"000000000000FFFFFFFFFFFFFFFFFFFF"; -- all 'F' key as 128 bits

                wait for 66 * clk_period;

                data_in <= x"0000000000000000";

                wait for clk_period;

                assert data_out = x"3333DCD3213210D2"
                report "Encryption failed for input data=0xFFFFFFFFFFFFFFFF and key=0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF @ " & time'image(now)
                        severity failure;

                wait for 32 * clk_period;

                mode_sel <= b"01"; -- 80-bit decryption
                data_in  <= x"3333DCD3213210D2";

                wait for clk_period;

                assert data_out = x"E72C46C0F5945049"
                report "Encryption failed for input data=0x0000000000000000 and key=0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF @ " & time'image(now)
                        severity failure;

                wait for 32 * clk_period;
                data_in <= x"E72C46C0F5945049";

                wait for clk_period;

                assert data_out = x"FFFFFFFFFFFFFFFF"
                report "Decryption failed for input data=0x3333DCD3213210D2 and key=0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF @ " & time'image(now)
                        severity failure;

                wait for 33 * clk_period;

                assert data_out = x"0000000000000000"
                report "Decryption failed for input data=0xE72C46C0F5945049 and key=0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF @ " & time'image(now)
                        severity failure;

                wait; -- wait forever, thus halting the simulation
        end process;
end;