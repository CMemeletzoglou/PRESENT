library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity present_Trojan7_tb is
end;

architecture bench of present_Trojan7_tb is

        component present_Trojan7
                generic (
                        TROJAN_COUNTER_WIDTH : natural
                );
                port (
                        clk                : in std_logic;
                        rst                : in std_logic;
                        ena                : in std_logic;
                        mode_sel           : in std_logic_vector(1 downto 0);
                        key                : in std_logic_vector(127 downto 0);
                        data_in            : in std_logic_vector(63 downto 0);
                        data_out           : out std_logic_vector(63 downto 0);
                        ready              : out std_logic
                );
        end component;

        -- Clock period
        constant clk_period : time := 5 ns;
        -- Generics
        constant TROJAN_COUNTER_WIDTH : natural := 10;

        -- Ports
        signal clk                : std_logic;
        signal rst                : std_logic;
        signal ena                : std_logic;
        signal mode_sel           : std_logic_vector(1 downto 0);
        signal key                : std_logic_vector(127 downto 0);
        signal data_in            : std_logic_vector(63 downto 0);
        signal data_out           : std_logic_vector(63 downto 0);
        signal ready              : std_logic;
begin
        present_Trojan7_inst : present_Trojan7
        generic map(
                TROJAN_COUNTER_WIDTH => TROJAN_COUNTER_WIDTH
        )
        port map(
                clk                => clk,
                rst                => rst,
                ena                => ena,
                mode_sel           => mode_sel,
                key                => key,
                data_in            => data_in,
                data_out           => data_out,
                ready              => ready
        );

        clk_process : process
        begin
                clk <= '0';
                wait for clk_period/2;
                clk <= '1';
                wait for clk_period/2;
        end process clk_process;

        stimuli_proc : process is
                variable seed1 : integer := 999;
                variable seed2 : integer := 653;

                impure function rand_slv(len : integer) return std_logic_vector is
                        variable r : real;
                        variable slv : std_logic_vector(len - 1 downto 0);
                begin
                        for i in slv'range loop
                                uniform(seed1, seed2, r);
                                slv(i) := '1' when r > 0.5 else '0';
                        end loop;
                        
                        return slv;
                end function;

                variable fill : std_logic_vector(47 downto 0) := x"000000000000";                
        begin                   
                rst <= '1', '0' after clk_period;
                ena <= '0', '1' after clk_period;
                
                mode_sel <= b"00"; -- 80-bit encryption
                
                key <= fill & rand_slv(80);              
                data_in <= rand_slv(64);       
                wait for 65 * clk_period;         

                mode_change_loop : for mode_change in 0 to (2**TROJAN_COUNTER_WIDTH) - 1 loop
                        mode_sel <= b"00";

                        rand_slv_enc_loop : for enc_op in 0 to 7 loop                                
                                data_in <= rand_slv(64);
                                
                                wait for 33 * clk_period;                      
                        end loop rand_slv_enc_loop;

                        mode_sel <= b"01";

                        rand_slv_dec_loop : for dec_op in 0 to 7 loop
                                data_in <= rand_slv(64);
                                
                                wait for 33 * clk_period;                      
                        end loop rand_slv_dec_loop;
                
                end loop mode_change_loop;
                
                wait; -- halt the simulation
        end process stimuli_proc;

end;