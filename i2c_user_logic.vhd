LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
--USE ieee.std_logic_unsigned.all;

ENTITY i2c_user_logic IS
	GENERIC (
		CONSTANT cnt_max : integer := 10416); 
  PORT(
    clk       		: IN     STD_LOGIC;                     --system clock
    iData     		: IN     STD_LOGIC_VECTOR(15 DOWNTO 0); --input data
    oSCL				: inout std_logic;
	 oSDA				: inout std_logic
	 );                    --serial data output
END i2c_user_logic;

ARCHITECTURE user_logic OF i2c_user_logic IS

TYPE state_type IS(start, ready, data_valid, busy_high, repeat); --needed states
signal state      : state_type;                   --state machine
signal reset_n    : STD_LOGIC;                    --active low reset
signal ena        : STD_LOGIC;                    --latch in data
signal data       : STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write 
signal data_wr    : STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write 
signal busy       : STD_LOGIC;                    --indicates transaction in 
signal count 	  : unsigned(27 DOWNTO 0):=X"000000F";
signal byteSel    : integer range 0 to 10:=0;
signal sig_TX     : std_logic;
signal ack_error : std_LOGIC;
signal data_wr_sig :std_LOGIC_VECTOR(7 downto 0);
signal r_w : std_logic;
signal ackSig : std_logic;

COMPONENT i2c_master_2 is
	GENERIC(
    input_clk : INTEGER := 50_000_000; --input clock speed from user logic in Hz
    bus_clk   : INTEGER := 100_000);   --speed the i2c bus (scl) will run at in Hz
  PORT(
    clk       : IN     STD_LOGIC;                    --system clock
    reset_n   : IN     STD_LOGIC;                    --active low reset
    ena       : IN     STD_LOGIC;                    --latch in command
    addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
    rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
    data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
    busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
    data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
    ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
    sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
    scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
END component;

BEGIN
	
process(byteSel, iData)
 begin
    case byteSel is
       when 0  => data <= X"76";
       when 1  => data <= X"76";
       when 3  => data <= X"7A";
       when 4  => data <= X"FF";
       when 5  => data <= X"77";
       when 6  => data <= X"00";
       when 7  => data <= X"0"&iData(15 downto 12);
       when 8  => data <= X"0"&iData(11 downto 8);
       when 9  => data <= X"0"&iData(7  downto 4);
       when 10 => data <= X"0"&iData(3  downto 0);
       when others => data <= X"76";
   end case;
end process;

Inst_i2c_master: i2c_master_2
	GENERIC MAP(
    input_clk => 50_000_000, --input clock speed from user logic in Hz
    bus_clk   => 100_000 )   --speed the i2c bus (scl) will run at in Hz
  PORT MAP(
    clk => clk,                           --system clock
    reset_n => reset_n,                       --active low reset
    ena => ena,                           --latch in command
    addr => "1110001",      							 --address of target slave
    rw => r_w,        						    --'0' is write, '1' is read
    data_wr => data_wr_sig,   							 --data to write to slave
    busy => busy,               				 --indicates transaction in progress
    data_rd => open,    						 --data read from slave
    ack_error => ackSig,                	    --flag if improper acknowledge from slave
    sda => oSDA,                           --serial data output of i2c bus
    scl => oSCL       
	 
	 ); 
	         
process(clk)
begin  
if(clk'event and clk = '1') then
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
		r_w <= '0';
   	data_wr <= data;                --data to be written 
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
          	if byteSel < 10 then
           	   byteSel <= byteSel + 1;
        	else	 
           	   byteSel <= 7;           
         	end if; 		  
   	          state <= start; 
  when others => null;

  end case;   
end if;  
end process;         
end user_logic;  
 