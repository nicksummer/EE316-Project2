library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity seven_seg_controller is
	port (
	 iClk  : in STD_LOGIC;
    iData : in STD_LOGIC_VECTOR(3 downto 0);
	 oData : out STD_LOGIC_VECTOR(6 downto 0)   -- a...g for 10s digit, then a...g for 1s digit
    );
end seven_seg_controller;

architecture Structural of seven_seg_controller is
begin                                          

	process(iData)
	begin
	case iData is
	 when "0000" => oData <= "1000000"; -- "0"     --binary outputs are g...a on the 7seg displays
	 when "0001" => oData <= "1111001"; -- "1" 
	 when "0010" => oData <= "0100100"; -- "2" 
	 when "0011" => oData <= "0110000"; -- "3" 
	 when "0100" => oData <= "0011001"; -- "4" 
	 when "0101" => oData <= "0010010"; -- "5" 
	 when "0110" => oData <= "0000010"; -- "6" 
	 when "0111" => oData <= "1111000"; -- "7" 
	 when "1000" => oData <= "0000000"; -- "8"    
	 when "1001" => oData <= "0010000"; -- "9" 
	 when "1010" => oData <= "0001000"; -- A   
	 when "1011" => oData <= "0000011"; -- b   
	 when "1100" => oData <= "1000110"; -- C   
	 when "1101" => oData <= "0100001"; -- d	 
	 when "1110" => oData <= "0000110"; -- E   
	 when "1111" => oData <= "0001110"; -- F
	 when others => oData <= "0000000"; -- Dumb case
	 end case;
 
	end process;
		
		
end Structural;
		
		
		
	
	
	
		
