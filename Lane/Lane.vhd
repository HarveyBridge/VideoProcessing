----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:25:14 07/20/2016 
-- Design Name: 
-- Module Name:    Lane - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.MyDataType.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Lane is
    Port ( 	clk_video : in  STD_LOGIC;
    		rst_system : in STD_LOGIC;
           	data_video : in  STD_LOGIC_VECTOR (7 downto 0);
           	scl : out  STD_LOGIC;
           	sda : inout  STD_LOGIC;
           	h_sync_vga : out  STD_LOGIC;
           	v_sync_vga : out  STD_LOGIC;
           	r_vga : out  STD_LOGIC_VECTOR (2 downto 0);
           	g_vga : out  STD_LOGIC_VECTOR (2 downto 0);
           	b_vga : out  STD_LOGIC_VECTOR (2 downto 0);
           	DebugMux	:in std_logic_vector(3 downto 0);
           	ImageSelect	:in std_logic
           	);
end Lane;

architecture Lane_arch of Lane is

signal boundary_edge_H : integer range 0 to 639:=250; -- 100 to 250
signal boundary_edge_V : integer range 0 to 639:=300; -- 100 to 300
--########## Component Defination ###################################################################################--	
signal buf_vga_Y : Matrix_Buf;
signal buf_vga_Y2 : Matrix_Buf;
signal buf_vga_Y_buf : std_logic_vector(7 downto 0);
signal buf_vga_Y_in_cnt : integer range 0 to 639:=0;
signal buf_vga_Y_out_cnt : integer range 0 to 639:=639;
signal buf_vga_state : std_logic_vector(1 downto 0):="00";
--
signal f_video_en : std_logic:='Z'; --Field
signal cnt_video_en : std_logic:='0';
signal cnt_vga_en : std_logic:='0';
signal buf_vga_en : std_logic:='0';
signal cnt_video_hsync : integer range 0 to 1715:=0;
signal f0_vga_en : std_logic:='0'; --Field 0
signal black_vga_en : std_logic:='0';
signal cnt_h_sync_vga : integer range 0 to 857:=0;
signal cnt_v_sync_vga : integer range 0 to 524:=0;
signal sync_vga_en : std_logic:='0';

component video_in
	Port ( 
            clk_video  : IN  std_logic;
            rst_system : IN  std_logic;
            data_video : IN  std_logic_vector(7 downto 0)  ;
            f_video_en : OUT std_logic;
            cnt_video_en : OUT std_logic;
            cnt_vga_en : OUT std_logic ;
            buf_vga_en : OUT std_logic ;
            cnt_video_hsync : out  integer range 0 to 1715;
            f0_vga_en : out std_logic;
            black_vga_en :out  std_logic;
            cnt_h_sync_vga :out integer range 0 to 857;
            cnt_v_sync_vga :out integer range 0 to 524;
            sync_vga_en : out  std_logic;
            v_sync_vga : out  std_logic;
            h_sync_vga : out  std_logic
        );
end component;

component i2c
	Port ( 
			clk_video  : IN  std_logic;
            rst_system : IN  std_logic;
            scl : out std_logic;
            sda : inout std_logic
         );

end component;

------------------------------------|
--Sobel_Cal Matrix = Matrix Buffer--|
------------------------------------|
signal Sobel_Cal_Column_1 : Matrix_Buf;
signal Sobel_Cal_R1C1 : std_logic_vector((10-1) downto 0):="0000000000";
signal Sobel_Cal_R2C1 : std_logic_vector((10-1) downto 0):="0000000000";
signal Sobel_Cal_R3C1 : std_logic_vector((10-1) downto 0):="0000000000";

signal Sobel_Cal_Column_2 : Matrix_Buf;
signal Sobel_Cal_R1C2 : std_logic_vector((10-1) downto 0):="0000000000";
signal Sobel_Cal_R2C2 : std_logic_vector((10-1) downto 0):="0000000000";
signal Sobel_Cal_R3C2 : std_logic_vector((10-1) downto 0):="0000000000";

signal Sobel_Cal_Column_3 : Matrix_Buf;
signal Sobel_Cal_R1C3 : std_logic_vector((10-1) downto 0):="0000000000";
signal Sobel_Cal_R2C3 : std_logic_vector((10-1) downto 0):="0000000000";
signal Sobel_Cal_R3C3 : std_logic_vector((10-1) downto 0):="0000000000";

signal Sobel_Cal_Buf_Cnt	 : integer range 0 to 639:=0;
signal Sobel_Cal_Buf_Length_Max : integer range 0 to 639:=639;
signal Sobel_Cal_en				: std_logic;

component BufferToMatrix3x3 is
	Port(
			clk_video	: in std_logic;
			rst_system	: in std_logic;
			data_video 	: in std_logic_vector(7 downto 0);
			buf_vga_en	: in std_logic;	
			buf_data_state: in std_logic_vector(1 downto 0);
			cnt_video_hsync : in  integer range 0 to 1715;
			Matrix_R1C1	: buffer std_logic_vector(10-1 downto 0);
			Matrix_R2C1	: buffer std_logic_vector(10-1 downto 0);
			Matrix_R3C1	: buffer std_logic_vector(10-1 downto 0);
			Matrix_R1C2	: buffer std_logic_vector(10-1 downto 0);
			Matrix_R2C2	: buffer std_logic_vector(10-1 downto 0);
			Matrix_R3C2	: buffer std_logic_vector(10-1 downto 0);
			Matrix_R1C3	: buffer std_logic_vector(10-1 downto 0);
			Matrix_R2C3	: buffer std_logic_vector(10-1 downto 0);
			Matrix_R3C3	: buffer std_logic_vector(10-1 downto 0);
			Matrix_Buf_Cnt	 : buffer integer range 0 to 639:=0
		);
end component;

----------------------|
-- Sobel Calculate ---|
----------------------|
signal SB_XSCR : std_logic_vector((10-1) downto 0):="0000000000";
signal SB_YSCR : std_logic_vector((10-1) downto 0):="0000000000";
signal SB_SUM : std_logic_vector((11-1) downto 0):="00000000000";
signal SB_buf_redata : Sobel_buf;
signal redata_cnt : integer range 0 to 650:=0;

component Sobel_Calculate is
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
end component;
--########## Component Defination ###################################################################################--	

------------------|
-- Buffer State --|
------------------|
signal range_total_cnt : integer range 0 to 1289:=0;
signal range_total_cnt_en : std_logic:='0';
signal buf_Y_temp_en : std_logic:='0';
signal SB_buf_012_en : std_logic:='0';
signal buf_sobel_cc_en : std_logic:='0';
signal buf_sobel_cc_delay : integer range 0 to 3:=0;
signal SBB_buf_en : std_logic:='0';
signal buf_data_state : std_logic_vector(1 downto 0):="00";


begin


--########## Component Defination ###################################################################################--	
VIDEO_IN2 : video_in
		port map (
    clk_video  =>clk_video,
    rst_system =>rst_system,
	data_video =>data_video,
    f_video_en =>f_video_en,
    cnt_video_en =>cnt_video_en,
    cnt_vga_en =>cnt_vga_en,
    buf_vga_en =>buf_vga_en,
    cnt_video_hsync =>cnt_video_hsync,
    f0_vga_en =>f0_vga_en,
    black_vga_en =>black_vga_en,
    cnt_h_sync_vga =>cnt_h_sync_vga,
    cnt_v_sync_vga =>cnt_v_sync_vga,
    sync_vga_en =>sync_vga_en,
    v_sync_vga =>v_sync_vga,
    h_sync_vga =>h_sync_vga
                
			);
i2c_1 :i2c
		port map (
                rst_system => rst_system,
                clk_video => clk_video,
                scl => scl,
                sda => sda           
			);


Sobel_Cal_BTM3x3 : BufferToMatrix3x3
	port map (
		clk_video 		=> clk_video,
		rst_system 		=> rst_system,		
		buf_vga_en 		=> buf_vga_en,
		buf_data_state 	=> buf_data_state,
		cnt_video_hsync => cnt_video_hsync,

		data_video 		=> data_video(7 downto 0),
		Matrix_R1C1 	=> Sobel_Cal_R1C1,
		Matrix_R2C1 	=> Sobel_Cal_R2C1,
		Matrix_R3C1 	=> Sobel_Cal_R3C1,
		Matrix_R1C2 	=> Sobel_Cal_R1C2,
		Matrix_R2C2 	=> Sobel_Cal_R2C2,
		Matrix_R3C2 	=> Sobel_Cal_R3C2,
		Matrix_R1C3 	=> Sobel_Cal_R1C3,
		Matrix_R2C3 	=> Sobel_Cal_R2C3,
		Matrix_R3C3 	=> Sobel_Cal_R3C3,
		Matrix_Buf_Cnt 	=> Sobel_Cal_Buf_Cnt
		);
Sobel_Cal_block: Sobel_Calculate
	port map(
		clk_video 		=> clk_video,
		rst_system 		=> rst_system,		
		buf_vga_en 		=> buf_vga_en,
		cnt_video_hsync => cnt_video_hsync,
		buf_data_state 	=> buf_data_state,
		buf_sobel_cc_en => buf_sobel_cc_en,
		
		Sobel_Cal_R1C1  => Sobel_Cal_R1C1,
		Sobel_Cal_R2C1  => Sobel_Cal_R2C1,
		Sobel_Cal_R3C1  => Sobel_Cal_R3C1,
		Sobel_Cal_R1C2  => Sobel_Cal_R1C2,
		Sobel_Cal_R2C2  => Sobel_Cal_R2C2,
		Sobel_Cal_R3C2  => Sobel_Cal_R3C2,		
		Sobel_Cal_R1C3  => Sobel_Cal_R1C3,
		Sobel_Cal_R2C3  => Sobel_Cal_R2C3,
		Sobel_Cal_R3C3  => Sobel_Cal_R3C3,
		Sobel_Cal_en	=> Sobel_Cal_en,
		SB_XSCR 		=> SB_XSCR,
		SB_YSCR 		=> SB_YSCR,
		SB_SUM 			=> SB_SUM,
		SB_buf_redata 	=> SB_buf_redata,
		redata_cnt 		=> redata_cnt
		);		
--########## Component Defination ###################################################################################--			
buf_vga_Y(buf_vga_Y_in_cnt)<= buf_vga_Y_buf ;


--VGA-buffer-8bit------------------------------------------------------------------------------------------------
process(rst_system, clk_video)
begin
if rst_system = '0' then
	buf_vga_state <= "00";
	buf_vga_Y_in_cnt <= 0;
else
	if rising_edge(clk_video) then
		if (buf_vga_en = '1' and cnt_video_hsync < 1280) then
			case buf_vga_state is
				when "00" => buf_vga_state <= "01";
				when "01" => buf_vga_state <= "10";
								 buf_vga_Y2(buf_vga_Y_in_cnt) <= data_video(7 downto 0);
								 if buf_vga_Y_in_cnt = 639 then
									 buf_vga_Y_in_cnt <= 0;
								 else
									 buf_vga_Y_in_cnt <= buf_vga_Y_in_cnt + 1;
								 end if;
				when "10" => buf_vga_state <= "11";
				when "11" => buf_vga_state <= "00";
								 buf_vga_Y2(buf_vga_Y_in_cnt) <= data_video(7 downto 0);
								 if buf_vga_Y_in_cnt = 639 then
									 buf_vga_Y_in_cnt <= 0;
								 else
									 buf_vga_Y_in_cnt <= buf_vga_Y_in_cnt + 1;
								 end if;
				when others => null;
			end case;
		else
			
			buf_vga_state <= "00";
			buf_vga_Y_in_cnt <= 0;
		end if;
	end if;
end if;
end process;
--VGA-buffer-8bit------------------------------------------------------------------------------------------------


--############################################### Buffer State ###############################################--
Buffer_State:process(rst_system, clk_video)
begin
if rst_system = '0' then
	range_total_cnt <= 0;
	range_total_cnt_en <= '0';
	buf_Y_temp_en <= '0';
	SB_buf_012_en <= '0';
	buf_sobel_cc_en <= '0';
	buf_sobel_cc_delay <= 0;
	SBB_buf_en <= '0';
	buf_data_state <= "00";
	--LBP_Data_State <= "00";--######### new buffer matrix == State #########--
else
	if rising_edge(clk_video) then
		 if (buf_vga_en = '1' and f_video_en = '0' and cnt_video_hsync < 1290) then
		--if (buf_vga_en = '1' and cnt_video_hsync < 1290) then -- my pc
			if buf_data_state = "11" then
				buf_data_state <= "00";
			else
				buf_data_state <= buf_data_state + '1';
			end if;
			----######### new buffer matrix == State #########--
			--if LBP_Data_State = "11" then
			--	LBP_Data_State <= "00";
			--else
			--	LBP_Data_State <= LBP_Data_State + '1';
			--end if;
			----######### new buffer matrix == State #########--

			if (cnt_video_hsync >= 0 and cnt_video_hsync < 1290 and cnt_v_sync_vga >= 0 and cnt_v_sync_vga < 480) then
				if range_total_cnt_en = '0' then
					if buf_data_state = "11" then
						range_total_cnt_en <= '1';
						SBB_buf_en <= '1';
						SB_buf_012_en <= '1';
						buf_sobel_cc_en <= '1';
					end if;

					----######### new buffer matrix == State #########--
					--if LBP_Data_State = "11"  then
					--	range_total_cnt_en <= '1';
					--	SBB_buf_en <= '1';
					--	SB_buf_012_en <= '1';
					--	buf_sobel_cc_en <= '1';
					--end if;
					----######### new buffer matrix == State #########--
				else
					if range_total_cnt < 1290 then
						SBB_buf_en <= '1';
						SB_buf_012_en <= '1';
						buf_sobel_cc_en <= '1';
					else
						SBB_buf_en <= '0';
						SB_buf_012_en <= '0';
						buf_sobel_cc_en <= '0';
					end if;
					
					if range_total_cnt = 1289 then
						range_total_cnt <= 1289;
					else
						range_total_cnt <= range_total_cnt + 1;
					end if;
				end if;
			else
				if cnt_v_sync_vga > 480 then
					buf_sobel_cc_delay <= 0;
				end if;
				range_total_cnt <= 0;
				range_total_cnt_en <= '0';
				SB_buf_012_en <= '0';
				buf_sobel_cc_en <= '0';
				SBB_buf_en <= '0';
			end if;
		else
			range_total_cnt <= 0;
			range_total_cnt_en <= '0';
			SB_buf_012_en <= '0';
			buf_sobel_cc_en <= '0';
			SBB_buf_en <= '0';
			buf_data_state <= "00";			
			--LBP_Data_State <= "00"; --######### new buffer matrix == State #########--
		end if;
	end if;
end if;
end process Buffer_State;
--############################################### Buffer State ###############################################--



--############################################### Display VGA ##############################################-- 
Display_VGA:process(rst_system, clk_video)
begin
if rst_system = '0' then
	r_vga <= "000";
	g_vga <= "000";
	b_vga <= "000";
	buf_vga_Y_out_cnt <= 0;
else
	if rising_edge(clk_video) then
			-- even  odd
		-- if (((f_video_en = '0' and black_vga_en = '0') or (f_video_en = '1' and black_vga_en = '1')) and cnt_h_sync_vga > 1 and cnt_h_sync_vga < 640 and cnt_v_sync_vga > 1 and cnt_v_sync_vga < 480)   then
				
				
			-- r_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
			-- g_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
			-- b_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
			
			
			-- -- ((f_video_en = '0' and black_vga_en = '0') or (f_video_en = '1' and black_vga_en = '1'))
			-- cnt_v_sync_vga 0 ~ 524 ==> 480
			-- cnt_h_sync_vga 0 ~ 857 ==> 640
		if cnt_v_sync_vga > 1 and cnt_v_sync_vga < 481 then
			if cnt_v_sync_vga > 1 and cnt_v_sync_vga < 480 then	
				if cnt_h_sync_vga > 1 and cnt_h_sync_vga < 640 then	
					buf_vga_Y_out_cnt <= buf_vga_Y_out_cnt - 1;	
					r_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
					g_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
					b_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
					 --r_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);
					 --g_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);
					 --b_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);								
					-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ Catch Special Range $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ --
						if((cnt_h_sync_vga > 100 and cnt_h_sync_vga < boundary_edge_H)and(cnt_v_sync_vga > 100 and cnt_v_sync_vga < boundary_edge_V) )then
							if((cnt_v_sync_vga > 100 and cnt_v_sync_vga < 102)or(cnt_v_sync_vga > (boundary_edge_V-2) and cnt_v_sync_vga < boundary_edge_V))then
								r_vga <= "111";
								g_vga <= "000";
								b_vga <= "000";
							else					
								if((cnt_h_sync_vga > 100 and cnt_h_sync_vga < 102)or(cnt_h_sync_vga > (boundary_edge_H-2) and cnt_h_sync_vga < boundary_edge_H))then					
									r_vga <= "000";
									g_vga <= "111";							
									b_vga <= "000";
								else
									-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ Inner Special Range 150x200 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ --
									--r_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);
									--g_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);
									--b_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);
									r_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
									g_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
									b_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
									-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ Inner Special Range 150x200 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ --
								end if;
							end if;
						else		
							--r_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);
							--g_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);
							--b_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);
							r_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
							g_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
							b_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);													
						end if;
				end if;
			-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ Catch Special Range $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ --
			else -- if cnt_h_sync_vga > 1 and cnt_h_sync_vga < 640 then	
				r_vga <= "000";
				g_vga <= "000";
				b_vga <= "000";
				buf_vga_Y_out_cnt <= 639;
			end if;
		end if;--if cnt_v_sync_vga > 1 and cnt_v_sync_vga < 480 then
	else -- if cnt_v_sync_vga > 1 and cnt_v_sync_vga < 481 then
		r_vga <= "000";
		g_vga <= "000";
		b_vga <= "000";
	end if;
end if;
end process Display_VGA;
--############################################### Display VGA ###############################################--



end Lane_arch;

