library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- single port RAM
entity key_mem is
        port (
                clk      : in std_logic;
                addr     : in std_logic_vector(4 downto 0);
                data_in  : in std_logic_vector(63 downto 0);
                ena      : in std_logic;
                wr_ena   : in std_logic;
                data_out : out std_logic_vector(63 downto 0)
        );
end entity key_mem;

architecture behavioral of key_mem is
        subtype ROUND_KEY_T is std_logic_vector(63 downto 0);
        type ROUND_KEY_MEM is array (0 to 31) of ROUND_KEY_T;
        signal ram_block : ROUND_KEY_MEM;

        -- synthesis attribute to make sure that the Xilinx Synthesis Tool,
        -- infers a Distributed RAM (i.e. a LUTRAM).
        attribute ram_style              : string;
        attribute ram_style of ram_block : signal is "distributed";
begin
        -- write-first read/write synchronization mode ram (infers a block RAM). During a write operation, the data_out
        -- bus contains the data being written on the indexed address.
        -- Only the clock signal should be on the sensitivity list, hence all read and writes are synchronous operations
        --         process (clk)        
        --         begin
        --                 if rising_edge(clk) then
        --                         if (ena = '1') then
        --                                 if (wr_ena = '1') then
        --                                         ram_block(to_integer(unsigned(addr))) <= data_in; -- write operation
        --                                          data_out                              <= data_in; -- pass the data being written to the output (write-first)

        -- --                                        report "mem key in = " & to_hstring(data_in) & "  at time = " & time'image(now);

        --                                 else
        --                                         data_out <= ram_block(to_integer(unsigned(addr))); -- read operation if wr_ena = '0'
        --                                 end if;
        --                         end if;
        --                 end if;
        --         end process;

        process (clk)
        begin
                if rising_edge(clk) then
                        if (ena = '1') then
                                if (wr_ena = '1') then -- write operation
                                        ram_block(to_integer(unsigned(addr))) <= data_in;
                                end if;
                        end if;
                end if;
        end process;

        -- the contents of the memory address indicated by the address bus' value
        -- must always appear on the output data bus        
        data_out <= ram_block(to_integer(unsigned(addr))); -- asynchronous read -> infers distributed RAM
end architecture;