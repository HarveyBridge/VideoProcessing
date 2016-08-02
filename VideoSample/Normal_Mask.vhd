library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.MyDataType.all;
--############################################### Sobel Expression ###############################################--
--			 Col-1   Col-2  Col-3
--			[ R1C1 , R1C2 , R1C3 ]
--Matrix =	[ R2C1 , R2C2 , R2C3 ]
--			[ R3C1 , R3C2 , R3C3 ]

--			 		Col-1   Col-2  Col-3
--					[ -1 , 	  0 , 	+1 ]
--	Gx	Matrix =	[ -2 , 	  0 , 	+2 ]
--					[ -1 , 	  0 , 	+1 ]

--			 		Col-1   Col-2  Col-3
--					[ -1 , 	 -2 , 	-1 ]
--	Gy	Matrix =	[  0 , 	  0 , 	 0 ]
--					[ +1 , 	 +2 , 	+1 ]

--############################################### Sobel Expression ###############################################--

entity Normal_Mask is
	Port(
			rst_system	: in std_logic;
			clk_video 	: in std_logic;
			buf_sobel_cc_en : in std_logic;
			buf_vga_en		: in std_logic;	
			cnt_video_hsync	: in  integer range 0 to 1715;	
			buf_data_state  : in std_logic_vector(1 downto 0);
			Matrix_R1C1  : in std_logic_vector((8-1) downto 0);
			Matrix_R2C1  : in std_logic_vector((8-1) downto 0);		
			Matrix_R3C1  : in std_logic_vector((8-1) downto 0);
			Matrix_R1C2  : in std_logic_vector((8-1) downto 0);
			Matrix_R2C2  : in std_logic_vector((8-1) downto 0);		
			Matrix_R3C2  : in std_logic_vector((8-1) downto 0);
			Matrix_R1C3  : in std_logic_vector((8-1) downto 0);
			Matrix_R2C3  : in std_logic_vector((8-1) downto 0);		
			Matrix_R3C3  : in std_logic_vector((8-1) downto 0);
			DataOutSequence : inout Matrix_Buf;	
			SB_XSCR : buffer std_logic_vector((10-1) downto 0);
			SB_YSCR : buffer std_logic_vector((10-1) downto 0);
			SB_SUM : buffer std_logic_vector((11-1) downto 0);
			SB_buf_redata : inout Sobel_buf;			
			redata_cnt : buffer integer range 0 to 650			
			--SB_CRB_data : in std_logic:='0';
		);
end Normal_Mask;

architecture Normal_Mask_arch of Normal_Mask is
begin
Normal_Mask:process(rst_system, clk_video)
variable sobel_x_cc_1 : std_logic_vector(9 downto 0);
variable sobel_x_cc_2 : std_logic_vector(9 downto 0);
variable sobel_y_cc_1 : std_logic_vector(9 downto 0);
variable sobel_y_cc_2 : std_logic_vector(9 downto 0);
begin
if rst_system = '0' then
	SB_XSCR <= "0000000000";
	SB_YSCR <= "0000000000";
	SB_SUM  <= "00000000000";
	--SB_CRB_data <= '0';
-- system reset
	redata_cnt <= 0 ;	
else
	if rising_edge(clk_video) then
		if buf_sobel_cc_en = '1' then
			if buf_data_state(0) = '1' then
				--$$$$$$$$$$$$$$$$$ Sobel Expression $$$$$$$$$$$$$$$$$--
				sobel_x_cc_1 := "0000000000" + Matrix_R1C1 + Matrix_R2C1 + Matrix_R2C1 + Matrix_R3C1;
				sobel_x_cc_2 := "0000000000" + Matrix_R1C3 + Matrix_R2C3 + Matrix_R2C3 + Matrix_R3C3;

				sobel_y_cc_1 := "0000000000" + Matrix_R1C1 + Matrix_R1C2 + Matrix_R1C2 + Matrix_R1C3;
				sobel_y_cc_2 := "0000000000" + Matrix_R3C1 + Matrix_R3C2 + Matrix_R3C2 + Matrix_R3C3;
				----$$$$$$$$$$$$$$$$$ Sobel Expression $$$$$$$$$$$$$$$$$--								

				if sobel_x_cc_1 >= sobel_x_cc_2 then
					SB_XSCR <= sobel_x_cc_1 - sobel_x_cc_2;
				else
					SB_XSCR <= sobel_x_cc_2 - sobel_x_cc_1;
				end if;
				
				if sobel_y_cc_1 >= sobel_y_cc_2 then
					SB_YSCR <= sobel_y_cc_1 - sobel_y_cc_2;
				else
					SB_YSCR <= sobel_y_cc_2 - sobel_y_cc_1;
				end if;
			else
-- sum  X_sobel  &  Y_sobel
				SB_SUM <= "00000000000"+SB_XSCR+SB_YSCR;
-- put SUM_sobel to SB_buf_redata(0~640) SB_SUM 10 downto 0 9bits + 9bits							
				if SB_SUM > "000111111111" then --"0001 1111 1111"
					SB_buf_redata(redata_cnt) <= "11111111";
				else
					SB_buf_redata(redata_cnt) <= SB_SUM(9 downto 2); 
				end if;
-- counter redata_cnt to get SB_buf_redata address
				if redata_cnt < 639 then
					redata_cnt <= redata_cnt + 1;
				else
					redata_cnt <= 0;
				end if;
			end if;
		else
			SB_XSCR <= "0000000000";
			SB_YSCR <= "0000000000";
			--SB_CRB_data <= '0';
-- when cnt_video_hsync > 1280, let redata_cnt be reset
			redata_cnt <= 0;
		end if;
	end if;
end if;
end process Normal_Mask;


end Normal_Mask_arch;