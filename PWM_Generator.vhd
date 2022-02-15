library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
	entity PWM_Generator is
		port (
			CLK : in std_logic;
			reset_n : in std_logic;
			duty_cycle : in std_logic_vector(15 downto 0);
			duty_load : in std_logic;
			PWM_out : out std_logic
		);
end PWM_Generator;

architecture struct of PWM_Generator is 
signal counter : std_logic_vector(7 downto 0);
signal duty_reg : std_logic_vector(15 downto 0);

begin 

process(clk)
begin
	if(rising_edge(clk)) then
		if (reset_n = '0') then 
			counter <= (others => '0');
		else
			counter <= std_LOGIC_VECTOR(to_unsigned(to_integer(unsigned( counter )) + 1, 8));
		end if;
	end if;
end process;

process(clk)
begin
	if(rising_edge(clk)) then 
		if(reset_n = '0') then 
			duty_reg <= (others => '0');
		elsif(duty_load = '1') then 
			duty_reg <= duty_cycle;		
		end if;	
	end if;
end process;
process(clk)
begin
	if(rising_edge(clk)) then 
		if(reset_n = '0') then	
			pwm_out <= '0';
		elsif(counter < duty_reg) then
			pwm_out <= '1';
		else 
			pwm_out <= '0';
		end if;
	end if;
end process;
end struct;