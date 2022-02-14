library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use work.Common.all;

entity project_1 is
	generic(
		COUNTER_N                      : integer  := 8;
		INIT_COUNTER_CLK_EN_MAX        : unsigned := b"100";
		FUNCTIONAL_COUNTER_CLK_EN_MAX_1hz   : unsigned :=  x"2FAF080"; -- should be x"02FAF080" for 1sec delay. Simulation: x"00000004"
		FUNCTIONAL_COUNTER_CLK_EN_MAX_60hz  : unsigned :=  x"0000CB7";
		FUNCTIONAL_COUNTER_CLK_EN_MAX_120hz : unsigned :=  x"000065C";
		FUNCTIONAL_COUNTER_CLK_EN_MAX_1000hz : unsigned := x"00000C3";
		RESET_DELAY_DELAY              : unsigned := x"FFFFF"     -- Real hardware value: X"FFFFF". Simulation value: X"00004".
	);
	port (
		CLOCK_50   : in std_logic;                        -- 50MHz clock
		KEY        : in std_logic_vector(3 downto 0);     -- keys for input
		SW 		  : in std_LOGIC_VECTOR(1 downto 0);
	   GPIO       : inout std_logic_vector(35 downto 0); -- GPIO (for keypad)
	   LEDR       : out std_logic_vector(15 downto 0);    -- red LEDs
		LEDG       : out std_logic_vector(2 downto 0);    -- green LEDs
		SRAM_DQ    : inout std_logic_vector(15 downto 0);   -- SRAM data
		SRAM_ADDR  : out std_logic_vector(19 downto 0);   -- SRAM address
		SRAM_CE_N  : out std_logic;                       -- SRAM CE
		SRAM_UB_N  : out std_logic;                       -- SRAM UB
		SRAM_LB_N  : out std_logic;                       -- SRAM LB
		SRAM_WE_N  : out std_logic;                       -- SRAM WE
		SRAM_OE_N  : out std_logic;                       -- SRAM OE
		LCD_EN     : out std_logic;
		LCD_RS     : out std_logic;
		LCD_DATA   : out std_LOGIC_VECTOR(7 downto 0);
		LCD_RW     : out std_logic;
		
		
		-- signal outputs for simulation
		oreset_sig    : out std_logic;
		oKP_value_sig : out std_logic_vector(4 downto 0);
		oRD_reset_sig : out std_logic;
		oDB_reset_sig : out std_logic;
		
		ostate_ul_sig                 : out t_ul;
		ostate_ul_program_sig         : out t_ul_program;
		ostate_ul_program_data_sig    : out t_ul_program_data;
		ostate_ul_program_address_sig : out t_ul_program_address;
		odigit_count_sig              : out unsigned(2 downto 0);                        
		oload_complete_sig            : out std_logic := '0';                            
		otriggered_sig                : out unsigned(1 downto 0);
		
		-- SRAM controller signals
		oSRAM_iData_sig        : out std_logic_vector(15 downto 0);                      -- Data to SRAM controller
		oSRAM_iData_buffer_sig : out std_logic_vector(15 downto 0);                      -- SRAM iData tristate buffer
		oSRAM_oData_sig       : out std_logic_vector(15 downto 0);                       -- Data from SRAM controller
		oSRAM_address_sig     : out std_logic_vector(19 downto 0);                       -- Address to SRAM controller
		oSRAM_rw_sig          : out std_logic;                                           -- Read/Write signal for SRAM controller
		oSRAM_trigger_sig     : out std_logic;                                           -- Trigger to SRAM controller
		oSRAM_ready_sig       : out std_logic;                                           -- Ready signal from SRAM controller
		
		--ROM signals 
		oROM_address_sig      : out std_logic_vector(7 downto 0);                        -- Address selection input to ROM
		oROM_q_sig            : out std_logic_vector(15 downto 0);                       -- Data output from ROM
		
		-- Init counter signals
		oIC_clear_sig         : out std_logic;                                           -- Synchronous clear to init counter
		oIC_en_sig            : out std_logic;                                           -- Enable to init counter
		oIC_max_tick_sig      : out std_logic;                                           -- Max tick from init counter
		oIC_q_sig             : out std_logic_vector(COUNTER_N-1 downto 0);              -- Q address output from init counter
		oIC_clk_en_sig        : out std_logic;                                           -- Clock enable signal to the init counter (period 100ns)
		oIC_clk_en_count_sig  : out unsigned(2 downto 0) := b"000";                      -- Unsigned clock enable counter for the init counter (to create a clk_en signal of period 100ns)
		oIC_q_old_sig         : out std_logic_vector(COUNTER_N-1 downto 0) := x"02";     -- Old Q address output from init counter (to detect changes)
		
		-- Functional counter signals
		oFC_clear_sig         : out std_logic;                                           -- Synchronous clear to functional counter
		oFC_en_sig            : out std_logic;                                           -- Enable to functional counter
		oFC_up_sig            : out std_logic;
		oFC_max_tick_sig      : out std_logic;                                           -- Max tick from functional counter
		oFC_q_sig             : out std_logic_vector(COUNTER_N-1 downto 0);              -- Q address output from functional counter
		oFC_clk_en_sig        : out std_logic;                                           -- Clock enable signal to the functional counter (period 1s)
		oFC_clk_en_count_sig  : out unsigned(27 downto 0) := x"0000000";                 -- Unsigned clock enable counter for the functional counter (to create a clk_en signal of period 1s)
		oFC_q_old_sig         : out std_logic_vector(COUNTER_N-1 downto 0) := x"02"      -- Old Q address output from init counter (to detect changes)
	);
end project_1;

architecture Structural of project_1 is

	component LCD_Parallel_user_logic is 
		GENERIC (
			CONSTANT cnt_max : integer := 208333); 
	  PORT(
		 clk       : IN STD_LOGIC;                     --system clock
		 ireset   : in std_logic;
		 iData 	: in std_LOGIC_VECTOR(7 downto 0);
		 oRow     : out std_LOGIC;
		 oCol     : out std_LOGIC_VECTOR(3 downto 0);
		 oRS       : out std_logic;
		 oEN       : out std_logic;
		 oData     : out std_logic_vector(7 downto 0)
		);
	end component;
	
	component i2c_user_level is  
		port (
			iClk : in std_logic;
			reset_n  : in std_logic;
			idata    : in std_LOGIC_VECTOR(15 downto 0);
			ena      : in std_LOGIC;
			oSDA     : inout std_logic;
			oSCL     : inout std_logic
		);
	end component;

	component PWM_Generator is 
		port (
			CLK : in std_logic;
			reset_n : in std_logic;
			duty_cycle : in std_logic_vector(15 downto 0);
			duty_load : in std_logic;
			PWM_out : out std_logic
			
		);
	end component;

	component reset_delay is
	generic (
		DELAY_LENGTH : unsigned(19 DOWNTO 0) := X"FFFFF"
	);
	port (
		signal iCLK : IN std_logic;	
		signal oRESET : OUT std_logic := '1'
	);	
	end component;
	  
	component sram_controller is
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
	
	end component;
	
	component rom is
	port(
		address	: in STD_LOGIC_VECTOR (7 downto 0);
		clock		: in STD_LOGIC  := '1';
		q		   : out STD_LOGIC_VECTOR (15 downto 0)
	);
	
	end component;
	
	component univ_bin_counter is
	generic(N: integer := 8);
	port(
			clk, reset				: in std_logic;
			syn_clr, load, en, up: in std_logic;
			clk_en 					: in std_logic := '1';
			d							: in std_logic_vector(N-1 downto 0);
			max_tick, min_tick	: out std_logic;
			q							: out std_logic_vector(N-1 downto 0)
		);
	end component;
	
	component seven_seg_controller is
	port (
		iClk  : in STD_LOGIC;
		iData : in STD_LOGIC_VECTOR(3 downto 0);
		oData : out STD_LOGIC_VECTOR(6 downto 0)
	);
	
	end component;
	
	component btn_debounce_toggle is
		generic(
			CONSTANT CNTR_MAX : std_logic_vector(15 downto 0) := X"FFFF"
		);
		port(
			BTN_I 	: in  STD_LOGIC;
			CLK 		: in  STD_LOGIC;
			BTN_O 	: out  STD_LOGIC;
			TOGGLE_O : out  STD_LOGIC
		);
	
	end component;
	
-- ----Signals---- --
	signal reset_sig            : std_logic;
	
	-- Reset delay signals
	signal RD_reset_sig         : std_logic;
	
	-- Debouncer signals
	signal DB_reset_sig         : std_logic;
	
	-- Keypad signals
	signal KP_value_sig         : std_logic_vector(4 downto 0);
	signal KP_value_reg_sig     : std_logic_vector(4 downto 0);
	signal KP_clk_en_sig        : std_logic;
	signal KP_rows_sig          : std_logic_vector(4 downto 0);
	signal KP_data_valid_sig    : std_logic;
	
	-- SRAM controller signals
	signal SRAM_iData_sig        : std_logic_vector(15 downto 0);                      -- Data to SRAM controller
	signal SRAM_iData_buffer_sig : std_logic_vector(15 downto 0);                      -- SRAM iData tristate buffer
	signal SRAM_oData_sig       : std_logic_vector(15 downto 0);                       -- Data from SRAM controller
	signal SRAM_address_sig     : std_logic_vector(19 downto 0);                       -- Address to SRAM controller
	signal SRAM_rw_sig          : std_logic;                                           -- Read/Write signal for SRAM controller
	signal SRAM_trigger_sig     : std_logic;                                           -- Trigger to SRAM controller
	signal SRAM_ready_sig       : std_logic;                                           -- Ready signal from SRAM controller
	
	--ROM signals 
	signal ROM_address_sig      : std_logic_vector(7 downto 0);                        -- Address selection input to ROM
	signal ROM_q_sig            : std_logic_vector(15 downto 0);                       -- Data output from ROM
	
	-- Init counter signals
	signal IC_clear_sig         : std_logic := '0';                                    -- Synchronous clear to init counter
	signal IC_en_sig            : std_logic := '0';                                    -- Enable to init counter
	signal IC_max_tick_sig      : std_logic;                                           -- Max tick from init counter
	signal IC_q_sig             : std_logic_vector(COUNTER_N-1 downto 0);              -- Q address output from init counter
	signal IC_clk_en_sig        : std_logic;                                           -- Clock enable signal to the init counter (period 100ns)
	signal IC_clk_en_count_sig  : unsigned(2 downto 0) := b"000";                      -- Unsigned clock enable counter for the init counter (to create a clk_en signal of period 100ns)
	signal IC_q_old_sig         : std_logic_vector(COUNTER_N-1 downto 0) := x"02";     -- Old Q address output from init counter (to detect changes) ("x02" is a dummy value - just can't be x"00")
	
	-- Functional counter signals
	signal FC_clear_sig         : std_logic := '0';                                    -- Synchronous clear to functional counter
	signal FC_en_sig            : std_logic := '1';                                    -- Enable to functional counter
	signal FC_up_sig            : std_logic;
	signal FC_max_tick_sig      : std_logic;                                           -- Max tick from functional counter
	signal FC_q_sig             : std_logic_vector(COUNTER_N-1 downto 0);              -- Q address output from functional counter
	signal FC_clk_en_sig        : std_logic;                                           -- Clock enable signal to the functional counter (period 1s)
	signal FC_clk_en_count_sig  : unsigned(27 downto 0) := x"0000000";                 -- Unsigned clock enable counter for the functional counter (to create a clk_en signal of period 1s)
	signal FC_q_old_sig         : std_logic_vector(COUNTER_N-1 downto 0) := x"02";     -- Old Q address output from init counter (to detect changes) ("x02" is a dummy value - just can't be x"00")
	signal FC_en_sig_rst        : std_LOGIC;
	signal FC_pause_sig 			 : std_LOGIC;
	signal FUNCTIONAL_COUNTER_CLK_EN_MAX_sig : unsigned(27 downto 0) := (others => '0');
	
	-- Seven segment signals
--	signal SS_hex0_sig          : std_logic_vector(3 downto 0);                         -- One-digit hex data into hex0
--	signal SS_hex1_sig          : std_logic_vector(3 downto 0);                         -- One-digit hex data into hex1
--	signal SS_hex2_sig          : std_logic_vector(3 downto 0);                         -- One-digit hex data into hex2
--	signal SS_hex3_sig          : std_logic_vector(3 downto 0);                         -- One-digit hex data into hex3
--	signal SS_hex4_sig          : std_logic_vector(3 downto 0);                         -- One-digit hex data into hex4
--	signal SS_hex5_sig          : std_logic_vector(3 downto 0);                         -- One-digit hex data into hex5
	
	signal SS_DATA_SIG : STD_LOGIC_VECTOR(15 downto 0);
	signal SS_ADDR_SIG : STD_LOGIC_VECTOR(15 downto 0);
	signal i2c_ENA_SIG : STD_LOGIC;
	
	-- User logic state machine signals
	signal state_ul_sig                 : t_ul;
	signal state_ul_program_sig         : t_ul_program;
	signal state_ul_program_data_sig    : t_ul_program_data;
	signal state_ul_program_address_sig : t_ul_program_address;
	signal digit_count_sig              : unsigned(2 downto 0);                         -- Keeps track of how many digits have been entered in the programming mode
	signal load_complete_sig            : std_logic := '0';                             -- Used to tell state_change process if a load has been completed
	signal triggered_sig                : unsigned(1 downto 0) := "00";                 -- Used as a counter to time the SRAM triggering process
	
	-- Debouncer Signals
	
	signal key1_sig : std_logic;
	signal key1_db_sig : std_logic;
	signal key2_sig : std_logic;
	signal key2_db_sig : std_logic;
	signal key3_sig : std_logic;
	signal key3_db_sig : std_logic;
	signal sw_sig : std_logic;
	signal sw_db_sig : std_logic;
	
	signal key1_db_sig_last : std_logic;
	signal key2_db_sig_last : std_logic;
	signal key3_db_sig_last : std_logic;
	signal sw_db_sig_last : std_logic;
	signal sw1_sig : std_LOGIC;	
	
	-- user input addr data signals 
	signal user_input_addr_sig : STD_LOGIC_VECTOR(7 downto 0);
	signal user_input_data_sig : STD_LOGIC_VECTOR(15 downto 0);
	
	--PWM signals 
	signal pwm_out_sig : std_logic;
	
	-- LCD PARALLEL signals
	signal LCD_EN_SIG : std_LOGIC;
	signal LCD_RS_SIG : STD_LOGIC;
	signal LCD_oDATA_sig : std_LOGIC_VECTOR(7 downto 0);
	signal LCD_iData_sig : std_LOGIC_VECTOR(7 downto 0);
	signal LCD_oRow_sig  : std_logic;
	signal LCD_oCol_sig  : std_LOGIC_VECTOR(3 downto 0);
	
	TYPE ROW is array (15 downto 0) of STD_LOGIC_VECTOR(7 downto 0);
	constant InitiALIZATION_const : row := (x"20", x"20", x"20", x"20", x"67", x"6e", x"69", x"7a", x"69", x"6c", x"61", x"69", x"74", x"69", x"6e", x"49");
	constant testmode_const       : row := (x"20", x"20", x"20", x"20", x"20", x"20", x"20", x"65", x"64", x"6f", x"6d", x"20", x"74", x"73", x"65", x"74");
	constant hexdigit			      : row := (x"66", x"65", x"64", x"63", x"62", x"61", x"39", x"38", x"37", x"36", x"35", x"34", x"33", x"32", x"31", x"30");
	constant pwm_mode_const       : row := (x"20", x"20", x"20", x"6e", x"6f", x"74", x"61", x"72", x"65", x"6e", x"65", x"67", x"20", x"6d", x"77", x"70");
	begin
	
	-- connecting signal outputs for simulation
--	oreset_sig                   <= reset_sig;
--	oKP_value_sig                <= KP_value_sig;
--	oRD_reset_sig                <= RD_reset_sig;
--	oDB_reset_sig                <= DB_reset_sig;
--	
--	ostate_ul_sig                 <= state_ul_sig;
--	ostate_ul_program_sig         <= state_ul_program_sig;
--	ostate_ul_program_data_sig    <= state_ul_program_data_sig;
--	ostate_ul_program_address_sig <= state_ul_program_address_sig;
--	odigit_count_sig              <= digit_count_sig;
--	oload_complete_sig            <= load_complete_sig;
--	otriggered_sig                <= triggered_sig;
--	
--	oSRAM_iData_sig               <= SRAM_iData_sig;
--	oSRAM_iData_buffer_sig        <= SRAM_iData_buffer_sig;
--	oSRAM_oData_sig               <= SRAM_oData_sig;
--	oSRAM_address_sig             <= SRAM_address_sig;
--	oSRAM_rw_sig                  <= SRAM_rw_sig;
--	oSRAM_trigger_sig             <= SRAM_trigger_sig; 
--	oSRAM_ready_sig               <= SRAM_ready_sig;
--	
--	oROM_address_sig              <= ROM_address_sig;
--	oROM_q_sig                    <= ROM_q_sig;
--	 
--	oIC_clear_sig                 <= IC_clear_sig;
--	oIC_en_sig                    <= IC_en_sig;
--	oIC_max_tick_sig              <= IC_max_tick_sig;
--	oIC_q_sig                     <= IC_q_sig;
--	oIC_clk_en_sig                <= IC_clk_en_sig;
--	oIC_clk_en_count_sig          <= IC_clk_en_count_sig;
--	oIC_q_old_sig                 <= IC_q_old_sig;
--
--	oFC_clear_sig                 <= FC_clear_sig;
--	oFC_en_sig                    <= FC_en_sig;
--	oFC_up_sig                    <= FC_up_sig;
--	oFC_max_tick_sig              <= FC_max_tick_sig;
--	oFC_q_sig                     <= FC_q_sig;
--	oFC_clk_en_sig                <= FC_clk_en_sig;
--	oFC_clk_en_count_sig          <= FC_clk_en_count_sig;
--	oFC_q_old_sig                 <= FC_q_old_sig;

	-- Static signal mappings
	
	ROM_address_sig <= IC_q_sig;   -- Map the output of the init counter to the ROM's address input
	sw_sig <= sw(0);
	sw1_sig <= sw(1);
	key1_sig <= key(1);
	key2_sig <= key(2);
	key3_sig <= key(3);
	
	LCD_DATA <= LCD_oDATA_sig;
	--LCD_idata_sig <= initialization_const(to_integer(unsigned(LCD_oCol_sig)));
	LCD_EN <= LCD_EN_SIG;
	LCD_RS <= LCD_RS_SIG;
	LCD_RW <= '0';
	
	
	-- This process solves the problem of multiple drivers on reset_sig by separating them into two cases:
	-- one where the reset delay is active, and another where it isn't.
	
	reset_switch : process(RD_reset_sig)
	begin
		if (RD_reset_sig = '1') then
			reset_sig <= '1'; -- RESET DELAY 
		else
			reset_sig <= DB_reset_sig; -- BUTTON DEBOUNCER
		end if;
	end process;
	
	
--	KP_load : process(CLOCK_50, KP_data_valid_sig)
--	begin
--		if (rising_edge(CLOCK_50) and KP_clk_en_sig = '1' and KP_data_valid_sig = '1') then 
--			KP_value_reg_sig <= KP_value_sig;
--		end if;
--	end process;
--	
--	init_clk_en : process(CLOCK_50, IC_en_sig)
--	begin
--		if (IC_en_sig = '1') then
--			if (rising_edge(CLOCK_50) and CLOCK_50'EVENT) then
--				if (IC_clk_en_count_sig = INIT_COUNTER_CLK_EN_MAX) then
--					IC_clk_en_sig <= '1';
--					IC_clk_en_count_sig <= b"000";
--				else
--					IC_clk_en_sig <= '0';
--					IC_clk_en_count_sig <= IC_clk_en_count_sig + b"001";
--				end if;
--			end if;
--		else
--			IC_clk_en_sig <= '0';
--			IC_clk_en_count_sig <= b"000";
--		end if;
--	end process;

-- create a seperate process to control the frequency using a signal
		-- cycling through three values.
		
	process(LCD_oRow_sig, LCD_oCol_sig, state_ul_sig)
	begin 
		if (state_ul_sig = INITIALIZATION) then
			if(LCD_oRow_sig = '0') then 
					LCD_idata_sig <= initialization_const(to_integer(unsigned(LCD_oCol_sig)));
			else 
					LCD_idata_sig <= x"20";
			end if;
		elsif (state_ul_sig = TEST_MODE) then
			if(LCD_oRow_sig = '0') then 
				LCD_idata_sig <= testmode_const(to_integer(unsigned(LCD_oCol_sig)));
			else
				case LCD_oCol_sig is 
					when "0000" => lcd_idata_sig <= hexdigit(to_integer(unsigned(SRAM_address_sig(7 downto 4))));
					when "0001" => lcd_idata_sig <= hexdigit(to_integer(unsigned(SRAM_address_sig(3 downto 0))));
					when "0011" => lcd_idata_sig <= hexdigit(to_integer(unsigned(SRAM_odata_sig(15 downto 12))));
					when "0100" => lcd_idata_sig <= hexdigit(to_integer(unsigned(SRAM_odata_sig(11 downto 8))));
					when "0101" => lcd_idata_sig <= hexdigit(to_integer(unsigned(SRAM_odata_sig(7 downto 4))));
					when "0110" => lcd_idata_sig <= hexdigit(to_integer(unsigned(SRAM_odata_sig(15 downto 0))));
					when others => LCD_idata_sig <= x"20";
				end case;
			end if;
		elsif(state_ul_sig = PWM_GENERATION) then
			if(LCD_oRow_sig = '0') then 
				LCD_idata_sig <= pwm_mode_const(to_integer(unsigned(LCD_oCol_sig)));
			else 
				if (FUNCTIONAL_COUNTER_CLK_EN_MAX_sig = FUNCTIONAL_COUNTER_CLK_EN_MAX_60hz) then
					case LCD_oCol_sig is 
					when "0000" => lcd_idata_sig <= x"36";
					when "0001" => lcd_idata_sig <= x"30";
					when "0011" => lcd_idata_sig <= x"48";
					when "0100" => lcd_idata_sig <= x"7A";
					when others => LCD_idata_sig <= x"20";
				end case;
				elsif (FUNCTIONAL_COUNTER_CLK_EN_MAX_sig = FUNCTIONAL_COUNTER_CLK_EN_MAX_120hz) then
					case LCD_oCol_sig is 
						when "0000" => lcd_idata_sig <= x"31";
						when "0001" => lcd_idata_sig <= x"32";
						when "0010" => lcd_idata_sig <= x"30";
						when "0100" => lcd_idata_sig <= x"48";
						when "0101" => lcd_idata_sig <= x"7A";
						when others => LCD_idata_sig <= x"20";
					end case;
				else
					case LCD_oCol_sig is 
						when "0000" => lcd_idata_sig <= x"31";
						when "0001" => lcd_idata_sig <= x"30";
						when "0010" => lcd_idata_sig <= x"30";
						when "0011" => lcd_idata_sig <= x"30";
						when "0101" => lcd_idata_sig <= x"48";
						when "0110" => lcd_idata_sig <= x"7A";
						when others => LCD_idata_sig <= x"20";
					end case;
				end if;
			end if;	
		end if;
	end process;
		
	process(cloCK_50)
	begin
		if(rising_edge(cloCK_50)) then
			if (state_ul_sig = TEST_MODE) then 
					FUNCTIONAL_COUNTER_CLK_EN_MAX_sig <= FUNCTIONAL_COUNTER_CLK_EN_MAX_1hz;
					
			elsif (state_ul_sig = PWM_GENERATION and funCTIONAL_COUNTER_CLK_EN_MAX_sig = FUNCTIONAL_COUNTER_CLK_EN_MAX_1hz) then
				FUNCTIONAL_COUNTER_CLK_EN_MAX_sig <= FUNCTIONAL_COUNTER_CLK_EN_MAX_60hz;
			elsif (state_ul_sig = PWM_GENERATION and key3_db_sig_last = '0' and key3_db_sig ='1') then
			
					if (FUNCTIONAL_COUNTER_CLK_EN_MAX_sig = FUNCTIONAL_COUNTER_CLK_EN_MAX_60hz) then
						FUNCTIONAL_COUNTER_CLK_EN_MAX_sig <= FUNCTIONAL_COUNTER_CLK_EN_MAX_120hz;
						
					elsif (FUNCTIONAL_COUNTER_CLK_EN_MAX_sig = FUNCTIONAL_COUNTER_CLK_EN_MAX_120hz) then
						FUNCTIONAL_COUNTER_CLK_EN_MAX_sig <= FUNCTIONAL_COUNTER_CLK_EN_MAX_1000hz;
						
					else
						FUNCTIONAL_COUNTER_CLK_EN_MAX_sig <= FUNCTIONAL_COUNTER_CLK_EN_MAX_60hz;
					end if;
			end if;	
		end if; 
	end process;
		
	functional_clk_en : process(CLOCK_50, FC_en_sig) -- clk en for 1 second?
	begin
		if (FC_en_sig = '1') then
			if (rising_edge(CLOCK_50) and CLOCK_50'EVENT) then
				if (FC_clk_en_count_sig >= FUNCTIONAL_COUNTER_CLK_EN_MAX_sig) then -- change the max into a signal with the same type as the m
					FC_clk_en_sig <= '1';
					FC_clk_en_count_sig <= x"0000000";
				else
					FC_clk_en_sig <= '0';
					FC_clk_en_count_sig <= FC_clk_en_count_sig + x"0000001";
				end if;
			end if;
		else
			FC_clk_en_sig <= '0';
			FC_clk_en_count_sig <= x"0000000";
		end if;
	end process;
	
	init_counter_change : process(CLOCK_50) -- change direction?
	begin
		if(rising_edge(CLOCK_50) and CLOCK_50'EVENT) then
		end if;
	end process;
	
	-- BEGIN USER LOGIC --
	-- Two separate processes for user logic
	-- First, controls changing of states due to user's input
	-- Second, controls the results of the changes in states
	
	state_change : process(CLOCK_50)
	begin
		if(rising_edge(CLOCK_50) and CLOCK_50'EVENT) then
			if(reset_sig = '1') then
				state_ul_sig <= RST;
			elsif (state_ul_sig <= RST or (sw_db_sig_last = '0' and sw_db_sig = '1')) then	
				state_ul_sig <= INITIALIZATION;
			else
				if(state_ul_sig = TEST_MODE or state_ul_sig = PWM_GENERATION) then
					FC_clear_sig <= '0';
				else 
				   FC_clear_sig <= '1';
				end if;
		
				if(IC_max_tick_sig = '1' and state_ul_sig = INITIALIZATION and sw_db_sig = '0' and sw_db_sig_last = '1') then
					FC_clear_sig <= '1';
					state_ul_sig <= TEST_MODE;
				end if;
				
				--if(state_ul_sig = TEST_MODE and KP_value_reg_sig = b"10000") then -- b"10000" denotes SHIFT key
				
				if(state_ul_sig = TEST_MODE and key2_db_sig = '0' and key2_db_sig_last = '1') then

					state_ul_sig <= PWM_GENERATION;
				end if;
				
				--if(state_ul_sig = PWM_GENERATION and state_ul_program_address_sig <= STANDBY and state_ul_program_data_sig <= STANDBY and KP_value_reg_sig = b"10000") then -- b"10000" denotes SHIFT key
				if(state_ul_sig = PWM_GENERATION  and key1_db_sig = '0' and key1_db_sig_last = '1' ) then	
					state_ul_sig <= TEST_MODE;
				end if;
 			end if;
		end if;
	
	end process;
	
	-- Tri-state buffer for SRAM_iData_sig
--	SRAM_iData_sig <= SRAM_iData_buffer_sig when (state_ul_sig = TEST_MODE) else --????
--							ROM_q_sig when (state_ul_sig = INITIALIZATION) -- Tie the ROM's data output to the SRAM controller's data input
--							else (others => 'Z');

   SRAM_iData_sig <= SRAM_DQ;
	SRAM_DQ <= rom_q_sig when (state_ul_sig = INITIALIZATION) else 
				 user_input_data_sig when state_ul_sig = PWM_GENERATION else --change later
				  (others => 'Z');

	state_actions : process(CLOCK_50)
	begin
		if(rising_edge(CLOCK_50) and CLOCK_50'EVENT) then
			LEDG(0) <= '0';
			FC_en_sig <= FC_pause_sig;
			if(state_ul_sig = RST) then
				IC_q_old_sig <= (others => '0');
				triggered_sig <= "00";
				FC_up_sig <= '1';
				FC_pause_sig <= '1';
				i2c_ENA_SIG <= '0';
				
		
			elsif(state_ul_sig = INITIALIZATION) then 
				--SRAM_DQ <= SRAM_oData_sig;                -- Tie the SRAM controller's data output to the SRAM (because writing)
				SRAM_address_sig <= x"000" & IC_q_sig;    -- Tie the init counter's output (an address ranging from 0x00 to 0xFF) into the SRAM controller's address input
				SRAM_rw_sig <= '0';                       -- Tie the SRAM's r/w input LOW to indicate writing
				IC_en_sig <= '1';
				i2c_ENA_SIG <= '0';
				
				-- LCD says Initialization in this state 
				
				case triggered_sig is
					when "00" => 
						SRAM_trigger_sig <= '0';
						IC_clk_en_sig <= '0';
						if (SRAM_ready_sig = '1') then 
							triggered_sig <= "01";
							SRAM_trigger_sig <= '1';
						end if;
					when "01" =>
						SRAM_trigger_sig <= '0';
						IC_clk_en_sig <= '0';
						triggered_sig <= "10";
					when "10" =>
						SRAM_trigger_sig <= '0';
						IC_clk_en_sig <= '0';
						if (SRAM_ready_sig = '1') then
							triggered_sig <= "11";
						end if;
					when "11" =>
						SRAM_trigger_sig <= '0';
						IC_clk_en_sig <= '0';
						if (IC_max_tick_sig /= '1') then
							IC_clk_en_sig <= '1';
							triggered_sig <= "00";
						end if;
				end case;

			elsif(state_ul_sig = TEST_MODE) then          -- This state only reads from the SRAM
				Triggered_sig <= "00";
				SRAM_address_sig <= x"000" & FC_q_sig;     -- Tie the functional counter's output (an address ranging from 0x00 to 0xFF) into the SRAM controller's address input
				SRAM_iData_buffer_sig <= SRAM_DQ;          -- Get data from SRAM's I/O SRAM_DQ and put it into the iData buffer            
				SRAM_rw_sig <= '1';                        -- Tie r/w on the SRAM controller high to indicate reading
				IC_en_sig <= '0';
				i2c_ENA_SIG <= '1';
				
				-- LCD displays test mode in this state or pause mode when it is paused
				 
				
				if(key1_db_sig = '0' and key1_db_sig_last = '1') then 
					-- pause mode on the LCD
					FC_pause_sig <= not FC_pause_sig;
				end if;
				
				SRAM_trigger_sig <= '1';
				
				--The Lcd should also display the SRAM addr and data in this state
				
				SS_DATA_SIG <= SRAM_oData_sig;
				SS_ADDR_SIG <= SRAM_address_sig(15 downto 0);
				
			
			elsif(state_ul_sig = PWM_GENERATION) then
				i2c_ENA_SIG <= '0';
				Triggered_sig <= "00";
				SRAM_address_sig <= x"000" & FC_q_sig;     -- Tie the functional counter's output (an address ranging from 0x00 to 0xFF) into the SRAM controller's address input
				SRAM_iData_buffer_sig <= SRAM_DQ;          -- Get data from SRAM's I/O SRAM_DQ and put it into the iData buffer            
				SRAM_rw_sig <= '1';                        -- Tie r/w on the SRAM controller high to indicate reading
				IC_en_sig <= '0';
				FC_en_sig <= '1';
				
				
				--The LCD should display PWM mode and should also display which frequency the sine wave should be generated at
				
				
				LEDG(0) <= PWM_out_sig;
				
				SRAM_trigger_sig <= '1';
				
			end if;
		end if;
	end process;
	
	inst_lcd_user_logic : LCD_Parallel_user_logic 
		GENERIC MAP (
			cnt_max => 208333)
	  PORT MAP(
		 clk    => CLOCK_50,                      --system clock
		 ireset => reset_sig, 
		 iData  => LCD_idata_sig,
		 oRow   => LCD_oRow_sig,
		 oCol   => LCD_oCol_sig,
		 oRS    => LCD_RS_SIG,    
		 oEN    => LCD_EN_SIG,  
		 oData  => LCD_oDATA_sig  
		);
		
		
	inst_i2c_user_level: i2c_user_level
	  PORT MAP(
			iClk => CLOCK_50,
			reset_n  => '1',
			idata    => SS_DATA_SIG,
			ena      => i2c_ENA_SIG,
			oSDA     => GPIO(9),
			oSCL     => GPIO(7)
		 );
		 
	inst_i2c_user_level2: i2c_user_level
	  PORT MAP(
			iClk => CloCK_50,
			reset_n  => '1',
			idata    => SS_ADDR_SIG,
			ena      => i2c_ENA_SIG,
			oSDA     => GPIO(10),
			oSCL     => GPIO(12)
		 );	 
	inst_PWM_Generator: PWM_Generator 
		port map (
			CLK 			=> CLOCK_50,
			reset_n     => '1',
			duty_cycle  => SRAM_oData_sig,
			duty_load   => SRAM_trigger_sig,
			PWM_out     => PWM_out_sig
			
		);
		
	inst_reset_delay : reset_delay
	generic map(
		DELAY_LENGTH => RESET_DELAY_DELAY -- Real hardware value: X"FFFFF". Simulation value: X"00004".
	)
	port map(
		iCLK          => CLOCK_50,
		oRESET        => RD_reset_sig
	
	);
	
--	inst_keypad_controller : keypad_controller
--	port map(
--		reset      => reset_sig,
--		clk        => CLOCK_50,
--		cols       => GPIO(9 downto 6),
--		clk_en     => KP_clk_en_sig,
--		rows       => KP_rows_sig,
--		kp_value   => KP_value_sig,
--		data_valid => KP_data_valid_sig
--			
--	);
	
	inst_sram_controller : sram_controller
	port map(
		iClk	     => CLOCK_50,
		iData      => SRAM_iData_sig,
		iAddress   => SRAM_address_sig,
		iRst       => reset_sig,      
		iRW        => SRAM_rw_sig,
		iTrigger   => SRAM_trigger_sig,
		oReady     => SRAM_ready_sig,
		oData      => SRAM_oData_sig,
		oAddress   => SRAM_ADDR,
		oCE        => SRAM_CE_N,
		oUB        => SRAM_UB_N,
		oLB        => SRAM_LB_N,
		oWE        => SRAM_WE_N,
		oOE        => SRAM_OE_N
	);
		
	inst_rom : rom
	port map(
		address    => ROM_address_sig,
		clock      => CLOCK_50,
		q		     => ROM_q_sig
	);
	
	init_univ_bin_counter : univ_bin_counter
	generic map(
		N => COUNTER_N
	)
	port map(
		clk        => CLOCK_50,
		reset      => reset_sig,
		syn_clr    => IC_clear_sig,
		load       => '0',
		en         => IC_en_sig,
		up         => '1',
		clk_en 	  => IC_clk_en_sig,
		d          => x"00",
		max_tick   => IC_max_tick_sig,
		q		     => IC_q_sig
);
	
	functional_univ_bin_counter : univ_bin_counter
	generic map(
		N => COUNTER_N
	)
	port map(
		clk        => CLOCK_50,
		reset      => reset_sig,
		syn_clr    => FC_clear_sig,
		load       => '0',
		en         => FC_en_sig,
		up         => FC_up_sig,
		clk_en 	  => FC_clk_en_sig,
		d          => x"00",
		max_tick   => FC_max_tick_sig,
		q		     => FC_q_sig
	);
	
	process(CLOCK_50)
	begin 
		if(rising_edge(CLOCK_50)) then
		key1_db_sig_last <= key1_db_sig;
		key2_db_sig_last <= key2_db_sig;
		key3_db_sig_last <= key3_db_sig;
		sw_db_sig_last <= sw_db_sig;
		end if;
	end process;
		
	inst_btn_debounce_toggle : btn_debounce_toggle
	port map(
		BTN_I 	  => key1_sig,--KEY(1), -- not this 
		CLK        => CLOCK_50,		
		BTN_O 	  => key1_db_sig
	);
	
	inst_btn_debounce_toggle1 : btn_debounce_toggle
	port map(
		BTN_I 	  => key2_sig,--KEY(1), -- not this 
		CLK        => CLOCK_50,		
		BTN_O 	  => key2_db_sig
	);
	inst_btn_debounce_toggle2 : btn_debounce_toggle
	port map(
		BTN_I 	  => key3_sig,--KEY(1), -- not this 
		CLK        => CLOCK_50,		
		BTN_O 	  => key3_db_sig
	);
	inst_btn_debounce_toggle_sw : btn_debounce_toggle
	port map(
		BTN_I 	  => sw_sig,--KEY(1), -- not this 
		CLK        => CLOCK_50,		
		BTN_O 	  => sw_db_sig
	);
	
	inst_btn_debounce_toggle_sw1 : btn_debounce_toggle
	port map(
		BTN_I 	  => sw1_sig,--KEY(1), -- not this 
		CLK        => CLOCK_50,		
		BTN_O 	  => DB_reset_sig
	);
	
--	hex0_seven_seg_controller : seven_seg_controller
--	port map(
--		iClk       => CLOCK_50,
--		iData      => SS_hex0_sig,
--		oData      => HEX0
--	);
--		
--	hex1_seven_seg_controller : seven_seg_controller
--	port map(
--		iClk       => CLOCK_50,
--		iData      => SS_hex1_sig,
--		oData      => HEX1
--	);
--		
--	hex2_seven_seg_controller : seven_seg_controller
--	port map(
--		iClk       => CLOCK_50,
--		iData      => SS_hex2_sig,
--		oData      => HEX2
--	);
--		
--	hex3_seven_seg_controller : seven_seg_controller
--	port map(
--		iClk       => CLOCK_50,
--		iData      => SS_hex3_sig,
--		oData      => HEX3
--	);
--	
--	hex4_seven_seg_controller : seven_seg_controller
--	port map(
--		iClk       => CLOCK_50,
--		iData      => SS_hex4_sig,
--		oData      => HEX4
--	);
--		
--	hex5_seven_seg_controller : seven_seg_controller
--	port map(
--		iClk       => CLOCK_50,
--		iData      => SS_hex5_sig,
--		oData      => HEX5
--	);
end Structural;