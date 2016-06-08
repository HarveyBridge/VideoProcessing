
library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity LocalTernaryPatterns_Imp is
port (
				scl : out std_logic;
				sda : inout std_logic;
			    data_video : in std_logic_vector(7 downto 0);
			    clk_video : in std_logic;
			 
			    h_sync_vga : out std_logic;
				v_sync_vga : out std_logic;
				r_vga : out  STD_LOGIC_vector(2 downto 0);
				g_vga : out  STD_LOGIC_vector(2 downto 0);
				b_vga : out  STD_LOGIC_vector(2 downto 0);

                -- Debug
					-- DebugOut : out  STD_LOGIC_vector(7 downto 0);
					-- DebugPulse : inout  STD_LOGIC;
					DebugMux	:in std_logic_vector(3 downto 0);
					ImageSelect	:in std_logic;
					test : buffer std_logic;

                rst_system : in  STD_LOGIC
);
end LocalTernaryPatterns_Imp;
architecture architecture_LTP_Implement of LocalTernaryPatterns_Imp is

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

--VGA-8bit-------------------------------------------------------------------------------------------------------
signal buf_vga_state : std_logic_vector(1 downto 0):="00";
signal buf_vga_state1 : std_logic_vector(1 downto 0):="00";



type Array_Y is ARRAY (integer range 0 to 639) of std_logic_vector(7 downto 0);
signal buf_vga_Y : Array_Y;
signal buf_vga_Y2 : Array_Y;
signal buf_vga_Y_buf : std_logic_vector(7 downto 0);


signal buf_vga_Y_in_cnt : integer range 0 to 639:=0;
signal buf_vga_Y_in_cnt2 : integer range 0 to 639:=0;
signal buf_vga_Y_out_cnt : integer range 0 to 639:=639;



--########## Component Defination ###################################################################################--	
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
--########## Component Defination ###################################################################################--	




--state-------------------------------------------------------------------------------------------------------
signal range_total_cnt : integer range 0 to 1289:=0;
signal range_total_cnt_en : std_logic:='0';
signal buf_Y_temp_en : std_logic:='0';
signal SB_buf_012_en : std_logic:='0';
signal buf_sobel_cc_en : std_logic:='0';
signal buf_sobel_cc_delay : integer range 0 to 3:=0;
signal SBB_buf_en : std_logic:='0';
signal buf_data_state : std_logic_vector(1 downto 0):="00";

signal LBP_Data_State : std_logic_vector(1 downto 0):="00";
--state-------------------------------------------------------------------------------------------------------

---------------------|
--SB = Sobel Buffer--|
---------------------|
type Array_Sobel_buf is array (integer range 0 to 639) of std_logic_vector ((8-1) downto 0);
signal SB_buf_0 : Array_Sobel_buf;
signal SB_buf_0_data_1 : std_logic_vector((10-1) downto 0):="0000000000";
signal SB_buf_0_data_2 : std_logic_vector((10-1) downto 0):="0000000000";
signal SB_buf_0_data_3 : std_logic_vector((10-1) downto 0):="0000000000";

signal SB_buf_1 : Array_Sobel_buf;
signal SB_buf_1_data_1 : std_logic_vector((10-1) downto 0):="0000000000";
signal SB_buf_1_data_2 : std_logic_vector((10-1) downto 0):="0000000000";
signal SB_buf_1_data_3 : std_logic_vector((10-1) downto 0):="0000000000";

signal SB_buf_2 : Array_Sobel_buf;
signal SB_buf_2_data_1 : std_logic_vector((10-1) downto 0):="0000000000";
signal SB_buf_2_data_2 : std_logic_vector((10-1) downto 0):="0000000000";
signal SB_buf_2_data_3 : std_logic_vector((10-1) downto 0):="0000000000";

signal SB_buf_in_data : std_logic_vector((8-1) downto 0):="00000000";
signal SB_buf_cnt : integer range 0 to 639:=0;
signal SB_buf_cnt_max : integer range 0 to 639:=639; --0~639

signal SB_XSCR : std_logic_vector((10-1) downto 0):="0000000000";
signal SB_YSCR : std_logic_vector((10-1) downto 0):="0000000000";
signal SB_SUM : std_logic_vector((11-1) downto 0):="00000000000";

signal SB_CRB_data : std_logic:='0';

type Sobel_buf is array (integer range 0 to 650) of std_logic_vector ((8-1) downto 0);
signal SB_buf_redata : Sobel_buf;

signal redata_cnt : integer range 0 to 650:=0;
signal redata_en : std_logic:='0';
signal SB_buf_switch : std_logic:='0';

----------|
--SB End--|
----------|

------------------------------|
--LBP Matrix = Matrix Buffer--|
------------------------------|
type Matrix_Buf is array (integer range 0 to 639) of std_logic_vector ((8-1) downto 0);
signal Matrix_Column_1 : Matrix_Buf;
signal Matrix_R1C1 : std_logic_vector((10-1) downto 0):="0000000000";
signal Matrix_R2C1 : std_logic_vector((10-1) downto 0):="0000000000";
signal Matrix_R3C1 : std_logic_vector((10-1) downto 0):="0000000000";

signal Matrix_Column_2 : Matrix_Buf;
signal Matrix_R1C2 : std_logic_vector((10-1) downto 0):="0000000000";
signal Matrix_R2C2 : std_logic_vector((10-1) downto 0):="0000000000";
signal Matrix_R3C2 : std_logic_vector((10-1) downto 0):="0000000000";

signal Matrix_Column_3 : Matrix_Buf;
signal Matrix_R1C3 : std_logic_vector((10-1) downto 0):="0000000000";
signal Matrix_R2C3 : std_logic_vector((10-1) downto 0):="0000000000";
signal Matrix_R3C3 : std_logic_vector((10-1) downto 0):="0000000000";

signal Matrix_Buf_Cnt	 : integer range 0 to 639:=0;
signal Matrix_Buf_Length_Max : integer range 0 to 639:=639;

------------------------------|
-- End of LBP Matrix = Matrix Buffer--|
------------------------------|
signal boundary_edge_H : integer range 0 to 639:=250; -- 100 to 250
signal boundary_edge_V : integer range 0 to 639:=300; -- 100 to 300
------------------|
--LTP Calculate --|
------------------|
type Analyze_Buf is array (integer range 0 to 255) of std_logic_vector ((16-1) downto 0);
signal R2C2_Encode 				: std_logic_vector(7 downto 0);
signal R2C2_Encode_Threshold	: std_logic_vector(7 downto 0):="00001111";
signal R2C2_Encode_Bit			: std_logic_vector(7 downto 0);
signal R2C2_Encode_Bit2			: std_logic_vector(7 downto 0);
signal LTP_Value				: Matrix_Buf;
signal LTP_Analyze				: Analyze_Buf;
signal LTP_Analyze_Cnt			: integer range 0 to 65535:=0;
signal LTP_Cnt					: integer range 0 to 639:=0;
signal LTP_Div_Character		: std_logic_vector(15 downto 0);
signal LTP_Character			: std_logic_vector(7 downto 0);
------------------|
--LTP Calculate --|
------------------|
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
------------------------------------|
--Sobel_Cal Matrix = Matrix Buffer--|
------------------------------------|
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

buf_vga_Y(buf_vga_Y_in_cnt)<= buf_vga_Y_buf ;

i2c_1 :i2c
		port map (
                rst_system => rst_system,
                clk_video => clk_video,
                scl => scl,
                sda => sda           
			);

--########## Component Defination ###################################################################################--			
			
--############################################### Sobel Buffer Matrix ###############################################--
process(rst_system, clk_video)
begin
if rst_system = '0' then
	buf_vga_state <= "00";
	SB_buf_0_data_1 <= "0000000000";
	SB_buf_0_data_2 <= "0000000000";
	SB_buf_0_data_3 <= "0000000000";
	SB_buf_1_data_1 <= "0000000000";
	SB_buf_1_data_2 <= "0000000000";
	SB_buf_1_data_3 <= "0000000000";
	SB_buf_2_data_1 <= "0000000000";
	SB_buf_2_data_2 <= "0000000000";
	SB_buf_2_data_3 <= "0000000000";
	SB_buf_cnt <= 0;
else
	if rising_edge(clk_video) then
		if (buf_vga_en = '1' and cnt_video_hsync < 1280) then
			if buf_data_state(0) = '0' then
				SB_buf_0_data_3 <= "00" & SB_buf_0(SB_buf_cnt);
				SB_buf_0_data_2 <= SB_buf_0_data_3;
				SB_buf_0_data_1 <= SB_buf_0_data_2;
				SB_buf_1_data_3 <= "00" & SB_buf_1(SB_buf_cnt);
				SB_buf_1_data_2 <= SB_buf_1_data_3;
				SB_buf_1_data_1 <= SB_buf_1_data_2;
				SB_buf_2_data_3 <= "00" & SB_buf_2(SB_buf_cnt);
				SB_buf_2_data_2 <= SB_buf_2_data_3;
				SB_buf_2_data_1 <= SB_buf_2_data_2;
			else	
				SB_buf_0(SB_buf_cnt) <= SB_buf_1_data_3(7 downto 0);
				SB_buf_1(SB_buf_cnt) <= SB_buf_2_data_3(7 downto 0);
				SB_buf_2(SB_buf_cnt) <= data_video;
				if SB_buf_cnt = SB_buf_cnt_max then
					SB_buf_cnt <= 0;
				else
					SB_buf_cnt <= SB_buf_cnt + 1;
				end if;	
			end if;
		else			
			buf_vga_state <= "00";
			SB_buf_0_data_1 <= "0000000000";
			SB_buf_0_data_2 <= "0000000000";
			SB_buf_0_data_3 <= "0000000000";
			SB_buf_1_data_1 <= "0000000000";
			SB_buf_1_data_2 <= "0000000000";
			SB_buf_1_data_3 <= "0000000000";
			SB_buf_2_data_1 <= "0000000000";
			SB_buf_2_data_2 <= "0000000000";
			SB_buf_2_data_3 <= "0000000000";
			SB_buf_cnt <= 0;
		end if;
	end if;
end if;
end process;
--############################################### Sobel Buffer Matrix ###############################################--


--############################################### Display VGA ###############################################-- 
process(rst_system, clk_video)
begin
if rst_system = '0' then
	r_vga <= "000";
	g_vga <= "000";
	b_vga <= "000";
	buf_vga_Y_out_cnt <= 0;
	-- show_frame_en <= '0';
	-- available_frame_value <= 0;
elsif rising_edge(clk_video) then
			-- even  odd
		-- if (((f_video_en = '0' and black_vga_en = '0') or (f_video_en = '1' and black_vga_en = '1')) and cnt_h_sync_vga > 1 and cnt_h_sync_vga < 640 and cnt_v_sync_vga > 1 and cnt_v_sync_vga < 480)   then
				
				
			-- r_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
			-- g_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
			-- b_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
			
			
			-- -- ((f_video_en = '0' and black_vga_en = '0') or (f_video_en = '1' and black_vga_en = '1'))
		if cnt_v_sync_vga > 1 and cnt_v_sync_vga < 480 then
			if cnt_h_sync_vga > 1 and cnt_h_sync_vga < 640 then		
				buf_vga_Y_out_cnt <= buf_vga_Y_out_cnt - 1;	
				if cnt_h_sync_vga > 280 and cnt_h_sync_vga < 536 then
					-- if(cnt_v_sync_vga > 1 and cnt_v_sync_vga < 5)then
						-- if cnt_h_sync_vga = 291 then
							-- r_vga <= "111";
							-- g_vga <= "000";							
							-- b_vga <= "000";
						-- elsif cnt_h_sync_vga = 301 then
							-- r_vga <= "000";
							-- g_vga <= "111";							
							-- b_vga <= "000";
						-- elsif cnt_h_sync_vga = 311 then
							-- r_vga <= "000";
							-- g_vga <= "000";							
							-- b_vga <= "111";
						-- elsif cnt_h_sync_vga = 321 then
							-- r_vga <= "111";
							-- g_vga <= "000";							
							-- b_vga <= "000";
						-- elsif cnt_h_sync_vga = 331 then
							-- r_vga <= "000";
							-- g_vga <= "111";							
							-- b_vga <= "000";
						-- elsif cnt_h_sync_vga = 341 then
							-- r_vga <= "000";
							-- g_vga <= "000";							
							-- b_vga <= "111";
						-- elsif cnt_h_sync_vga = 351 then
							-- r_vga <= "111";
							-- g_vga <= "000";							
							-- b_vga <= "000";
						-- elsif cnt_h_sync_vga = 361 then
							-- r_vga <= "000";
							-- g_vga <= "111";							
							-- b_vga <= "000";
						-- elsif cnt_h_sync_vga = 371 then
							-- r_vga <= "000";
							-- g_vga <= "000";							
							-- b_vga <= "111";
						-- elsif cnt_h_sync_vga = 381 then
							-- r_vga <= "111";
							-- g_vga <= "000";							
							-- b_vga <= "000";
						-- elsif cnt_h_sync_vga = 391 then
							-- r_vga <= "000";
							-- g_vga <= "111";							
							-- b_vga <= "000";
						-- elsif cnt_h_sync_vga = 401 then
							-- r_vga <= "000";
							-- g_vga <= "000";							
							-- b_vga <= "111";
						-- elsif cnt_h_sync_vga = 411 then
							-- r_vga <= "111";
							-- g_vga <= "000";							
							-- b_vga <= "000";
						-- elsif cnt_h_sync_vga = 421 then
							-- r_vga <= "000";
							-- g_vga <= "111";							
							-- b_vga <= "000";
						-- elsif cnt_h_sync_vga = 431 then
							-- r_vga <= "000";
							-- g_vga <= "000";							
							-- b_vga <= "111";
						-- elsif cnt_h_sync_vga = 441 then
							-- r_vga <= "111";
							-- g_vga <= "000";							
							-- b_vga <= "000";
						-- elsif cnt_h_sync_vga = 451 then
							-- r_vga <= "000";
							-- g_vga <= "111";							
							-- b_vga <= "000";
						-- elsif cnt_h_sync_vga = 461 then
							-- r_vga <= "000";
							-- g_vga <= "000";							
							-- b_vga <= "111";
						-- elsif cnt_h_sync_vga = 471 then
							-- r_vga <= "111";
							-- g_vga <= "000";							
							-- b_vga <= "000";
						-- elsif cnt_h_sync_vga = 481 then
							-- r_vga <= "000";
							-- g_vga <= "111";							
							-- b_vga <= "000";
						-- elsif cnt_h_sync_vga = 491 then
							-- r_vga <= "000";
							-- g_vga <= "000";							
							-- b_vga <= "111";
						-- elsif cnt_h_sync_vga = 501 then
							-- r_vga <= "111";
							-- g_vga <= "000";							
							-- b_vga <= "000";
						-- elsif cnt_h_sync_vga = 511 then
							-- r_vga <= "000";
							-- g_vga <= "111";							
							-- b_vga <= "000";
						-- elsif cnt_h_sync_vga = 521 then
							-- r_vga <= "000";
							-- g_vga <= "000";							
							-- b_vga <= "111";
						-- elsif cnt_h_sync_vga = 531 then
							-- r_vga <= "111";
							-- g_vga <= "000";							
							-- b_vga <= "000";
						-- end if;
					-- end if;
					-- if( ( cnt_v_sync_vga > (480 - CONV_INTEGER(LTP_Analyze(cnt_h_sync_vga-281)(8 downto 0)))) and cnt_v_sync_vga < 480 )then					
						-- r_vga <= "111";
						-- g_vga <= "000";							
						-- b_vga <= "000";
					-- else
						-- r_vga <= "111";
						-- g_vga <= "111";
						-- b_vga <= "111";						
					-- end if;	
					if( cnt_h_sync_vga = 300 and ( cnt_v_sync_vga > (480 - CONV_INTEGER(LTP_Analyze(1)(8 downto 0)))) and cnt_v_sync_vga < 480 )then					
						r_vga <= "111";
						g_vga <= "000";
						b_vga <= "000";
					elsif( cnt_h_sync_vga = 310 and ( cnt_v_sync_vga > (480 - CONV_INTEGER(LTP_Analyze(2)(8 downto 0)))) and cnt_v_sync_vga < 480 )then					
						r_vga <= "111";
						g_vga <= "000";
						b_vga <= "000";
					elsif( cnt_h_sync_vga = 320 and ( cnt_v_sync_vga > (480 - CONV_INTEGER(LTP_Analyze(4)(8 downto 0)))) and cnt_v_sync_vga < 480 )then					
						r_vga <= "111";
						g_vga <= "000";
						b_vga <= "000";
					elsif( cnt_h_sync_vga = 330 and ( cnt_v_sync_vga > (480 - CONV_INTEGER(LTP_Analyze(8)(8 downto 0)))) and cnt_v_sync_vga < 480 )then					
						r_vga <= "111";
						g_vga <= "000";
						b_vga <= "000";
					elsif( cnt_h_sync_vga = 340 and ( cnt_v_sync_vga > (480 - CONV_INTEGER(LTP_Analyze(16)(8 downto 0)))) and cnt_v_sync_vga < 480 )then					
						r_vga <= "111";
						g_vga <= "000";
						b_vga <= "000";
					elsif( cnt_h_sync_vga = 350 and ( cnt_v_sync_vga > (480 - CONV_INTEGER(LTP_Analyze(32)(8 downto 0)))) and cnt_v_sync_vga < 480 )then					
						r_vga <= "111";
						g_vga <= "000";
						b_vga <= "000";
					elsif( cnt_h_sync_vga = 360 and ( cnt_v_sync_vga > (480 - CONV_INTEGER(LTP_Analyze(64)(8 downto 0)))) and cnt_v_sync_vga < 480 )then					
						r_vga <= "111";
						g_vga <= "000";
						b_vga <= "000";
					elsif( cnt_h_sync_vga = 370 and ( cnt_v_sync_vga > (480 - CONV_INTEGER(LTP_Analyze(128)(8 downto 0)))) and cnt_v_sync_vga < 480 )then					
						r_vga <= "111";
						g_vga <= "000";
						b_vga <= "000";		
					elsif( cnt_h_sync_vga = 400 and ( cnt_v_sync_vga > (480 - CONV_INTEGER(LTP_Character)) and cnt_v_sync_vga < 480 ))then					
						r_vga <= "111";
						g_vga <= "111";
						b_vga <= "000";	
					elsif( cnt_h_sync_vga = 550 and ( cnt_v_sync_vga > 100) and cnt_v_sync_vga < 480 )then					
						r_vga <= "000";
						g_vga <= "111";
						b_vga <= "111";	
					else
						r_vga <= "111";
						g_vga <= "111";
						b_vga <= "111";
					end if;	
				else				
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
								-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ Inner Special Range $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ --
								r_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
								g_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
								b_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);

								LTP_Analyze(CONV_INTEGER(LTP_Value(buf_vga_Y_out_cnt)(7 downto 0))) <= LTP_Analyze(CONV_INTEGER(LTP_Value(buf_vga_Y_out_cnt)(7 downto 0))) + '1';	
								LTP_Div_Character <= LTP_Analyze(1) + LTP_Analyze(2) + LTP_Analyze(4) + LTP_Analyze(8) + LTP_Analyze(16) + LTP_Analyze(32) + LTP_Analyze(64) + LTP_Analyze(128) ;
								LTP_Character <= LTP_Div_Character(10 downto 3);
								-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ Inner Special Range $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ --
							end if;
						end if;
					else					
						if((cnt_v_sync_vga > 300 and cnt_v_sync_vga < 480)) then
							if(cnt_h_sync_vga > 1 and cnt_h_sync_vga < 10) and (cnt_v_sync_vga > 480-50 and cnt_v_sync_vga < 480) then								
								r_vga <= "000";
								g_vga <= "000";
								b_vga <= "111";
							elsif((cnt_h_sync_vga > 10 and cnt_h_sync_vga < 20) and (cnt_v_sync_vga > 480-100 and cnt_v_sync_vga < 480)) then 
								r_vga <= "000";
								g_vga <= "111";
								b_vga <= "111";
							elsif((cnt_h_sync_vga > 20 and cnt_h_sync_vga < 30) and(cnt_v_sync_vga > 480-150 and cnt_v_sync_vga < 480)) then 
								r_vga <= "111";
								g_vga <= "000";
								b_vga <= "111";							
							else	
								if((LTP_Character > 100 and LTP_Character < 150) and (cnt_h_sync_vga > 30 and cnt_h_sync_vga < 60) and(cnt_v_sync_vga > 480-150 and cnt_v_sync_vga < 480)) then 
									r_vga <= "000";
									g_vga <= "111";
									b_vga <= "000";
								else
									r_vga <= "111";
									g_vga <= "000";
									b_vga <= "000";
								end if;
								-- r_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);
								-- g_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);
								-- b_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);	
							end if;
							-- if((cnt_v_sync_vga > 310 and cnt_v_sync_vga < 315))then
								-- if(cnt_h_sync_vga > 0 and cnt_h_sync_vga < CONV_INTEGER(LTP_Analyze(0)(9 downto 0)))then					
									-- r_vga <= "111";
									-- g_vga <= "000";							
									-- b_vga <= "000";
								-- else
									-- r_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
									-- g_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
									-- b_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
								-- end if;
							-- elsif((cnt_v_sync_vga > 320 and cnt_v_sync_vga < 325))then				
								-- if(cnt_h_sync_vga > 0 and cnt_h_sync_vga < CONV_INTEGER(LTP_Analyze(1)(9 downto 0)))then					
									-- r_vga <= "000";
									-- g_vga <= "111";							
									-- b_vga <= "000";
								-- else
									-- r_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
									-- g_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
									-- b_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
								-- end if;
							-- elsif((cnt_v_sync_vga > 330 and cnt_v_sync_vga < 335))then
								-- if(cnt_h_sync_vga > 0 and cnt_h_sync_vga < CONV_INTEGER(LTP_Analyze(2)(9 downto 0)))then					
									-- r_vga <= "000";
									-- g_vga <= "000";							
									-- b_vga <= "111";
								-- else
									-- r_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
									-- g_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
									-- b_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
								-- end if;
							-- elsif((cnt_v_sync_vga > 340 and cnt_v_sync_vga < 345))then
								-- if(cnt_h_sync_vga > 0 and cnt_h_sync_vga < CONV_INTEGER(LTP_Analyze(3)(9 downto 0)))then					
									-- r_vga <= "111";
									-- g_vga <= "111";							
									-- b_vga <= "000";
								-- else
									-- r_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
									-- g_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
									-- b_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
								-- end if;
							-- elsif((cnt_v_sync_vga > 350 and cnt_v_sync_vga < 355))then
								-- if(cnt_h_sync_vga > 0 and cnt_h_sync_vga < CONV_INTEGER(LTP_Analyze(4)(9 downto 0)))then					
									-- r_vga <= "111";
									-- g_vga <= "000";							
									-- b_vga <= "000";
								-- else
									-- r_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
									-- g_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
									-- b_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
								-- end if;
							-- elsif((cnt_v_sync_vga > 360 and cnt_v_sync_vga < 365))then
								-- if(cnt_h_sync_vga > 0 and cnt_h_sync_vga < CONV_INTEGER(LTP_Analyze(5)(9 downto 0)))then					
									-- r_vga <= "000";
									-- g_vga <= "111";							
									-- b_vga <= "000";
								-- else
									-- r_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
									-- g_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
									-- b_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
								-- end if;
							-- elsif((cnt_v_sync_vga > 370 and cnt_v_sync_vga < 375))then
								-- if(cnt_h_sync_vga > 0 and cnt_h_sync_vga < CONV_INTEGER(LTP_Analyze(6)(9 downto 0)))then					
									-- r_vga <= "000";
									-- g_vga <= "000";							
									-- b_vga <= "111";
								-- else
									-- r_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
									-- g_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
									-- b_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
								-- end if;
							-- elsif((cnt_v_sync_vga > 380 and cnt_v_sync_vga < 385))then
								-- if(cnt_h_sync_vga > 0 and cnt_h_sync_vga < CONV_INTEGER(LTP_Analyze(7)(9 downto 0)))then					
									-- r_vga <= "111";
									-- g_vga <= "111";							
									-- b_vga <= "000";
								-- else
									-- r_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
									-- g_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
									-- b_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
								-- end if;
							-- else
								-- r_vga <= "000";
								-- g_vga <= "111";							
								-- b_vga <= "111";
							-- end if;
						else
							r_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
							g_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
							b_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
						end if;				
					end if;
				end if;
				-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ Catch Special Range $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ --
-- mark this to show full image  ===> Flash Image !!
			-- if  (f_video_en = '1' and black_vga_en = '1') then
				-- buf_vga_Y_out_cnt <= buf_vga_Y_out_cnt - 1;	
				-- r_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
				-- g_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
				-- b_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
			-- else
				-- r_vga <= "000";
				-- g_vga <= "000";
				-- b_vga <= "000";
			-- end if;
-- count address and show sobel
			-- buf_vga_Y_out_cnt <= buf_vga_Y_out_cnt - 1;	
			-- r_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);
			-- g_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);
			-- b_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);	
			else
				r_vga <= "000";
				g_vga <= "000";
				b_vga <= "000";
				buf_vga_Y_out_cnt <= 639;
			end if;
		else
			
			LTP_Analyze(cnt_h_sync_vga) <= (others=>'0');
			
			r_vga <= "000";
			g_vga <= "000";
			b_vga <= "000";
			--available_frame_cnt <= 300;
			--available_frame_en <= '0';
			--available_frame_value <= 0;
		end if;
--	
end if;
end process;
--############################################### Display VGA ###############################################--

--############################################### Buffer State ###############################################--
process(rst_system, clk_video)
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
	LBP_Data_State <= "00";
else
	if rising_edge(clk_video) then
		-- if (buf_vga_en = '1' and f_video_en = '0' and cnt_video_hsync < 1290) then
		if (buf_vga_en = '1' and cnt_video_hsync < 1290) then
			if buf_data_state = "11" then
				buf_data_state <= "00";
			else
				buf_data_state <= buf_data_state + '1';
			end if;
			if LBP_Data_State = "11" then
				LBP_Data_State <= "00";
			else
				LBP_Data_State <= LBP_Data_State + '1';
			end if;
			
			if (cnt_video_hsync >= 0 and cnt_video_hsync < 1290 and cnt_v_sync_vga >= 0 and cnt_v_sync_vga < 480) then
				if range_total_cnt_en = '0' then
					if buf_data_state = "11" then
						range_total_cnt_en <= '1';
						SBB_buf_en <= '1';
						SB_buf_012_en <= '1';
						buf_sobel_cc_en <= '1';
					end if;
					if LBP_Data_State = "11" then
						range_total_cnt_en <= '1';
						SBB_buf_en <= '1';
						SB_buf_012_en <= '1';
						buf_sobel_cc_en <= '1';
					end if;
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
			LBP_Data_State <= "00"; 
		end if;
	end if;
end if;
end process;
--############################################### Buffer State ###############################################--


-- --############################################### Sobel Calculate ###############################################--
process(rst_system, clk_video)
variable sobel_x_cc_1 : std_logic_vector(9 downto 0);
variable sobel_x_cc_2 : std_logic_vector(9 downto 0);
variable sobel_y_cc_1 : std_logic_vector(9 downto 0);
variable sobel_y_cc_2 : std_logic_vector(9 downto 0);
begin
if rst_system = '0' then
	SB_XSCR <= "0000000000";
	SB_YSCR <= "0000000000";
	SB_SUM  <= "00000000000";
	SB_CRB_data <= '0';
-- system reset
	redata_cnt <= 0 ;
	redata_en <= '0';
	Sobel_Cal_en <= '0';
else
	if rising_edge(clk_video) then
		if buf_sobel_cc_en = '1' then
			if buf_data_state(0) = '1' then
			-- if buf_data_state(0) = '0' then
				sobel_x_cc_1 := SB_buf_0_data_1 + SB_buf_0_data_2 + SB_buf_0_data_2 + SB_buf_0_data_3;
				sobel_x_cc_2 := SB_buf_2_data_1 + SB_buf_2_data_2 + SB_buf_2_data_2 + SB_buf_2_data_3;
				
				sobel_y_cc_1 := SB_buf_0_data_1 + SB_buf_1_data_1 + SB_buf_1_data_1 + SB_buf_2_data_1;
				sobel_y_cc_2 := SB_buf_0_data_3 + SB_buf_1_data_3 + SB_buf_1_data_3 + SB_buf_2_data_3;
	
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
				--if ((SB_XSCR > "0001100000" and SB_XSCR < "0011100000") or (SB_YSCR > "0001100000" and SB_YSCR < "0011100000")) then
					-- SB_CRB_data <= '1';
				Sobel_Cal_en <= '1';
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
			SB_CRB_data <= '0';
-- when cnt_video_hsync > 1280, let redata_cnt be reset
			redata_cnt <= 0;
			Sobel_Cal_en <= '0';
		end if;
	end if;
end if;
end process;
-- --############################################### Sobel Calculate ###############################################--

--############################################### Matrix Expression ###############################################--
--			 Col-1   Col-2  Col-3
--			[ R1C1 , R1C2 , R1C3 ]
--Matrix =	[ R2C1 , R2C2 , R2C3 ]
--			[ R3C1 , R3C2 , R3C3 ]
--############################################### Matrix Expression ###############################################--

--############################################### LBP Buffer Matrix ###############################################--
process(rst_system, clk_video)
begin
if rst_system = '0' then
	Matrix_R1C1 <= "0000000000";
	Matrix_R2C1 <= "0000000000";
	Matrix_R3C1 <= "0000000000";
	
	Matrix_R1C2 <= "0000000000";
	Matrix_R2C2 <= "0000000000";
	Matrix_R3C2 <= "0000000000";
	
	Matrix_R1C3 <= "0000000000";
	Matrix_R2C3 <= "0000000000";
	Matrix_R3C3 <= "0000000000";
	Matrix_Buf_Cnt <= 0;

else
	if rising_edge(clk_video) then
		if (buf_vga_en = '1' and cnt_video_hsync < 1280) then
			if LBP_Data_State(0) = '0' then				
				Matrix_R1C1 <= "00" & Matrix_Column_1(Matrix_Buf_Cnt);
				Matrix_R2C1 <= Matrix_R1C1;
				Matrix_R3C1 <= Matrix_R2C1;
				
				Matrix_R1C2 <= "00" & Matrix_Column_2(Matrix_Buf_Cnt);
				Matrix_R2C2 <= Matrix_R1C2;
				Matrix_R3C2 <= Matrix_R2C2;
				
				Matrix_R1C3 <= "00" & Matrix_Column_3(Matrix_Buf_Cnt);
				Matrix_R2C3 <= Matrix_R1C3;
				Matrix_R3C3 <= Matrix_R2C3;
				
			else	

				Matrix_Column_1(Matrix_Buf_Cnt) <= data_video(7 downto 0);
				Matrix_Column_2(Matrix_Buf_Cnt) <= Matrix_R3C1(7 downto 0);
				Matrix_Column_3(Matrix_Buf_Cnt) <= Matrix_R3C2(7 downto 0);
				
				if Matrix_Buf_Cnt = Matrix_Buf_Length_Max then
					Matrix_Buf_Cnt <= 0;
				else
					Matrix_Buf_Cnt <= Matrix_Buf_Cnt + 1 ;
				end if;				
			end if;
		else
			Matrix_R1C1 <= "0000000000";
			Matrix_R2C1 <= "0000000000";
			Matrix_R3C1 <= "0000000000";
			
			Matrix_R1C2 <= "0000000000";
			Matrix_R2C2 <= "0000000000";
			Matrix_R3C2 <= "0000000000";
			
			Matrix_R1C3 <= "0000000000";
			Matrix_R2C3 <= "0000000000";
			Matrix_R3C3 <= "0000000000";
			Matrix_Buf_Cnt <= 0;
		end if;
	end if;
end if;
end process;
--############################################### LBP Buffer Matrix ###############################################--


--############################################### Sobel_Cal Buffer Matrix ###############################################--
process(rst_system, clk_video)
begin
if rst_system = '0' then
	Sobel_Cal_R1C1 <= "0000000000";
	Sobel_Cal_R2C1 <= "0000000000";
	Sobel_Cal_R3C1 <= "0000000000";
	
	Sobel_Cal_R1C2 <= "0000000000";
	Sobel_Cal_R2C2 <= "0000000000";
	Sobel_Cal_R3C2 <= "0000000000";
	
	Sobel_Cal_R1C3 <= "0000000000";
	Sobel_Cal_R2C3 <= "0000000000";
	Sobel_Cal_R3C3 <= "0000000000";
	Sobel_Cal_Buf_Cnt <= 0;

else
	if rising_edge(clk_video) then
		if (buf_vga_en = '1' and cnt_video_hsync < 1280) then
			if Sobel_Cal_en = '0' then				
				Sobel_Cal_R1C1 <= "00" & Sobel_Cal_Column_1(Sobel_Cal_Buf_Cnt);
				Sobel_Cal_R2C1 <= Sobel_Cal_R1C1;
				Sobel_Cal_R3C1 <= Sobel_Cal_R2C1;
				
				Sobel_Cal_R1C2 <= "00" & Sobel_Cal_Column_2(Sobel_Cal_Buf_Cnt);
				Sobel_Cal_R2C2 <= Sobel_Cal_R1C2;
				Sobel_Cal_R3C2 <= Sobel_Cal_R2C2;
				
				Sobel_Cal_R1C3 <= "00" & Sobel_Cal_Column_3(Sobel_Cal_Buf_Cnt);
				Sobel_Cal_R2C3 <= Sobel_Cal_R1C3;
				Sobel_Cal_R3C3 <= Sobel_Cal_R2C3;
				
			else	

				Sobel_Cal_Column_1(Sobel_Cal_Buf_Cnt) <= SB_buf_redata(redata_cnt)(7 downto 0);
				Sobel_Cal_Column_2(Sobel_Cal_Buf_Cnt) <= Sobel_Cal_R3C1(7 downto 0);
				Sobel_Cal_Column_3(Sobel_Cal_Buf_Cnt) <= Sobel_Cal_R3C2(7 downto 0);
				
				if Sobel_Cal_Buf_Cnt = Sobel_Cal_Buf_Length_Max then
					Sobel_Cal_Buf_Cnt <= 0;
				else
					Sobel_Cal_Buf_Cnt <= Sobel_Cal_Buf_Cnt + 1 ;
				end if;				
			end if;
		else
			Sobel_Cal_R1C1 <= "0000000000";
			Sobel_Cal_R2C1 <= "0000000000";
			Sobel_Cal_R3C1 <= "0000000000";
			
			Sobel_Cal_R1C2 <= "0000000000";
			Sobel_Cal_R2C2 <= "0000000000";
			Sobel_Cal_R3C2 <= "0000000000";
			
			Sobel_Cal_R1C3 <= "0000000000";
			Sobel_Cal_R2C3 <= "0000000000";
			Sobel_Cal_R3C3 <= "0000000000";
			Sobel_Cal_Buf_Cnt <= 0;
		end if;
	end if;
end if;
end process;
--############################################### Sobel_Cal Buffer Matrix ###############################################--


--############################################### Sobel_Cal to LTP Calculate ###############################################--
process(rst_system, clk_video)

variable R2C2_Encode_Reg_U	: std_logic_vector(9 downto 0);
variable R2C2_Encode_Reg_D	: std_logic_vector(9 downto 0);
begin
if rst_system = '0' then
	R2C2_Encode <= (others =>'0');
	R2C2_Encode_Bit <= (others =>'0');
	R2C2_Encode_Bit2<= (others =>'0');
	LTP_Cnt <= 0;
else
	if rising_edge(clk_video) then
		if buf_sobel_cc_en = '1' then
			if Sobel_Cal_en = '1' then
			-- if buf_data_state(0) = '0' then
				R2C2_Encode_Reg_U := Sobel_Cal_R2C2 + R2C2_Encode_Threshold ;
				R2C2_Encode_Reg_D := Sobel_Cal_R2C2 - R2C2_Encode_Threshold ;

				if Sobel_Cal_R1C1 > R2C2_Encode_Reg_U then
					R2C2_Encode_Bit(7) <= '1';
					R2C2_Encode_Bit2(7) <= '0';
				elsif Sobel_Cal_R1C1 < R2C2_Encode_Reg_D then
					R2C2_Encode_Bit(7) <= '0';
					R2C2_Encode_Bit2(7) <= '1';
				else 
					R2C2_Encode_Bit(7) <= '0';
					R2C2_Encode_Bit2(7) <= '0';
				end if;
				if Sobel_Cal_R2C1 > R2C2_Encode_Reg_U then
					R2C2_Encode_Bit(6) <= '1';
					R2C2_Encode_Bit2(6) <= '0';
				elsif Sobel_Cal_R2C1 < R2C2_Encode_Reg_D then
					R2C2_Encode_Bit(6) <= '0';
					R2C2_Encode_Bit2(6) <= '1';
				else 
					R2C2_Encode_Bit(6) <= '0';
					R2C2_Encode_Bit2(6) <= '0';
				end if;
				if Sobel_Cal_R3C1 > R2C2_Encode_Reg_U then
					R2C2_Encode_Bit(5) <= '1';
					R2C2_Encode_Bit2(5) <= '0';
				elsif Sobel_Cal_R3C1 < R2C2_Encode_Reg_D then
					R2C2_Encode_Bit(5) <= '0';
					R2C2_Encode_Bit2(5) <= '1';
				else 
					R2C2_Encode_Bit(5) <= '0';
					R2C2_Encode_Bit2(5) <= '0';
				end if;
				if Sobel_Cal_R3C2 > R2C2_Encode_Reg_U then
					R2C2_Encode_Bit(4) <= '1';
					R2C2_Encode_Bit2(4) <= '0';
				elsif Sobel_Cal_R3C2 < R2C2_Encode_Reg_D then
					R2C2_Encode_Bit(4) <= '0';
					R2C2_Encode_Bit2(4) <= '1';
				else 
					R2C2_Encode_Bit(4) <= '0';
					R2C2_Encode_Bit2(4) <= '0';
				end if;
				if Sobel_Cal_R3C3 > R2C2_Encode_Reg_U then
					R2C2_Encode_Bit(3) <= '1';
					R2C2_Encode_Bit2(3) <= '0';
				elsif Sobel_Cal_R3C3 < R2C2_Encode_Reg_D then
					R2C2_Encode_Bit(3) <= '0';
					R2C2_Encode_Bit2(3) <= '1';
				else 
					R2C2_Encode_Bit(3) <= '0';
					R2C2_Encode_Bit2(3) <= '0';
				end if;
				if Sobel_Cal_R2C3 > R2C2_Encode_Reg_U then
					R2C2_Encode_Bit(2) <= '1';
					R2C2_Encode_Bit2(2) <= '0';
				elsif Sobel_Cal_R2C3 < R2C2_Encode_Reg_D then
					R2C2_Encode_Bit(2) <= '0';
					R2C2_Encode_Bit2(2) <= '1';
				else 
					R2C2_Encode_Bit(2) <= '0';
					R2C2_Encode_Bit2(2) <= '0';
				end if;
				if Sobel_Cal_R1C3 > R2C2_Encode_Reg_U then
					R2C2_Encode_Bit(1) <= '1';
					R2C2_Encode_Bit2(1) <= '0';
				elsif Sobel_Cal_R1C3 < R2C2_Encode_Reg_D then
					R2C2_Encode_Bit(1) <= '0';
					R2C2_Encode_Bit2(1) <= '1';
				else 
					R2C2_Encode_Bit(1) <= '0';
					R2C2_Encode_Bit2(1) <= '0';
				end if;
				if Sobel_Cal_R1C2 > R2C2_Encode_Reg_U then
					R2C2_Encode_Bit(0) <= '1';
					R2C2_Encode_Bit2(0) <= '0';
				elsif Sobel_Cal_R1C2 < R2C2_Encode_Reg_D then
					R2C2_Encode_Bit(0) <= '0';
					R2C2_Encode_Bit2(0) <= '1';
				else 
					R2C2_Encode_Bit(0) <= '0';
					R2C2_Encode_Bit2(0) <= '0';
				end if;

			else
				if ImageSelect = '0' then
					R2C2_Encode <= R2C2_Encode_Bit;
				else
					R2C2_Encode <= R2C2_Encode_Bit2;
				end if;
				
				LTP_Value(LTP_Cnt) <= R2C2_Encode;
				if LTP_Cnt < 639 then
					LTP_Cnt <= LTP_Cnt + 1;
				else
					LTP_Cnt <= 0;
				end if;

			end if;
		else
			R2C2_Encode <= (others =>'0');
			R2C2_Encode_Bit <= (others =>'0');
-- when cnt_video_hsync > 1280, let redata_cnt be reset
			LTP_Cnt <= 0;
		end if;
	end if;
end if;
end process;
--############################################### Sobel_Cal to LTP Calculate ###############################################--



--############################################### Sobel Calculate ###############################################--
-- process(rst_system, clk_video)
-- variable sobel_x_cc_1 : std_logic_vector(9 downto 0);
-- variable sobel_x_cc_2 : std_logic_vector(9 downto 0);
-- variable sobel_y_cc_1 : std_logic_vector(9 downto 0);
-- variable sobel_y_cc_2 : std_logic_vector(9 downto 0);
-- begin
-- if rst_system = '0' then
	-- SB_XSCR <= "0000000000";
	-- SB_YSCR <= "0000000000";
	-- SB_SUM  <= "00000000000";
	-- redata_cnt <= 0 ;
-- else
	-- if rising_edge(clk_video) then
		-- if buf_sobel_cc_en = '1' then
			-- if LBP_Data_State(0) = '1' then
				-- sobel_x_cc_1 := Matrix_R1C3 + Matrix_R2C3 + Matrix_R2C3 + Matrix_R3C3;
				-- sobel_x_cc_2 := Matrix_R1C1 + Matrix_R2C1 + Matrix_R2C1 + Matrix_R3C1;
				
				-- sobel_y_cc_1 := Matrix_R1C3 + Matrix_R1C2 + Matrix_R1C2 + Matrix_R1C1;
				-- sobel_y_cc_2 := Matrix_R3C3 + Matrix_R3C2 + Matrix_R3C2 + Matrix_R3C1;
	
				-- if sobel_x_cc_1 >= sobel_x_cc_2 then
					-- SB_XSCR <= sobel_x_cc_1 - sobel_x_cc_2;
				-- else
					-- SB_XSCR <= sobel_x_cc_2 - sobel_x_cc_1;
				-- end if;
				
				-- if sobel_y_cc_1 >= sobel_y_cc_2 then
					-- SB_YSCR <= sobel_y_cc_1 - sobel_y_cc_2;
				-- else
					-- SB_YSCR <= sobel_y_cc_2 - sobel_y_cc_1;
				-- end if;
			-- else
-- -- sum  X_sobel  &  Y_sobel
				-- SB_SUM <= "00000000000"+SB_XSCR+SB_YSCR;
-- -- put SUM_sobel to SB_buf_redata(0~640)
				-- SB_buf_redata(redata_cnt) <= SB_SUM(9 downto 2); 
-- -- counter redata_cnt to get SB_buf_redata address
				-- if redata_cnt < 639 then
					-- redata_cnt <= redata_cnt + 1;
				-- else
					-- redata_cnt <= 0;
				-- end if;
			-- end if;
		-- else
			-- SB_XSCR <= "0000000000";
			-- SB_YSCR <= "0000000000";
			-- SB_CRB_data <= '0';
-- -- when cnt_video_hsync > 1280, let redata_cnt be reset
			-- redata_cnt <= 0;
		-- end if;
	-- end if;
-- end if;
-- end process;
--############################################### Sobel Calculate ###############################################--


-- --############################################### LBP Calculate ###############################################--
-- process(rst_system, clk_video)

-- variable R2C2_Encode_Reg_7	: std_logic_vector(9 downto 0);
-- variable R2C2_Encode_Reg_6	: std_logic_vector(9 downto 0);
-- variable R2C2_Encode_Reg_5	: std_logic_vector(9 downto 0);
-- variable R2C2_Encode_Reg_4	: std_logic_vector(9 downto 0);
-- variable R2C2_Encode_Reg_3	: std_logic_vector(9 downto 0);
-- variable R2C2_Encode_Reg_2	: std_logic_vector(9 downto 0);
-- variable R2C2_Encode_Reg_1	: std_logic_vector(9 downto 0);
-- variable R2C2_Encode_Reg_0	: std_logic_vector(9 downto 0);


-- begin
-- if rst_system = '0' then
	-- R2C2_Encode <= (others =>'0');
	-- R2C2_Encode_Bit <= (others =>'0');
	-- R2C2_Encode_Bit2<= (others =>'0');
	-- LTP_Cnt <= 0;
-- else
	-- if rising_edge(clk_video) then
		-- if buf_sobel_cc_en = '1' then
			-- if LBP_Data_State(0) = '1' then
			-- -- if buf_data_state(0) = '0' then
				-- if Matrix_R1C1 > Matrix_R2C2 then
					-- R2C2_Encode_Reg_7 := Matrix_R1C1 - Matrix_R2C2;
				-- else
					-- R2C2_Encode_Reg_7 := Matrix_R2C2 - Matrix_R1C1;
				-- end if;
				-- if Matrix_R2C1 > Matrix_R2C2 then
					-- R2C2_Encode_Reg_6 := Matrix_R2C1 - Matrix_R2C2;
				-- else
					-- R2C2_Encode_Reg_6 := Matrix_R2C2 - Matrix_R2C1;
				-- end if;
				-- if Matrix_R3C1 > Matrix_R2C2 then
					-- R2C2_Encode_Reg_5 := Matrix_R3C1 - Matrix_R2C2;
				-- else
					-- R2C2_Encode_Reg_5 := Matrix_R2C2 - Matrix_R3C1;
				-- end if;
				-- if Matrix_R3C2 > Matrix_R2C2 then
					-- R2C2_Encode_Reg_4 := Matrix_R3C2 - Matrix_R2C2;	
				-- else
					-- R2C2_Encode_Reg_4 := Matrix_R2C2 - Matrix_R3C2;	
				-- end if;
				
				-- if Matrix_R3C3 > Matrix_R2C2 then
					-- R2C2_Encode_Reg_3 := Matrix_R3C3 - Matrix_R2C2;
				-- else
					-- R2C2_Encode_Reg_3 := Matrix_R2C2 - Matrix_R3C3;
				-- end if;
				-- if Matrix_R2C3 > Matrix_R2C2 then
					-- R2C2_Encode_Reg_2 := Matrix_R2C3 - Matrix_R2C2;
				-- else
					-- R2C2_Encode_Reg_2 := Matrix_R2C2 - Matrix_R2C3;
				-- end if;
				-- if Matrix_R1C3 > Matrix_R2C2 then
					-- R2C2_Encode_Reg_1 := Matrix_R1C3 - Matrix_R2C2;
				-- else
					-- R2C2_Encode_Reg_1 := Matrix_R2C2 - Matrix_R1C3;
				-- end if;
				-- if Matrix_R1C2 > Matrix_R2C2 then
					-- R2C2_Encode_Reg_0 := Matrix_R1C2 - Matrix_R2C2;
				-- else
					-- R2C2_Encode_Reg_0 := Matrix_R2C2 - Matrix_R1C2;
				-- end if;
				
				-- if R2C2_Encode_Reg_7 > R2C2_Encode_Threshold then
					-- R2C2_Encode_Bit(7) <= '1';
					-- R2C2_Encode_Bit2(7) <= '0';
				-- elsif R2C2_Encode_Reg_7 < R2C2_Encode_Threshold then
					-- R2C2_Encode_Bit(7) <= '0';
					-- R2C2_Encode_Bit2(7) <= '1';
				-- else
					-- R2C2_Encode_Bit(7) <= '0';
					-- R2C2_Encode_Bit2(7) <= '0';
				-- end if;
				
				-- if R2C2_Encode_Reg_6 > R2C2_Encode_Threshold then
					-- R2C2_Encode_Bit(6) <= '1';
					-- R2C2_Encode_Bit2(6) <= '0';
				-- elsif R2C2_Encode_Reg_6 < R2C2_Encode_Threshold then
					-- R2C2_Encode_Bit(6) <= '0';
					-- R2C2_Encode_Bit2(6) <= '1';
				-- else
					-- R2C2_Encode_Bit(6) <= '0';
					-- R2C2_Encode_Bit2(6) <= '0';
				-- end if;
				
				-- if R2C2_Encode_Reg_5 > R2C2_Encode_Threshold then
					-- R2C2_Encode_Bit(5) <= '1';
					-- R2C2_Encode_Bit2(5) <= '0';
				-- elsif R2C2_Encode_Reg_5 < R2C2_Encode_Threshold then
					-- R2C2_Encode_Bit(5) <= '0';
					-- R2C2_Encode_Bit2(5) <= '1';
				-- else
					-- R2C2_Encode_Bit(5) <= '0';
					-- R2C2_Encode_Bit2(5) <= '0';
				-- end if;		
				-- if R2C2_Encode_Reg_4 > R2C2_Encode_Threshold then
					-- R2C2_Encode_Bit(4) <= '1';
					-- R2C2_Encode_Bit2(4) <= '0';
				-- elsif R2C2_Encode_Reg_4 < R2C2_Encode_Threshold then
					-- R2C2_Encode_Bit(4) <= '0';
					-- R2C2_Encode_Bit2(4) <= '1';
				-- else
					-- R2C2_Encode_Bit(4) <= '0';
					-- R2C2_Encode_Bit2(4) <= '0';
				-- end if;
				-- if R2C2_Encode_Reg_3 > R2C2_Encode_Threshold then
					-- R2C2_Encode_Bit(3) <= '1';
					-- R2C2_Encode_Bit2(3) <= '0';
				-- elsif R2C2_Encode_Reg_3 < R2C2_Encode_Threshold then
					-- R2C2_Encode_Bit(3) <= '0';
					-- R2C2_Encode_Bit2(3) <= '1';
				-- else
					-- R2C2_Encode_Bit(3) <= '0';
					-- R2C2_Encode_Bit2(3) <= '0';
				-- end if;
				-- if R2C2_Encode_Reg_2 > R2C2_Encode_Threshold then
					-- R2C2_Encode_Bit(2) <= '1';
					-- R2C2_Encode_Bit2(2) <= '0';
				-- elsif R2C2_Encode_Reg_2 < R2C2_Encode_Threshold then
					-- R2C2_Encode_Bit(2) <= '0';
					-- R2C2_Encode_Bit2(2) <= '1';
				-- else
					-- R2C2_Encode_Bit(2) <= '0';
					-- R2C2_Encode_Bit2(2) <= '0';
				-- end if;
				-- if R2C2_Encode_Reg_1 > R2C2_Encode_Threshold then
					-- R2C2_Encode_Bit(1) <= '1';
					-- R2C2_Encode_Bit2(1) <= '0';
				-- elsif R2C2_Encode_Reg_1 < R2C2_Encode_Threshold then
					-- R2C2_Encode_Bit(1) <= '0';
					-- R2C2_Encode_Bit2(1) <= '1';
				-- else
					-- R2C2_Encode_Bit(1) <= '0';
					-- R2C2_Encode_Bit2(1) <= '0';
				-- end if;
				-- if R2C2_Encode_Reg_0 > R2C2_Encode_Threshold then
					-- R2C2_Encode_Bit(0) <= '1';
					-- R2C2_Encode_Bit2(0) <= '0';
				-- elsif R2C2_Encode_Reg_0 < R2C2_Encode_Threshold then
					-- R2C2_Encode_Bit(0) <= '0';
					-- R2C2_Encode_Bit2(0) <= '1';
				-- else
					-- R2C2_Encode_Bit(0) <= '0';
					-- R2C2_Encode_Bit2(0) <= '0';
				-- end if;
				
			-- else
				-- if ImageSelect = '0' then
					-- R2C2_Encode <= R2C2_Encode_Bit;
				-- else
					-- R2C2_Encode <= R2C2_Encode_Bit2;
				-- end if;
				
				-- LTP_Value(LTP_Cnt) <= R2C2_Encode;
				-- if LTP_Cnt < 639 then
					-- LTP_Cnt <= LTP_Cnt + 1;
				-- else
					-- LTP_Cnt <= 0;
				-- end if;
				
-- -- sum  X_sobel  &  Y_sobel
				-- -- SB_SUM <= "00000000000"+SB_XSCR+SB_YSCR;
-- -- -- put SUM_sobel to SB_buf_redata(0~640)
				-- -- SB_buf_redata(redata_cnt) <= SB_SUM(9 downto 2); 
-- -- -- counter redata_cnt to get SB_buf_redata address
				-- -- if redata_cnt < 639 then
					-- -- redata_cnt <= redata_cnt + 1;
				-- -- else
					-- -- redata_cnt <= 0;
				-- -- end if;
			-- end if;
		-- else
			-- R2C2_Encode <= (others =>'0');
			-- R2C2_Encode_Bit <= (others =>'0');
-- -- when cnt_video_hsync > 1280, let redata_cnt be reset
			-- LTP_Cnt <= 0;
		-- end if;
	-- end if;
-- end if;
-- end process;
-- --############################################### LBP Calculate ###############################################--

--############################################### DebugMux Matrix ###############################################--
process(DebugMux)
begin
	case DebugMux is
		when "0000"	=> R2C2_Encode_Threshold <= x"01";
		when "0001"	=> R2C2_Encode_Threshold <= x"02";
		when "0010"	=> R2C2_Encode_Threshold <= x"04";
		when "0011"	=> R2C2_Encode_Threshold <= x"08";
		when "0100"	=> R2C2_Encode_Threshold <= x"10";
		when "0101"	=> R2C2_Encode_Threshold <= x"20";
		when "0110"	=> R2C2_Encode_Threshold <= x"40";
		when "0111"	=> R2C2_Encode_Threshold <= x"80";
		when "1000"	=> R2C2_Encode_Threshold <= x"C0";
		when "1001"	=> R2C2_Encode_Threshold <= x"E0";
		when "1010"	=> R2C2_Encode_Threshold <= x"F0";
		when "1011"	=> R2C2_Encode_Threshold <= x"F8";
		when "1100"	=> R2C2_Encode_Threshold <= x"FC";
		when "1101"	=> R2C2_Encode_Threshold <= x"FE";
		when "1110"	=> R2C2_Encode_Threshold <= x"FF";		
		when "1111"	=> R2C2_Encode_Threshold <= x"F5";	
		when others	=> R2C2_Encode_Threshold <= x"01";
	end case;
end process;
--############################################### DebugMux Matrix ###############################################--
end architecture_LTP_Implement;
