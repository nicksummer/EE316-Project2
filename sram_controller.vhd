library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Common.all;


entity sram_controller is

   port(
		iClk		: in  std_logic;
      iData    : in  std_logic_vector(15 downto 0);
      iAddress : in  std_logic_vector(19 downto 0);
      iRst     : in  std_logic;
		iRW      : in  std_logic;
		iTrigger : in  std_logic;
      oReady   : out std_logic;
		oData    : out std_logic_vector(15 downto 0);
		oAddress : out std_logic_vector(19 downto 0);
		oCE      : out std_logic;
		oUB      : out std_logic;
		oLB      : out std_logic;
		oWE      : out std_logic;
		oOE      : out std_logic;
		
		oRW_state : out t_rw;
		oFstate_write : out t_fstate_write;
		oFstate_read : out t_fstate_read
       );
end sram_controller;

architecture Behavioral of sram_controller is

signal rw_state : t_rw;
signal fstate_write : t_fstate_write;
signal fstate_read : t_fstate_read;

begin

	oRW_state <= rw_state;
	oFstate_write <= fstate_write;
	oFstate_read <= fstate_read;
		
    main : process(iClk)
    begin
        if(iClk'EVENT and iClk = '1') then
            if(iRst = '1') then
                oReady <= '0';
					 oCE <= '1';
					 oUB <= '1';
					 oLB <= '1';
					 oWE <= '1';
					 oOE <= '1';

					 oData <= x"0000";
					 oAddress <= x"00000";
					 
					 --rw_state <= RST;
					 fstate_write <= STANDBY;
					 fstate_read <= STANDBY;
				elsif(fstate_read = STANDBY and fstate_write = STANDBY) then
					oReady <= '1';
					if(iTrigger = '1') then
						oReady <= '0';
						if(iRW = '0') then
							fstate_write <= INIT;
						else
							fstate_read <= INIT;
						end if;
					end if;
				end if;
				
				if(rw_state = WT) then
					if(fstate_write = STANDBY) then
						oCE <= '1';
						oUB <= '1';
						oLB <= '1';
						oWE <= '1';
						oOE <= '1';
						
					elsif(fstate_write = INIT) then
						--oReady <= '0';
						oCE <= '0';
						oOE <= '1';
						oUB <= '0';
						oLB <= '0';
						oData <= iData;
						oAddress <= iAddress;
					
					
						fstate_write <= PULSE;
					elsif(fstate_write = PULSE) then
						oWE <= '0';
						fstate_write <= STANDBY;
					else -- if fstate_write = FINISH
						oWE <= '1';
						fstate_write <= STANDBY;
						fstate_read <= STANDBY;
					end if;
					
					
				else -- if rw_state = RD
					 if(fstate_read = STANDBY) then
						--oReady <= '1';
						oCE <= '1';
						oOE <= '1';
						oUB <= '1';
						oLB <= '1';
						oWE <= '1';
					
					 elsif(fstate_read = INIT) then
						--oReady <= '0';
						oCE <= '0';
						oWE <= '1';
						oOE <= '0';
						oUB <= '0';
						oLB <= '0';
						oAddress <= iAddress;
						oData <= iData;
						if (iRW = '1') then 
							fstate_read <= INIT; 
							else
							fstate_read <= STANDBY;
						end if;
						
--					 elsif(fstate_read = PULSE) then
--						oOE <= '0';
--						fstate_read <= LOAD;
--					 elsif(fstate_read = LOAD) then
--					   oOE <= '0';
--						oData <= iData;
--						fstate_read <= FINISH;
					 else -- if fstate_read = FINISH
						oOE <= '0';
						fstate_read <= STANDBY;
						fstate_write <= STANDBY;
					 end if;
					end if;
				end if;
                    
                    
            
    end process;
	 
	 readwrite : process(iClk)
	 begin
		if(iClk'EVENT and iClk = '1') then
			if(iRW = '1') then
				rw_state <= RD;
			else -- if iRW = 0, denoting a write operation
				rw_state <= WT;
			end if;
		end if;
	 
	 end process;
	 
	 

end Behavioral;