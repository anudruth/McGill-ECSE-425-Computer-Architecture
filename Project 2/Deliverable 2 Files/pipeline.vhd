library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity pipeline is
port (clk : in std_logic;
      a, b, c, d, e : in integer;
      op1, op2, op3, op4, op5, final_output : out integer
  );
end pipeline;

architecture behavioral of pipeline is

signal op1_temp, op2_temp, op3_temp, op4_temp, op5_temp: integer := 0;
signal op1_prop, op2_prop, op3_prop, op4_prop, op5_prop: integer := 0;


begin
-- todo: complete this
process (clk)
begin
	if rising_edge(clk) then
		op1_temp <= op1_prop;
		op2_temp <= op2_prop;
		op3_temp <= op3_prop;
		op4_temp <= op4_prop;
		op5_temp <= op5_prop;
	end if;
	
end process;

op1_prop <= a + b;
op2_prop <= op1_temp * 42;
op3_prop <= c * d;
op4_prop <= a - e;
op5_prop <= op3_temp * op4_temp;
final_output <= op2_temp - op5_temp;

op1 <= op1_temp;
op2 <= op2_temp;
op3 <= op3_temp;
op4 <= op4_temp;
op5 <= op5_temp;


end behavioral;