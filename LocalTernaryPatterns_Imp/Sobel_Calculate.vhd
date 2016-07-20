library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.MyDataType.all;
entity Sobel_Calculate is
	Port(
			rst_system	: in std_logic;
			clk_video 	: in std_logic;
			buf_sobel_cc_en : in std_logic;
			buf_vga_en		: in std_logic;	
			cnt_video_hsync	: in  integer range 0 to 1715;	
			buf_data_state  : in std_logic_vector(1 downto 0);
			Sobel_Cal_R1C1  : in std_logic_vector(10-1 downto 0);
			Sobel_Cal_R2C1  : in std_logic_vector(10-1 downto 0);		
			Sobel_Cal_R3C1  : in std_logic_vector(10-1 downto 0);
			Sobel_Cal_R1C2  : in std_logic_vector(10-1 downto 0);
			Sobel_Cal_R2C2  : in std_logic_vector(10-1 downto 0);		
			Sobel_Cal_R3C2  : in std_logic_vector(10-1 downto 0);
			Sobel_Cal_R1C3  : in std_logic_vector(10-1 downto 0);
			Sobel_Cal_R2C3  : in std_logic_vector(10-1 downto 0);		
			Sobel_Cal_R3C3  : in std_logic_vector(10-1 downto 0);
			Sobel_Cal_en	: inout std_logic;
			SB_XSCR : buffer std_logic_vector((10-1) downto 0);
			SB_YSCR : buffer std_logic_vector((10-1) downto 0);
			SB_SUM : buffer std_logic_vector((11-1) downto 0);
			SB_buf_redata : inout Sobel_buf;
			redata_cnt : buffer integer range 0 to 650						
			--SB_CRB_data : in std_logic:='0';
		);
end Sobel_Calculate;

architecture Sobel_Calculate_arch of Sobel_Calculate is

begin
Sobel_Calculate:process(rst_system, clk_video)
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
	Sobel_Cal_en <= '0';
else
	if rising_edge(clk_video) then
		if buf_sobel_cc_en = '1' then
			if buf_data_state(0) = '1' then
			-- if buf_data_state(0) = '0' then
				--sobel_x_cc_1 := SB_buf_0_data_1 + SB_buf_0_data_2 + SB_buf_0_data_2 + SB_buf_0_data_3;
				--sobel_x_cc_2 := SB_buf_2_data_1 + SB_buf_2_data_2 + SB_buf_2_data_2 + SB_buf_2_data_3;
				
				--sobel_y_cc_1 := SB_buf_0_data_1 + SB_buf_1_data_1 + SB_buf_1_data_1 + SB_buf_2_data_1;
				--sobel_y_cc_2 := SB_buf_0_data_3 + SB_buf_1_data_3 + SB_buf_1_data_3 + SB_buf_2_data_3;

				sobel_x_cc_1 := Sobel_Cal_R1C1 + Sobel_Cal_R2C1 + Sobel_Cal_R2C1 + Sobel_Cal_R3C1;
				sobel_x_cc_2 := Sobel_Cal_R1C3 + Sobel_Cal_R2C3 + Sobel_Cal_R2C3 + Sobel_Cal_R3C3;

				sobel_y_cc_1 := Sobel_Cal_R1C1 + Sobel_Cal_R1C2 + Sobel_Cal_R1C2 + Sobel_Cal_R1C3;
				sobel_y_cc_2 := Sobel_Cal_R3C1 + Sobel_Cal_R3C2 + Sobel_Cal_R3C2 + Sobel_Cal_R3C3;
				
				

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
				Sobel_Cal_en <= '0';
			else
				Sobel_Cal_en <= '1';
				--if ((SB_XSCR > "0001100000" and SB_XSCR < "0011100000") or (SB_YSCR > "0001100000" and SB_YSCR < "0011100000")) then
					-- SB_CRB_data <= '1';
				
-- sum  X_sobel  &  Y_sobel
				SB_SUM <= "00000000000"+SB_XSCR+SB_YSCR;
-- put SUM_sobel to SB_buf_redata(0~640) SB_SUM 10 downto 0 9bits + 9bits							
				if SB_SUM > "00111111111" then
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
			Sobel_Cal_en <= '0';
		end if;
	end if;
end if;
end process Sobel_Calculate;


end Sobel_Calculate_arch;