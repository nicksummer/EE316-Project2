LIBRARY ieee;
USE ieee.std_logic_1164.all;
	
use IEEE.NUMERIC_STD.ALL;
--	use IEEE.STD_LOGIC_ARITH;
--	use IEEE.STD_LOGIC_UNSIGNED.ALL;	

entity LCD_Parallel is
	GENERIC (
		CONSTANT cnt_max : integer := 208333); 
		port (
		reset_n				: in std_logic; 
		clk				    : in std_logic;
		ena                 : in std_logic; 
		busy                : out std_logic;
		en                  : out std_logic);
		
end LCD_Parallel;

architecture state_machine of LCD_Parallel is

type stateType is (enlow, enhigh, enlow2);
signal state   : stateType;
signal bit_cnt : integer;
signal data	   : std_logic_vector(7 downto 0);
signal clk_cnt : integer range 0 to cnt_max;
signal clk_en  : std_logic;
signal MUX_OUT : std_logic_vector(7 downto 0);



BEGIN

	
clk_en_inst: process(clk)  -- Gives the 5/3 ms enable
	begin
	if rising_edge(clk) then
		if (clk_cnt = cnt_max) then
			clk_cnt <= 0;
			clk_en <= '1';
		else
			clk_cnt <= clk_cnt + 1;
			clk_en <= '0';
		end if;
	end if;
end process;


process(clk, reset_n)
begin
	if reset_n = '0' then 
	state <= enlow;
	busy <= '1';
	
	elsif rising_edge(clk) and clk_en = '1' then
	
	case state is 
		when enlow => 
		       
		        en <= '0';
			    busy <= '0';
			if clk_en = '1' and ena = '1'then
				state <= enhigh;
				en <= '1';
		    else
		        state <= enlow;
			end if;
			
		when enhigh =>
			en <= '1';
			busy <= '1';
			
			if clk_en = '1' then
				state <= enlow2;
		        en <= '0';
		    else
		        state <= enhigh;
			end if;
			
		when enlow2 =>
			en <= '0';
			busy<='1';
			if clk_en = '1' then
				state <= enlow;
				busy <= '0';
		    else
		        state <= enlow2;
		        
			end if;
		
		end case;
	end if;
end process;
			
end state_machine;			
			
			
			
			
