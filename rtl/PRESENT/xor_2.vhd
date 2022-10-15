library ieee;
use ieee.std_logic_1164.all;

entity xor_2 is
	port (
		a, b : IN std_logic;
		y : OUT std_logic
	) ;
end xor_2;

architecture boolean_eq of xor_2 is
begin
	y <= a XOR b;
end boolean_eq ; 