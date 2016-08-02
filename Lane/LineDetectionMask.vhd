library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.MyDataType.all;
entity LineDetectionMask is
	Port(
			rst_system		: in std_logic;
			clk_video 		: in std_logic;
			buf_sobel_cc_en : in std_logic;
			buf_vga_en		: in std_logic;	
			cnt_video_hsync	: in  integer range 0 to 1715;	
			buf_data_state  : in std_logic_vector(1 downto 0);
			LDM_Cal_R1C1  	: in std_logic_vector(10-1 downto 0);
			LDM_Cal_R2C1  	: in std_logic_vector(10-1 downto 0);		
			LDM_Cal_R3C1  	: in std_logic_vector(10-1 downto 0);
			LDM_Cal_R1C2  	: in std_logic_vector(10-1 downto 0);
			LDM_Cal_R2C2  	: in std_logic_vector(10-1 downto 0);		
			LDM_Cal_R3C2  	: in std_logic_vector(10-1 downto 0);
			LDM_Cal_R1C3  	: in std_logic_vector(10-1 downto 0);
			LDM_Cal_R2C3  	: in std_logic_vector(10-1 downto 0);		
			LDM_Cal_R3C3  	: in std_logic_vector(10-1 downto 0);
			LDM_Cal_en		: inout std_logic;
			LDM_Cal_record	: inout std_logic_vector((4-1) downto 0);
			LDM_Cal_Buf_Src_X: in integer range 0 to 639;
			LDM_Cal_Buf_Src_Y: in integer range 0 to 479;
			LDM_Cal_Buf_X1	: inout integer range 0 to 639;
			LDM_Cal_Buf_Y1	: inout integer range 0 to 479;
			LDM_Cal_Buf_X2	: inout integer range 0 to 639;
			LDM_Cal_Buf_Y2	: inout integer range 0 to 479			
		);
end LineDetectionMask;

architecture LineDetectionMask_arch of LineDetectionMask is

begin


--############################################### Scharr Expression ###############################################--
--			 Col-1   Col-2  Col-3
--			[ R1C1 , R1C2 , R1C3 ]
--Matrix =	[ R2C1 , R2C2 , R2C3 ]
--			[ R3C1 , R3C2 , R3C3 ]

--			 		Col-1   Col-2  Col-3
--					[ -1  ,	  -1 , 	-1  ]
--	Gx	Matrix =	[ +2  ,	  +2 , 	+2  ]
--					[ -1  ,	  -1 , 	-1  ]

--			 		Col-1   Col-2  Col-3
--					[ -3 , 	 -10 , 	-3 ]
--	Gy	Matrix =	[  0 , 	  0  , 	 0 ]
--					[ +3 , 	 +10 , 	+3 ]
--############################################### Scharr Expression ###############################################--




LineDetectionMask:process(rst_system, clk_video)
begin
if rst_system = '0' then
	LDM_Cal_record <= "0000";	
	LDM_Cal_Buf_X1 <= 0;
	LDM_Cal_Buf_Y1 <= 0;	
	LDM_Cal_Buf_X2 <= 0;
	LDM_Cal_Buf_Y2 <= 0;	
	LDM_Cal_en <= '0';
else
	if rising_edge(clk_video) then
		if buf_sobel_cc_en = '1' then
			if buf_data_state(0) = '1' then
			-- if buf_data_state(0) = '0' then
				--sobel_x_cc_1 := SB_buf_0_data_1 + SB_buf_0_data_2 + SB_buf_0_data_2 + SB_buf_0_data_3;
				--sobel_x_cc_2 := SB_buf_2_data_1 + SB_buf_2_data_2 + SB_buf_2_data_2 + SB_buf_2_data_3;
				
				--sobel_y_cc_1 := SB_buf_0_data_1 + SB_buf_1_data_1 + SB_buf_1_data_1 + SB_buf_2_data_1;
				--sobel_y_cc_2 := SB_buf_0_data_3 + SB_buf_1_data_3 + SB_buf_1_data_3 + SB_buf_2_data_3;
				if((LDM_Cal_R2C1 = "0011111111")and(LDM_Cal_R2C2 = "0011111111")and(LDM_Cal_R2C3 = "0011111111")) then
					LDM_Cal_record(0) <= '1'; 
					LDM_Cal_Buf_X1 <= LDM_Cal_Buf_Src_X;
					LDM_Cal_Buf_Y1 <= LDM_Cal_Buf_Src_Y;
				else
					LDM_Cal_record(0) <= '0'; 
					LDM_Cal_Buf_X1 <= 0;
					LDM_Cal_Buf_Y1 <= 0;
				end if;
				--$$$$$$$$$$$$$$$$$ LDM Expression $$$$$$$$$$$$$$$$$--
				--LDM_x_cc_1 := LDM_Cal_R1C1 + LDM_Cal_R2C1 + LDM_Cal_R2C1 + LDM_Cal_R3C1;
				--LDM_x_cc_2 := LDM_Cal_R1C2 + LDM_Cal_R2C2 + LDM_Cal_R2C2 + LDM_Cal_R3C2;
				--LDM_x_cc_3 := LDM_Cal_R1C3 + LDM_Cal_R2C3 + LDM_Cal_R2C3 + LDM_Cal_R3C3;

				--LDM_y_cc_1 := LDM_Cal_R1C1 + LDM_Cal_R2C1 + LDM_Cal_R3C1;
				--LDM_y_cc_2 := 	LDM_Cal_R1C2 + LDM_Cal_R1C2 + 
				--				LDM_Cal_R2C2 + LDM_Cal_R2C2 + 
				--				LDM_Cal_R3C2 + LDM_Cal_R3C2 ;
				--LDM_y_cc_3 := LDM_Cal_R1C3 + LDM_Cal_R2C3 + LDM_Cal_R3C3;
				----$$$$$$$$$$$$$$$$$ LDM Expression $$$$$$$$$$$$$$$$$--								

				
				--abc 123
				--acb 132
				--bac 213
				--bca 231
				--cab 312
				--cba 321
				--if((LDM_x_cc_1 >= LDM_x_cc_2)and(LDM_x_cc_2 >= LDM_x_cc_3))then					
				--	LDM_XSCR <= (LDM_x_cc_1 - LDM_x_cc_2) + (LDM_x_cc_1 - LDM_x_cc_3) ;	
				--elsif((LDM_x_cc_1 >= LDM_x_cc_3)and(LDM_x_cc_3 >= LDM_x_cc_2))then
				--	LDM_XSCR <= (LDM_x_cc_1 - LDM_x_cc_2) + (LDM_x_cc_1 - LDM_x_cc_3) ;	
				--elsif((LDM_x_cc_2 >= LDM_x_cc_1)and(LDM_x_cc_1 >= LDM_x_cc_3))then
				--	LDM_XSCR <= (LDM_x_cc_2 - LDM_x_cc_1) + (LDM_x_cc_2 - LDM_x_cc_3) ;
				--elsif((LDM_x_cc_2 >= LDM_x_cc_3)and(LDM_x_cc_3 >= LDM_x_cc_1))then
				--	LDM_XSCR <= (LDM_x_cc_2 - LDM_x_cc_1) + (LDM_x_cc_2 - LDM_x_cc_3) ;
				--elsif((LDM_x_cc_3 >= LDM_x_cc_1)and(LDM_x_cc_1 >= LDM_x_cc_2))then
				--	LDM_XSCR <= (LDM_x_cc_3 - LDM_x_cc_1) + (LDM_x_cc_3 - LDM_x_cc_2) ;
				--elsif((LDM_x_cc_3 >= LDM_x_cc_2)and(LDM_x_cc_2 >= LDM_x_cc_1))then
				--	LDM_XSCR <= (LDM_x_cc_3 - LDM_x_cc_1) + (LDM_x_cc_3 - LDM_x_cc_2) ;
				--end if;

				--if((LDM_y_cc_1 >= LDM_y_cc_2)and(LDM_y_cc_2 >= LDM_y_cc_3))then					
				--	LDM_YSCR <= (LDM_y_cc_1 - LDM_y_cc_2) + (LDM_y_cc_1 - LDM_y_cc_3) ;	
				--elsif((LDM_y_cc_1 >= LDM_y_cc_3)and(LDM_y_cc_3 >= LDM_y_cc_2))then
				--	LDM_YSCR <= (LDM_y_cc_1 - LDM_y_cc_2) + (LDM_y_cc_1 - LDM_y_cc_3) ;	
				--elsif((LDM_y_cc_2 >= LDM_y_cc_1)and(LDM_y_cc_1 >= LDM_y_cc_3))then
				--	LDM_YSCR <= (LDM_y_cc_2 - LDM_y_cc_1) + (LDM_y_cc_2 - LDM_y_cc_3) ;
				--elsif((LDM_y_cc_2 >= LDM_y_cc_3)and(LDM_y_cc_3 >= LDM_y_cc_1))then
				--	LDM_YSCR <= (LDM_y_cc_2 - LDM_y_cc_1) + (LDM_y_cc_2 - LDM_y_cc_3) ;
				--elsif((LDM_y_cc_3 >= LDM_y_cc_1)and(LDM_y_cc_1 >= LDM_y_cc_2))then
				--	LDM_YSCR <= (LDM_y_cc_3 - LDM_y_cc_1) + (LDM_y_cc_3 - LDM_y_cc_2) ;
				--elsif((LDM_y_cc_3 >= LDM_y_cc_2)and(LDM_y_cc_2 >= LDM_y_cc_1))then
				--	LDM_YSCR <= (LDM_y_cc_3 - LDM_y_cc_1) + (LDM_y_cc_3 - LDM_y_cc_2) ;
				--end if;				
			else			
				LDM_Cal_record(3 downto 1) <= LDM_Cal_record(2 downto 0);
				if(LDM_Cal_record(3 downto 0) = "1111")then
					LDM_Cal_en <= '1';
					LDM_Cal_Buf_X2 <= LDM_Cal_Buf_Src_X;
					LDM_Cal_Buf_Y2 <= LDM_Cal_Buf_Src_Y;
				else
					LDM_Cal_en <= '0';
					LDM_Cal_Buf_X2 <= 0;
					LDM_Cal_Buf_Y2 <= 0;
				end if;	
			end if;
		else
			LDM_Cal_record <= "0000";	
			LDM_Cal_Buf_X1 <= 0;
			LDM_Cal_Buf_Y1 <= 0;	
			LDM_Cal_Buf_X2 <= 0;
			LDM_Cal_Buf_Y2 <= 0;	
			LDM_Cal_en <= '0';
		end if;
	end if;
end if;
end process LineDetectionMask;


end LineDetectionMask_arch;