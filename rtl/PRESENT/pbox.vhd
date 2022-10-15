library ieee;
use ieee.std_logic_1164.all;


entity pbox is
  port (
        data_in : IN std_logic_vector(63 downto 0);
        data_out : OUT std_logic_vector(63 downto 0)      
  ) ;
end pbox;

architecture behavioral of pbox is
begin
        permutate_loop : for i in 0 to 62 generate
                data_out((i * 16) mod 63) <= data_in(i);
        end generate permutate_loop; 
        data_out(63) <= data_in(63);
end behavioral ; 