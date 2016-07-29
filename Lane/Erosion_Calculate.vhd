library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.MyDataType.all;

entity Erosion_Calculate is
Port(
		clk_video				: in std_logic;
		rst_system				: in std_logic;		
		buf_sobel_cc_en 		: in std_logic;		
		Sobel_Cal_en 			: in std_logic;					
		Erosion_R1C1  			: in std_logic;
		Erosion_R2C1  			: in std_logic;		
		Erosion_R3C1  			: in std_logic;
		Erosion_R1C2  			: in std_logic;
		Erosion_R2C2  			: in std_logic;		
		Erosion_R3C2  			: in std_logic;
		Erosion_R1C3  			: in std_logic;
		Erosion_R2C3  			: in std_logic;		
		Erosion_R3C3  			: in std_logic;
		Erosion_Cnt				: buffer integer range 0 to 639:=0;
		Erosion_Bit 			: buffer std_logic;
		Erosion_Value			: inout Matrix_Buf_1Bit
	);
end Erosion_Calculate;

architecture Erosion_Calculate_arch of Erosion_Calculate is

begin

Erosion_Calculate:process(rst_system, clk_video)
variable Erosion_R2C2_temp : std_logic:='0';
begin
if rst_system = '0' then
	Erosion_Cnt <= 0;
else
	if rising_edge(clk_video) then
		if buf_sobel_cc_en = '1' then
			 if Sobel_Cal_en = '1' then				
				Erosion_R2C2_temp := 	Erosion_R1C1 and Erosion_R2C1 and Erosion_R3C1 and 
										Erosion_R1C2 and Erosion_R3C2 and 
										Erosion_R1C3 and Erosion_R2C3 and Erosion_R3C3;
				if Erosion_R2C2_temp = '1' then
					Erosion_Bit <= '1';
				else
					Erosion_Bit <= '0';
				end if;
			else				
				Erosion_Value(Erosion_Cnt) <= Erosion_Bit;
				if Erosion_Cnt < 639 then
					Erosion_Cnt <= Erosion_Cnt + 1;
				else
					Erosion_Cnt <= 0;
				end if;
			end if;
		else
			Erosion_Cnt <= 0;
		end if;
	end if;
end if;
end process Erosion_Calculate;


end Erosion_Calculate_arch;