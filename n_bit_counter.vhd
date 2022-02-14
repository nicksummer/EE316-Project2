library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
	entity n_bit_counter is
	generic(N: integer := 8);
		port (
			CLK : in std_logic;
			reset_n : in std_logic;
			clear : in std_logic;
			load : in std_logic;
			en : in std_logic;
			A  : in std_logic_vector(N-1 downto 0);
			q  : out std_logic_vector(N-1 downto 0)
			
		);
end n_bit_counter;

architecture struct of n_bit_counter is 
signal reg : unsigned(n-1 downto 0);
signal next_reg : unsigned(n-1 downto 0);

begin 

process(CLK, reset_n)
begin
	if(reset_n = '1') then
		reg <= (others => '0');	
	
	elsif(rising_edge(CLK)) then 
		reg <= next_reg;
end if;
end process;

next_reg <= (others => '0') when clear = '1' else
				unsigned(A) when load = '1' else
				reg +1 		when en ='1' else
				reg;
q <= std_logic_vector(reg);
end struct;