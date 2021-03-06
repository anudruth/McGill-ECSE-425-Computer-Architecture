LIBRARY ieee;
USE ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

ENTITY pipeline_tb IS
END pipeline_tb;

ARCHITECTURE behaviour OF pipeline_tb IS

COMPONENT pipeline IS
port (clk : in std_logic;
      a, b, c, d, e : in integer;
      op1, op2, op3, op4, op5, final_output : out integer
  );
END COMPONENT;

--The input signals with their initial values
SIGNAL clk: STD_LOGIC := '0';
SIGNAL s_a, s_b, s_c, s_d, s_e : INTEGER := 0;
SIGNAL s_op1, s_op2, s_op3, s_op4, s_op5, s_final_output : INTEGER := 0;

CONSTANT clk_period : time := 1 ns;

BEGIN
dut: pipeline
PORT MAP(clk, s_a, s_b, s_c, s_d, s_e, s_op1, s_op2, s_op3, s_op4, s_op5, s_final_output);

 --clock process
clk_process : PROCESS
BEGIN
	clk <= '0';
	WAIT FOR clk_period/2;
	clk <= '1';
	WAIT FOR clk_period/2;
END PROCESS;
 

stim_process: PROCESS
BEGIN   
	--TODO: Stimulate the inputs for the pipelined equation ((a + b) * 42) - (c * d * (a - e)) and assert the results
	REPORT "Testing all zeros";
	
	s_a <= 0;
	s_b <= 0;
	s_c <= 0;
	s_d <= 0;
	s_e <= 0;
	
	WAIT FOR 3 * clk_period;
	ASSERT(s_op1 = 0) REPORT "OP1 should be 0, but was " & integer'image(s_op1) SEVERITY ERROR;
	ASSERT(s_op2 = 0) REPORT "OP2 should be 0, but was " & integer'image(s_op2) SEVERITY ERROR;
	ASSERT(s_op3 = 0) REPORT "OP3 should be 0, but was " & integer'image(s_op3) SEVERITY ERROR;
	ASSERT(s_op4 = 0) REPORT "OP4 should be 0, but was " & integer'image(s_op4) SEVERITY ERROR;
	ASSERT(s_op5 = 0) REPORT "OP5 should be 0, but was " & integer'image(s_op5) SEVERITY ERROR;
	ASSERT(s_final_output = 0) REPORT "Final output should be 0, but was " & integer'image(s_final_output) SEVERITY ERROR;
	
	REPORT "_________________________________";
	
	REPORT "Testing valid numbers. maintaing numbers for 3 periods";

	s_a <= 3;
	s_b <= 4;
	s_c <= -2;
	s_d <= 1;
	s_e <= 5;
	
	WAIT FOR 3 * clk_period;
	ASSERT(s_op1 = 7) REPORT "OP1 should be 7, but was " & integer'image(s_op1) SEVERITY ERROR;
	ASSERT(s_op2 = 294) REPORT "OP2 should be 294, but was " & integer'image(s_op2) SEVERITY ERROR;
	ASSERT(s_op3 = -2) REPORT "OP3 should be -2, but was " & integer'image(s_op3) SEVERITY ERROR;
	ASSERT(s_op4 = -2) REPORT "OP4 should be -2, but was " & integer'image(s_op4) SEVERITY ERROR;
	ASSERT(s_op5 = 4) REPORT "OP5 should be 4, but was " & integer'image(s_op5) SEVERITY ERROR;
	ASSERT(s_final_output = 290) REPORT "Final output should be 290, but was " & integer'image(s_final_output) SEVERITY ERROR;
	
	REPORT "_________________________________";

	REPORT "Testing each stage of pipeline. all input flushed after 1 period";
	
	s_a <= 0;
	s_b <= 6;
	s_c <= -2;
	s_d <= -3;
	s_e <= 10;

	WAIT FOR 1 * clk_period;

	ASSERT(s_op1 = 6) REPORT "OP1 should be 6, but was " & integer'image(s_op1) SEVERITY ERROR;		-- in first period only op1, op3, op4 should be evaluated
	ASSERT(s_op3 = 6) REPORT "OP3 should be 6, but was " & integer'image(s_op3) SEVERITY ERROR;
	ASSERT(s_op4 = -10) REPORT "OP4 should be -10, but was " & integer'image(s_op4) SEVERITY ERROR;
	
	s_a <= 0;
	s_b <= 0;
	s_c <= 0;
	s_d <= 0;
	s_e <= 0;
	
	WAIT FOR 1 * clk_period;
	
	ASSERT(s_op2 = 252) REPORT "OP2 should be 252, but was " & integer'image(s_op2) SEVERITY ERROR;		-- in second period 
	ASSERT(s_op5 = -60) REPORT "OP5 should be -60, but was " & integer'image(s_op5) SEVERITY ERROR;
	ASSERT(s_final_output = 312) REPORT "Final output should be 312, but was " & integer'image(s_final_output) SEVERITY ERROR;	

	REPORT "_________________________________";

	REPORT "Testing full pipeline";
	
	s_a <= 1;
	s_b <= 2;
	s_c <= 7;
	s_d <= 5;
	s_e <= 9;
	
	WAIT FOR 1 * clk_period;

	s_a <= 0;
	s_b <= 6;
	s_c <= -2;
	s_d <= -3;
	s_e <= 10;
	
	ASSERT(s_op1 = 3) REPORT "OP1 should be 3 after first period for first set of numbers, but was " & integer'image(s_op1) SEVERITY ERROR;		
	ASSERT(s_op3 = 35) REPORT "OP3 should be 35 after first period for first set of numbers, but was " & integer'image(s_op3) SEVERITY ERROR;
	ASSERT(s_op4 = -8) REPORT "OP4 should be -8 after first period for first set of numbers, but was " & integer'image(s_op4) SEVERITY ERROR;

	WAIT FOR 1 * clk_period;

	ASSERT(s_op2 = 126) REPORT "OP2 should be 126 after second period for first set of numbers, but was " & integer'image(s_op2) SEVERITY ERROR;		
	ASSERT(s_op5 = -280) REPORT "OP5 should be -280 after second period for first set of numbers, but was " & integer'image(s_op5) SEVERITY ERROR;
	ASSERT(s_final_output = 406) REPORT "Final output should be 406 after second period for first set of numbers, but was " & integer'image(s_final_output) SEVERITY ERROR;	

	ASSERT(s_op1 = 6) REPORT "OP1 should be 6 after second period for second set of numbers, but was " & integer'image(s_op1) SEVERITY ERROR;		
	ASSERT(s_op3 = 6) REPORT "OP3 should be 6 after second period for second set of numbers, but was " & integer'image(s_op3) SEVERITY ERROR;
	ASSERT(s_op4 = -10) REPORT "OP4 should be -10 after second period for second set of numbers, but was " & integer'image(s_op4) SEVERITY ERROR;
	
	WAIT FOR 1 * clk_period;
	-- flushing all inputs
	s_a <= 0;
	s_b <= 0;
	s_c <= 0;
	s_d <= 0;
	s_e <= 0;
	
	ASSERT(s_op2 = 252) REPORT "OP2 should be 252 after third period for second set of numbers, but was " & integer'image(s_op2) SEVERITY ERROR;		
	ASSERT(s_op5 = -60) REPORT "OP5 should be -60 after third period for second set of numbers, but was " & integer'image(s_op5) SEVERITY ERROR;
	ASSERT(s_final_output = 312) REPORT "Final output should be 312 after third period for second set of numbers, but was " & integer'image(s_final_output) SEVERITY ERROR;	


	WAIT FOR 2 * clk_period;

	ASSERT(s_op1 = 0) REPORT "OP1 should now be 0, but was " & integer'image(s_op1) SEVERITY ERROR;
	ASSERT(s_op2 = 0) REPORT "OP2 should now be 0, but was " & integer'image(s_op2) SEVERITY ERROR;
	ASSERT(s_op3 = 0) REPORT "OP3 should now be 0, but was " & integer'image(s_op3) SEVERITY ERROR;
	ASSERT(s_op4 = 0) REPORT "OP4 should now be 0, but was " & integer'image(s_op4) SEVERITY ERROR;
	ASSERT(s_op5 = 0) REPORT "OP5 should now be 0, but was " & integer'image(s_op5) SEVERITY ERROR;
	ASSERT(s_final_output = 0) REPORT "Final output should be 0, but was " & integer'image(s_final_output) SEVERITY ERROR;
	
	REPORT "_________________________________";
	
	WAIT;
END PROCESS stim_process;
END;
