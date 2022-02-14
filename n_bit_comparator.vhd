library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
	entity n_bit_comparator is
	generic(N: integer := 8);
		port (
			CLK : in std_logic;
			a   : in std_logic_vector(N-1 downto 0);
			b   : in std_logic_vector(N-1 downto 0);
			C   : out std_logic;
			
		);
end n_bit_comparator;

architecture struct of n_bit_counter is 
signal compare : std_logic_vector(7 downto 0);

begin 

process(a, b)
begin 

	if (a = b) then 
		c <= '1';
	else 
		c <= '0';
	end if;
end process;

end struct;