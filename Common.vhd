package Common is

	-- Types for SRAM controller
   type t_rw is (RST, RD, WT);
	type t_fstate_write is (STANDBY, INIT, PULSE, FINISH);
	type t_fstate_read is (STANDBY, INIT, PULSE, LOAD, FINISH);
	
	-- Types for user logic (project_1.vhd)
	type t_ul is (RST, INITIALIZATION, TEST_MODE, PWM_GENERATION);
	type t_ul_program is (SIXTY, ONE20, ONE000);
	type t_ul_program_address is (STANDBY, LOAD);
	type t_ul_program_data is (STANDBY, LOAD);
	
end Common;

package body Common is
   -- subprogram bodies here
end Common;