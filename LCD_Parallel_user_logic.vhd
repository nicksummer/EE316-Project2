LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
--USE ieee.std_logic_unsigned.all;

ENTITY LCD_Parallel_user_logic IS
	GENERIC (
		CONSTANT cnt_max : integer := 208333); 
  PORT(
   clk       : IN STD_LOGIC;                     --system clock
   ireset    : in std_logic;
	iData     : in std_LOGIC_VECTOR(7 downto 0);
	oRow      : out std_LOGIC;
	oCol      : out std_LOGIC_VECTOR(3 downto 0);
   oRS       : out std_logic;
	oEN       : out std_logic;
	oData     : out std_logic_vector(7 downto 0)
	
	);                    --serial data output
END LCD_Parallel_user_logic;

ARCHITECTURE user_logic OF LCD_Parallel_user_logic IS

TYPE state_type IS(start, ready, data_valid, busy_high, repeat); --needed states
signal state      : state_type;                   --state machine
signal reset_n    : STD_LOGIC;                    --active low reset
signal ena        : STD_LOGIC;                    --latch in data
signal data       : STD_LOGIC_VECTOR(11 DOWNTO 0); --data to write 
--signal data_wr    : STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write 
signal busy       : STD_LOGIC;                    --indicates transaction in 
--signal busy_prev  : STD_LOGIC;
signal count 	  : unsigned(27 DOWNTO 0):=X"000000F";
signal byteSel    : integer range 0 to 42 :=0;
signal sig_RS     : std_logic;
signal sig_EN     : std_logic;
signal reset_n_combined : std_logic;

TYPE ROW is array (15 downto 0) of STD_LOGIC_VECTOR(15 downto 0);
signal LCD_top_row_sig : row;
signal LCD_top_bottom_sig : row;

    
COMPONENT LCD_Parallel is
	GENERIC (
		CONSTANT cnt_max : integer := 208333); 
		port (
		reset_n				: in std_logic; 
		ena                 : in std_logic; 
		clk				    : in std_logic;
		busy                : out std_logic;
		en                  : out std_logic);
end COMPONENT;

BEGIN
   
    oRS <= data(8);
    oEN <= sig_en;
    
    oData <= data(7 downto 0);
    
   
process(byteSel)
 begin
    case byteSel is
       when 0   => data <= X"038"; -- init seq
       when 1   => data <= X"038";
       when 2   => data <= X"038";
       when 3   => data <= X"038";
       when 4   => data <= X"038";
       when 5   => data <= X"038";
       when 6   => data <= X"001";
       when 7   => data <= X"00C";
       when 8   => data <= X"006";
       when 9   => data <= X"080"; --------------
		 when 26 => data  <= X"0C0"; -- command to change the line on the LCD 26 when in the new 
		 when others => data <= "0001" & iData;
   end case;
	
	if (byteSel < 26) then
		oRow <= '0';
	else 
		oRow <= '1';
	end if;
	
	if (byteSel <= 26) then
		oCol <= std_LOGIC_VECTOR(to_unsigned(byteSel - 10, 4));
	else 
		oCol <= std_LOGIC_VECTOR(to_unsigned(byteSel - 27, 4));
	end if;
end process;

      
Inst_LCD_Parallel: LCD_Parallel
	GENERIC map(
		cnt_max => cnt_max)
	port map (
		reset_n	=>	reset_n,
		ena     =>  ena,
		clk		=>	clk,	  
		busy    =>  busy,       
		en      =>  sig_en         
	  );
        
process(clk)
begin  
if(clk'event and clk = '1') then
  if ireset = '1' then
     state <= start;
     reset_n <= '0';
     byteSel <= 0; 
  else
  case state is 
  when start =>
	      if count /= X"0000000" then
	                            
		count   <= count - 1;	
		reset_n <= '0';	
		state   <= start;
		ena 	<= '0';  
	else
		reset_n <= '1'; 
   	state   <= ready;
   	--data_wr <= data;                --data to be written 
    end if;

  when ready =>		
	      if busy = '0' then
	      	ena     <= '1';
	      	state   <= data_valid;
	      end if;

  when data_valid =>                              --state for conducting this transaction
              if busy = '1' then  
        	ena     <= '0';
        	state   <= busy_high;

              end if;

  when busy_high => 
              if(busy = '0') then                -- busy just went low 
		      state <= repeat;
   	      end if;		     
  when repeat => 
          	if byteSel < 42 then
           	   byteSel <= byteSel + 1;
        	else	 
           	   byteSel <= 9;           
         	end if; 		  
   	          state <= start; 
  when others => null;

  end case;
  end if;   
end if;  
end process;         
end user_logic;  
 