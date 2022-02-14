library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
	entity n_bit_reg is
		generic(N: integer := 8);
		port (
			CLK : in std_logic;
			reset_n : in std_logic ;
			xin : in std_logic_vector(N-1 downto 0);
			load: in std_logic;
			y   : out std_logic_vector(N-1 downto 0)
		);
end n_bit_reg;

architecture struct of n_bit_reg is

 
begin
process(CLK, reset_n)
begin
if(rising_edge(CLK)) then 
	if (reset_n = '1') then
		y <= (others=> '0');
	else
		y <= xin;
	end if;
end if;
end process;


end struct;