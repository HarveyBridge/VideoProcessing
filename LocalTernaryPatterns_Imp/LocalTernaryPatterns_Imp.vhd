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
--########## Component Defination ###################################################################################--	

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
type Analyze_Buf is array (integer range 0 to 255) of std_logic_vector ((16-1) downto 0);
type Analyze_Temp_Buf is array (integer range 0 to 8-1) of std_logic_vector ((16-1) downto 0);
type Analyze_Queue_buf is array (integer range 0 to 255) of std_logic_vector ((32-1) downto 0);
type Analyze_Queue is array (integer range 0 to 7) of Analyze_Queue_buf;
--############################################### Matrix Expression ###############################################--
--			 Col-1   Col-2  Col-3
--			[ R1C1 , R1C2 , R1C3 ]
--Matrix =	[ R2C1 , R2C2 , R2C3 ]
--			[ R3C1 , R3C2 , R3C3 ]
--############################################### Matrix Expression ###############################################--
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

-----------------------------------|
--LTP Edge Matrix = Matrix Buffer--|
-----------------------------------|
--## Buffer Using ##--
signal LTP_Edge_Column_1 : Matrix_Buf;
signal LTP_Edge_R1C1 : std_logic_vector((10-1) downto 0):="0000000000";
signal LTP_Edge_R2C1 : std_logic_vector((10-1) downto 0):="0000000000";
signal LTP_Edge_R3C1 : std_logic_vector((10-1) downto 0):="0000000000";

signal LTP_Edge_Column_2 : Matrix_Buf;
signal LTP_Edge_R1C2 : std_logic_vector((10-1) downto 0):="0000000000";
signal LTP_Edge_R2C2 : std_logic_vector((10-1) downto 0):="0000000000";
signal LTP_Edge_R3C2 : std_logic_vector((10-1) downto 0):="0000000000";

signal LTP_Edge_Column_3 : Matrix_Buf;
signal LTP_Edge_R1C3 : std_logic_vector((10-1) downto 0):="0000000000";
signal LTP_Edge_R2C3 : std_logic_vector((10-1) downto 0):="0000000000";
signal LTP_Edge_R3C3 : std_logic_vector((10-1) downto 0):="0000000000";

signal LTP_Edge_Buf_Cnt	 : integer range 0 to 639:=0;
signal LTP_Edge_Buf_Length_Max : integer range 0 to 639:=639;

--## Calculate Using ##--
signal LTP_Edge_Cnt				: integer range 0 to 639:=0;
signal LTP_Edge_R2C2_Encode 	: std_logic_vector(7 downto 0);
signal LTP_Edge_R2C2_Encode_Bit	: std_logic_vector(7 downto 0);
signal LTP_Edge_R2C2_Encode_Bit2: std_logic_vector(7 downto 0);
signal LTP_Edge_Value			: Matrix_Buf;
signal LTP_Edge_Analyze			: Analyze_Buf;

------------------------------------|
--LTP Edge2 Matrix = Matrix Buffer--|
------------------------------------|
--## Buffer Using ##--
signal LTP_Edge2_Column_1 : Matrix_Buf;
signal LTP_Edge2_R1C1 : std_logic_vector((10-1) downto 0):="0000000000";
signal LTP_Edge2_R2C1 : std_logic_vector((10-1) downto 0):="0000000000";
signal LTP_Edge2_R3C1 : std_logic_vector((10-1) downto 0):="0000000000";

signal LTP_Edge2_Column_2 : Matrix_Buf;
signal LTP_Edge2_R1C2 : std_logic_vector((10-1) downto 0):="0000000000";
signal LTP_Edge2_R2C2 : std_logic_vector((10-1) downto 0):="0000000000";
signal LTP_Edge2_R3C2 : std_logic_vector((10-1) downto 0):="0000000000";

signal LTP_Edge2_Column_3 : Matrix_Buf;
signal LTP_Edge2_R1C3 : std_logic_vector((10-1) downto 0):="0000000000";
signal LTP_Edge2_R2C3 : std_logic_vector((10-1) downto 0):="0000000000";
signal LTP_Edge2_R3C3 : std_logic_vector((10-1) downto 0):="0000000000";

signal LTP_Edge2_Buf_Cnt	 : integer range 0 to 639:=0;
signal LTP_Edge2_Buf_Length_Max : integer range 0 to 639:=639;

--## Calculate Using ##--
signal LTP_Edge2_Cnt				: integer range 0 to 639:=0;
signal LTP_Edge2_R2C2_Encode 		: std_logic_vector(7 downto 0);
signal LTP_Edge2_R2C2_Encode_Bit	: std_logic_vector(7 downto 0);
signal LTP_Edge2_R2C2_Encode_Bit2	: std_logic_vector(7 downto 0);
signal LTP_Edge2_Value				: Matrix_Buf;
signal LTP_Edge2_Analyze			: Analyze_Buf;

------------------------------------|
--LTP Edge3 Matrix = Matrix Buffer--|
------------------------------------|
--## Buffer Using ##--
signal LTP_Edge3_Column_1 : Matrix_Buf;
signal LTP_Edge3_R1C1 : std_logic_vector((10-1) downto 0):="0000000000";
signal LTP_Edge3_R2C1 : std_logic_vector((10-1) downto 0):="0000000000";
signal LTP_Edge3_R3C1 : std_logic_vector((10-1) downto 0):="0000000000";

signal LTP_Edge3_Column_2 : Matrix_Buf;
signal LTP_Edge3_R1C2 : std_logic_vector((10-1) downto 0):="0000000000";
signal LTP_Edge3_R2C2 : std_logic_vector((10-1) downto 0):="0000000000";
signal LTP_Edge3_R3C2 : std_logic_vector((10-1) downto 0):="0000000000";

signal LTP_Edge3_Column_3 : Matrix_Buf;
signal LTP_Edge3_R1C3 : std_logic_vector((10-1) downto 0):="0000000000";
signal LTP_Edge3_R2C3 : std_logic_vector((10-1) downto 0):="0000000000";
signal LTP_Edge3_R3C3 : std_logic_vector((10-1) downto 0):="0000000000";

signal LTP_Edge3_Buf_Cnt	 : integer range 0 to 639:=0;
signal LTP_Edge3_Buf_Length_Max : integer range 0 to 639:=639;

--## Calculate Using ##--
signal LTP_Edge3_Cnt				: integer range 0 to 639:=0;
signal LTP_Edge3_R2C2_Encode 		: std_logic_vector(7 downto 0);
signal LTP_Edge3_R2C2_Encode_Bit	: std_logic_vector(7 downto 0);
signal LTP_Edge3_R2C2_Encode_Bit2	: std_logic_vector(7 downto 0);
signal LTP_Edge3_Value				: Matrix_Buf;
signal LTP_Edge3_Analyze			: Analyze_Buf;




------------------------------|
-- End of LBP Matrix = Matrix Buffer--|
------------------------------|
signal boundary_edge_H : integer range 0 to 639:=250; -- 100 to 250
signal boundary_edge_V : integer range 0 to 639:=300; -- 100 to 300
------------------|
--LTP Calculate --|
------------------|


signal R2C2_Encode 				: std_logic_vector(7 downto 0);
signal R2C2_Encode_Threshold	: std_logic_vector(7 downto 0):="00001111";
signal R2C2_Encode_Bit			: std_logic_vector(7 downto 0);
signal R2C2_Encode_Bit2			: std_logic_vector(7 downto 0);
signal LTP_Value				: Matrix_Buf;
signal LTP_Analyze				: Analyze_Buf;

signal LTP_Queue				: Analyze_Queue;
signal LTP_Queue_Cnt			: integer range 0 to 7:=0;
signal LTP_Display				: Analyze_Buf;

signal LTP_Cnt					: integer range 0 to 639:=0;
signal LTP_Analyze_Temp			: Analyze_Temp_Buf;
signal LTP_Analyze_TempCnt		: integer range 0 to 65535:=0;

signal LTP_Div_Character		: std_logic_vector(15 downto 0);
signal LTP_Character			: std_logic_vector(7 downto 0);
------------------|
--LTP Calculate --|
------------------|

------------------|
--Hand Threshold--|
------------------|
type Hand_Threshold is array (integer range 0 to 8-1) of std_logic_vector ((16-1) downto 0);
-- signal Sample_Hand	: Hand_Threshold;
signal Sample_Hand_1	: integer range 0 to 512;
signal Sample_Hand_2	: integer range 0 to 512;
signal Sample_Hand_4	: integer range 0 to 512;
signal Sample_Hand_8	: integer range 0 to 512;
signal Sample_Hand_16	: integer range 0 to 512;
signal Sample_Hand_32	: integer range 0 to 512;
signal Sample_Hand_64	: integer range 0 to 512;
signal Sample_Hand_128	: integer range 0 to 512;
signal Sample_Hand_1_Flag : std_logic:='0';
signal Sample_Hand_2_Flag : std_logic:='0';
signal Sample_Hand_4_Flag : std_logic:='0';
signal Sample_Hand_8_Flag : std_logic:='0';
signal Sample_Hand_16_Flag : std_logic:='0';
signal Sample_Hand_32_Flag : std_logic:='0';
signal Sample_Hand_64_Flag : std_logic:='0';
signal Sample_Hand_128_Flag : std_logic:='0';

signal Display_EN		: std_logic:='0';
------------------|
--Hand Threshold--|
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
signal FrameNumber	: integer range 0 to 65535:=0;
signal DebugEn		: std_logic:='0';
signal FrameCnt		: integer range 0 to 32767:=0;

signal CaptureIR_cnt : integer range 0 to 639:=639;

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

LTP_Edge2_BTM3x3 : BufferToMatrix3x3
	port map (
		clk_video 		=> clk_video,
		rst_system 		=> rst_system,		
		buf_vga_en 		=> buf_vga_en,
		buf_data_state 	=> buf_data_state,
		cnt_video_hsync => cnt_video_hsync,

		data_video 		=> LTP_Edge_Value(LTP_Edge_Cnt)(7 downto 0),
		Matrix_R1C1 	=> LTP_Edge2_R1C1,
		Matrix_R2C1 	=> LTP_Edge2_R2C1,
		Matrix_R3C1 	=> LTP_Edge2_R3C1,
		Matrix_R1C2 	=> LTP_Edge2_R1C2,
		Matrix_R2C2 	=> LTP_Edge2_R2C2,
		Matrix_R3C2 	=> LTP_Edge2_R3C2,
		Matrix_R1C3 	=> LTP_Edge2_R1C3,
		Matrix_R2C3 	=> LTP_Edge2_R2C3,
		Matrix_R3C3 	=> LTP_Edge2_R3C3,
		Matrix_Buf_Cnt 	=> LTP_Edge2_Buf_Cnt
		);

LTP_Edge3_BTM3x3 : BufferToMatrix3x3
	port map (
		clk_video 		=> clk_video,
		rst_system 		=> rst_system,		
		buf_vga_en 		=> buf_vga_en,
		buf_data_state 	=> buf_data_state,
		cnt_video_hsync => cnt_video_hsync,

		data_video 		=> LTP_Edge2_Value(LTP_Edge2_Cnt)(7 downto 0),
		Matrix_R1C1 	=> LTP_Edge3_R1C1,
		Matrix_R2C1 	=> LTP_Edge3_R2C1,
		Matrix_R3C1 	=> LTP_Edge3_R3C1,
		Matrix_R1C2 	=> LTP_Edge3_R1C2,
		Matrix_R2C2 	=> LTP_Edge3_R2C2,
		Matrix_R3C2 	=> LTP_Edge3_R3C2,
		Matrix_R1C3 	=> LTP_Edge3_R1C3,
		Matrix_R2C3 	=> LTP_Edge3_R2C3,
		Matrix_R3C3 	=> LTP_Edge3_R3C3,
		Matrix_Buf_Cnt 	=> LTP_Edge3_Buf_Cnt
		);

--########## Component Defination ###################################################################################--			
buf_vga_Y(buf_vga_Y_in_cnt)<= buf_vga_Y_buf ;

--############################################### Sobel Buffer Matrix ###############################################--
SobelBufferMatrix:process(rst_system, clk_video)
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
end process SobelBufferMatrix;
--############################################### Sobel Buffer Matrix ###############################################--

--############################################### Capture Inner Range ##############################################-- 
CaptureInnerRange:process(rst_system, clk_video)
begin
	if rst_system = '0' then
		CaptureIR_cnt <= 0;
		FrameNumber <= 0;
		FrameCnt <= 0;
		Display_EN <= '0';
	elsif rising_edge(clk_video) then
		if cnt_v_sync_vga > 1 and cnt_v_sync_vga < 481 then
			if cnt_v_sync_vga > 1 and cnt_v_sync_vga < 480 then	
				if cnt_h_sync_vga > 1 and cnt_h_sync_vga < 640 then	
					CaptureIR_cnt <= CaptureIR_cnt - 1;	
					if cnt_h_sync_vga > 280 and cnt_h_sync_vga < 536 then
					else
					-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ Catch Special Range $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ --
						if((cnt_h_sync_vga > 100 and cnt_h_sync_vga < boundary_edge_H)and(cnt_v_sync_vga > 100 and cnt_v_sync_vga < boundary_edge_V) )then
							if((cnt_v_sync_vga > 100 and cnt_v_sync_vga < 102)or(cnt_v_sync_vga > (boundary_edge_V-2) and cnt_v_sync_vga < boundary_edge_V))then
							else					
								if((cnt_h_sync_vga > 100 and cnt_h_sync_vga < 102)or(cnt_h_sync_vga > (boundary_edge_H-2) and cnt_h_sync_vga < boundary_edge_H))then													
								else
									-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ Inner Special Range 150x200 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ --								
									if DebugEn = '0' then
										LTP_Analyze(CONV_INTEGER(LTP_Value(CaptureIR_cnt)(7 downto 0))) <= LTP_Analyze(CONV_INTEGER(LTP_Value(CaptureIR_cnt)(7 downto 0))) + '1';	
										LTP_Div_Character <= LTP_Analyze(1) + LTP_Analyze(2) + LTP_Analyze(4) + LTP_Analyze(8) + LTP_Analyze(16) + LTP_Analyze(32) + LTP_Analyze(64) + LTP_Analyze(128) ;
										LTP_Character <= LTP_Div_Character(10 downto 3);
									end if;
									if FrameCnt = 30000 then
										FrameCnt <= 0;	

										LTP_Queue_Cnt <= LTP_Queue_Cnt + 1;
										LTP_Queue(LTP_Queue_Cnt)(1)(15 downto 0) <= LTP_Analyze(1)(15 downto 0);
										LTP_Queue(LTP_Queue_Cnt)(2)(15 downto 0) <= LTP_Analyze(2)(15 downto 0);
										LTP_Queue(LTP_Queue_Cnt)(4)(15 downto 0) <= LTP_Analyze(4)(15 downto 0);
										LTP_Queue(LTP_Queue_Cnt)(8)(15 downto 0) <= LTP_Analyze(8)(15 downto 0);
										LTP_Queue(LTP_Queue_Cnt)(16)(15 downto 0) <= LTP_Analyze(16)(15 downto 0);
										LTP_Queue(LTP_Queue_Cnt)(32)(15 downto 0) <= LTP_Analyze(32)(15 downto 0);
										LTP_Queue(LTP_Queue_Cnt)(64)(15 downto 0) <= LTP_Analyze(64)(15 downto 0);
										LTP_Queue(LTP_Queue_Cnt)(128)(15 downto 0) <= LTP_Analyze(128)(15 downto 0);
										LTP_Display(1)(15 downto 0) <= LTP_Queue(0)(1)(19 downto 4) + LTP_Queue(1)(1)(19 downto 4) + LTP_Queue(2)(1)(19 downto 4) + LTP_Queue(3)(1)(19 downto 4) + LTP_Queue(4)(1)(19 downto 4) + LTP_Queue(5)(1)(19 downto 4) + LTP_Queue(6)(1)(19 downto 4) + LTP_Queue(7)(1)(19 downto 4);
										LTP_Display(2)(15 downto 0) <= LTP_Queue(0)(2)(19 downto 4) + LTP_Queue(1)(2)(19 downto 4) + LTP_Queue(2)(2)(19 downto 4) + LTP_Queue(3)(2)(19 downto 4) + LTP_Queue(4)(2)(19 downto 4) + LTP_Queue(5)(2)(19 downto 4) + LTP_Queue(6)(2)(19 downto 4) + LTP_Queue(7)(2)(19 downto 4);
										LTP_Display(4)(15 downto 0) <= LTP_Queue(0)(4)(19 downto 4) + LTP_Queue(1)(4)(19 downto 4) + LTP_Queue(2)(4)(19 downto 4) + LTP_Queue(3)(4)(19 downto 4) + LTP_Queue(4)(4)(19 downto 4) + LTP_Queue(5)(4)(19 downto 4) + LTP_Queue(6)(4)(19 downto 4) + LTP_Queue(7)(4)(19 downto 4);
										LTP_Display(8)(15 downto 0) <= LTP_Queue(0)(8)(19 downto 4) + LTP_Queue(1)(8)(19 downto 4) + LTP_Queue(2)(8)(19 downto 4) + LTP_Queue(3)(8)(19 downto 4) + LTP_Queue(4)(8)(19 downto 4) + LTP_Queue(5)(8)(19 downto 4) + LTP_Queue(6)(8)(19 downto 4) + LTP_Queue(7)(8)(19 downto 4);
										LTP_Display(16)(15 downto 0) <= LTP_Queue(0)(16)(19 downto 4) + LTP_Queue(1)(16)(19 downto 4) + LTP_Queue(2)(16)(19 downto 4) + LTP_Queue(3)(16)(19 downto 4) + LTP_Queue(4)(16)(19 downto 4) + LTP_Queue(5)(16)(19 downto 4) + LTP_Queue(6)(16)(19 downto 4) + LTP_Queue(7)(16)(19 downto 4);
										LTP_Display(32)(15 downto 0) <= LTP_Queue(0)(32)(19 downto 4) + LTP_Queue(1)(32)(19 downto 4) + LTP_Queue(2)(32)(19 downto 4) + LTP_Queue(3)(32)(19 downto 4) + LTP_Queue(4)(32)(19 downto 4) + LTP_Queue(5)(32)(19 downto 4) + LTP_Queue(6)(32)(19 downto 4) + LTP_Queue(7)(32)(19 downto 4);
										LTP_Display(64)(15 downto 0) <= LTP_Queue(0)(64)(19 downto 4) + LTP_Queue(1)(64)(19 downto 4) + LTP_Queue(2)(64)(19 downto 4) + LTP_Queue(3)(64)(19 downto 4) + LTP_Queue(4)(64)(19 downto 4) + LTP_Queue(5)(64)(19 downto 4) + LTP_Queue(6)(64)(19 downto 4) + LTP_Queue(7)(64)(19 downto 4);
										LTP_Display(128)(15 downto 0) <= LTP_Queue(0)(128)(19 downto 4) + LTP_Queue(1)(128)(19 downto 4) + LTP_Queue(2)(128)(19 downto 4) + LTP_Queue(3)(128)(19 downto 4) + LTP_Queue(4)(128)(19 downto 4) + LTP_Queue(5)(128)(19 downto 4) + LTP_Queue(6)(128)(19 downto 4) + LTP_Queue(7)(128)(19 downto 4);
										
										
										-- LTP_Display(1)(7 downto 0) <= LTP_Display(1)(15 downto 8);
										-- LTP_Display(2)(7 downto 0) <= LTP_Display(2)(15 downto 8);
										-- LTP_Display(4)(7 downto 0) <= LTP_Display(4)(15 downto 8);
										-- LTP_Display(8)(7 downto 0) <= LTP_Display(8)(15 downto 8);
										-- LTP_Display(16)(7 downto 0) <= LTP_Display(16)(15 downto 8);
										-- LTP_Display(32)(7 downto 0) <= LTP_Display(32)(15 downto 8);
										-- LTP_Display(64)(7 downto 0) <= LTP_Display(64)(15 downto 8);
										-- LTP_Display(128)(7 downto 0) <= LTP_Display(128)(15 downto 8);
										
										case FrameNumber is
											when 5 =>
												DebugEn <= '0';												
												LTP_Analyze(1) <= (others=>'0');
												LTP_Analyze(2) <= (others=>'0');
												LTP_Analyze(4) <= (others=>'0');
												LTP_Analyze(8) <= (others=>'0');
												LTP_Analyze(16) <= (others=>'0');
												LTP_Analyze(32) <= (others=>'0');
												LTP_Analyze(64) <= (others=>'0');
												LTP_Analyze(128) <= (others=>'0');
												FrameNumber <= 0;
											when 2 =>
												LTP_Analyze(1)(7 downto 0) <= LTP_Analyze(1)(15 downto 8);	
												LTP_Analyze(2)(7 downto 0) <= LTP_Analyze(2)(15 downto 8);	
												LTP_Analyze(4)(7 downto 0) <= LTP_Analyze(4)(15 downto 8);	
												LTP_Analyze(8)(7 downto 0) <= LTP_Analyze(8)(15 downto 8);	
												LTP_Analyze(16)(7 downto 0) <= LTP_Analyze(16)(15 downto 8);	
												LTP_Analyze(32)(7 downto 0) <= LTP_Analyze(32)(15 downto 8);	
												LTP_Analyze(64)(7 downto 0) <= LTP_Analyze(64)(15 downto 8);	
												LTP_Analyze(128)(7 downto 0) <= LTP_Analyze(128)(15 downto 8);
												FrameNumber <= FrameNumber + 1;
												Display_EN <= '1';
											when 3 =>												
												Sample_Hand_1 <= CONV_INTEGER(LTP_Analyze(1)(7 downto 0));
												Sample_Hand_2 <= CONV_INTEGER(LTP_Analyze(2)(7 downto 0));
												Sample_Hand_4 <= CONV_INTEGER(LTP_Analyze(4)(7 downto 0));
												Sample_Hand_8 <= CONV_INTEGER(LTP_Analyze(8)(7 downto 0));
												Sample_Hand_16 <= CONV_INTEGER(LTP_Analyze(16)(7 downto 0));
												Sample_Hand_32 <= CONV_INTEGER(LTP_Analyze(32)(7 downto 0));
												Sample_Hand_64 <= CONV_INTEGER(LTP_Analyze(64)(7 downto 0));
												Sample_Hand_128 <= CONV_INTEGER(LTP_Analyze(128)(7 downto 0));
												FrameNumber <= FrameNumber + 1;
											when 4 =>
												if ((Sample_Hand_1 > 1 and Sample_Hand_1 < 75) and (Sample_Hand_2 > 1 and Sample_Hand_2 < 75) and (Sample_Hand_4 > 1 and Sample_Hand_4 < 75) and (Sample_Hand_16 > 1 and Sample_Hand_16 < 75) and (Sample_Hand_32 > 1 and Sample_Hand_32 < 75) and (Sample_Hand_64 > 1 and Sample_Hand_64 < 75)) then
													Sample_Hand_1_Flag <= '1';
													Sample_Hand_2_Flag <= '1';
													Sample_Hand_4_Flag <= '1';
													Sample_Hand_16_Flag <= '1';
													Sample_Hand_32_Flag <= '1';
													Sample_Hand_64_Flag <= '1';
												else
													Sample_Hand_1_Flag <= '0';
													Sample_Hand_2_Flag <= '0';
													Sample_Hand_4_Flag <= '0';
													Sample_Hand_16_Flag <= '0';
													Sample_Hand_32_Flag <= '0';
													Sample_Hand_64_Flag <= '0';
												end if;
												if (Sample_Hand_8 > 100 and Sample_Hand_8 < 300) then
													Sample_Hand_8_Flag <= '1';
												else
													Sample_Hand_8_Flag <= '0';
												end if;
												if (Sample_Hand_128 > 100 and Sample_Hand_128 < 275) then
													Sample_Hand_128_Flag <= '1';
												else
													Sample_Hand_128_Flag <= '0';
												end if;
												FrameNumber <= FrameNumber + 1;
											when others =>
												if FrameNumber < 2 then
													FrameNumber <= FrameNumber + 1;
												else
													FrameNumber <= FrameNumber + 1;
													DebugEn <= '1';
												end if;
										end case;
									else
										FrameCnt <= FrameCnt + 1;
									end if;
									-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ Inner Special Range 150x200 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ --
								end if;
							end if;										
						end if;
					end if;
				else
					CaptureIR_cnt <= 639;
				end if;
			end if;
		end if;
	end if;
end process CaptureInnerRange;
--############################################### Capture Inner Range ##############################################-- 

--############################################### Display VGA ##############################################-- 
Display_VGA:process(rst_system, clk_video)
begin
if rst_system = '0' then
	r_vga <= "000";
	g_vga <= "000";
	b_vga <= "000";
	buf_vga_Y_out_cnt <= 0;
	--FrameNumber <= 0;
	--FrameCnt <= 0;
	--Display_EN <= '0';
	-- show_frame_en <= '0';
	-- available_frame_value <= 0;
elsif rising_edge(clk_video) then
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
					if cnt_h_sync_vga > 280 and cnt_h_sync_vga < 536 then
						
						-- if( ( cnt_v_sync_vga > (480 - CONV_INTEGER(LTP_Analyze(cnt_h_sync_vga-281)(8 downto 0)))) and cnt_v_sync_vga < 480 )then					
							-- r_vga <= "111";
							-- g_vga <= "000";							
							-- b_vga <= "000";
						-- else
							-- r_vga <= "111";
							-- g_vga <= "111";
							-- b_vga <= "111";						
						-- end if;	
						if Display_EN = '1' then						
							if( cnt_h_sync_vga = 300 and ( cnt_v_sync_vga > (480 - CONV_INTEGER(LTP_Display(1)(8 downto 0)))) and cnt_v_sync_vga < 480 )then					
								r_vga <= "111";
								g_vga <= "000";
								b_vga <= "000";
							elsif( cnt_h_sync_vga = 310 and ( cnt_v_sync_vga > (480 - CONV_INTEGER(LTP_Display(2)(8 downto 0)))) and cnt_v_sync_vga < 480 )then					
								r_vga <= "111";
								g_vga <= "000";
								b_vga <= "000";
							elsif( cnt_h_sync_vga = 320 and ( cnt_v_sync_vga > (480 - CONV_INTEGER(LTP_Display(4)(8 downto 0)))) and cnt_v_sync_vga < 480 )then					
								r_vga <= "111";
								g_vga <= "000";
								b_vga <= "000";
							elsif( cnt_h_sync_vga = 330 and ( cnt_v_sync_vga > (480 - CONV_INTEGER(LTP_Display(8)(8 downto 0)))) and cnt_v_sync_vga < 480 )then					
								r_vga <= "111";
								g_vga <= "000";
								b_vga <= "000";
							elsif( cnt_h_sync_vga = 340 and ( cnt_v_sync_vga > (480 - CONV_INTEGER(LTP_Display(16)(8 downto 0)))) and cnt_v_sync_vga < 480 )then					
								r_vga <= "111";
								g_vga <= "000";
								b_vga <= "000";
							elsif( cnt_h_sync_vga = 350 and ( cnt_v_sync_vga > (480 - CONV_INTEGER(LTP_Display(32)(8 downto 0)))) and cnt_v_sync_vga < 480 )then					
								r_vga <= "111";
								g_vga <= "000";
								b_vga <= "000";
							elsif( cnt_h_sync_vga = 360 and ( cnt_v_sync_vga > (480 - CONV_INTEGER(LTP_Display(64)(8 downto 0)))) and cnt_v_sync_vga < 480 )then					
								r_vga <= "111";
								g_vga <= "000";
								b_vga <= "000";
							elsif( cnt_h_sync_vga = 370 and ( cnt_v_sync_vga > (480 - CONV_INTEGER(LTP_Display(128)(8 downto 0)))) and cnt_v_sync_vga < 480 )then					
								r_vga <= "111";
								g_vga <= "000";
								b_vga <= "000";		
							elsif( cnt_h_sync_vga = 400 and ( cnt_v_sync_vga > (480 - CONV_INTEGER(LTP_Character)) and cnt_v_sync_vga < 480 ))then					
								r_vga <= "000";
								g_vga <= "000";
								b_vga <= "111";	
							elsif( cnt_h_sync_vga = 425 and ( cnt_v_sync_vga > (480 - 25) and cnt_v_sync_vga < 480 ))then					
								r_vga <= "000";
								g_vga <= "000";
								b_vga <= "111";		
							elsif( cnt_h_sync_vga = 430 and ( cnt_v_sync_vga > (480 - 50) and cnt_v_sync_vga < 480 ))then					
								r_vga <= "000";
								g_vga <= "000";
								b_vga <= "111";		
							elsif( cnt_h_sync_vga = 435 and ( cnt_v_sync_vga > (480 - 75) and cnt_v_sync_vga < 480 ))then					
								r_vga <= "000";
								g_vga <= "000";
								b_vga <= "111";		
							elsif( cnt_h_sync_vga = 440 and ( cnt_v_sync_vga > (480 - 100) and cnt_v_sync_vga < 480 ))then					
								r_vga <= "111";
								g_vga <= "000";
								b_vga <= "000";		
							elsif( cnt_h_sync_vga = 445 and ( cnt_v_sync_vga > (480 - 125) and cnt_v_sync_vga < 480 ))then					
								r_vga <= "000";
								g_vga <= "000";
								b_vga <= "111";		
							elsif( cnt_h_sync_vga = 450 and ( cnt_v_sync_vga > (480 - 150) and cnt_v_sync_vga < 480 ))then					
								r_vga <= "000";
								g_vga <= "000";
								b_vga <= "111";		
							elsif( cnt_h_sync_vga = 455 and ( cnt_v_sync_vga > (480 - 175) and cnt_v_sync_vga < 480 ))then					
								r_vga <= "000";
								g_vga <= "000";
								b_vga <= "111";		
							elsif( cnt_h_sync_vga = 460 and ( cnt_v_sync_vga > (480 - 200) and cnt_v_sync_vga < 480 ))then					
								r_vga <= "111";
								g_vga <= "000";
								b_vga <= "000";		
							elsif( cnt_h_sync_vga = 465 and ( cnt_v_sync_vga > (480 - 225) and cnt_v_sync_vga < 480 ))then					
								r_vga <= "000";
								g_vga <= "000";
								b_vga <= "111";		
							elsif( cnt_h_sync_vga = 470 and ( cnt_v_sync_vga > (480 - 250) and cnt_v_sync_vga < 480 ))then					
								r_vga <= "000";
								g_vga <= "000";
								b_vga <= "111";		
							elsif( cnt_h_sync_vga = 475 and ( cnt_v_sync_vga > (480 - 275) and cnt_v_sync_vga < 480 ))then					
								r_vga <= "000";
								g_vga <= "000";
								b_vga <= "111";		
							elsif( cnt_h_sync_vga = 480 and ( cnt_v_sync_vga > (480 - 300) and cnt_v_sync_vga < 480 ))then					
								r_vga <= "111";
								g_vga <= "000";
								b_vga <= "000";		
							elsif( cnt_h_sync_vga = 485 and ( cnt_v_sync_vga > (480 - 325) and cnt_v_sync_vga < 480 ))then					
								r_vga <= "000";
								g_vga <= "000";
								b_vga <= "111";		
							elsif( cnt_h_sync_vga = 490 and ( cnt_v_sync_vga > (480 - 350) and cnt_v_sync_vga < 480 ))then					
								r_vga <= "000";
								g_vga <= "000";
								b_vga <= "111";		
							elsif( cnt_h_sync_vga = 495 and ( cnt_v_sync_vga > (480 - 375) and cnt_v_sync_vga < 480 ))then					
								r_vga <= "000";
								g_vga <= "000";
								b_vga <= "111";		
							elsif( cnt_h_sync_vga = 500 and ( cnt_v_sync_vga > (480 - 400) and cnt_v_sync_vga < 480 ))then					
								r_vga <= "111";
								g_vga <= "000";
								b_vga <= "000";		
							elsif( cnt_h_sync_vga = 505 and ( cnt_v_sync_vga > (480 - 425) and cnt_v_sync_vga < 480 ))then					
								r_vga <= "000";
								g_vga <= "000";
								b_vga <= "111";		
							elsif( cnt_h_sync_vga = 510 and ( cnt_v_sync_vga > (480 - 450) and cnt_v_sync_vga < 480 ))then					
								r_vga <= "000";
								g_vga <= "000";
								b_vga <= "111";		
							elsif( cnt_h_sync_vga = 515 and ( cnt_v_sync_vga > (480 - 475) and cnt_v_sync_vga < 480 ))then					
								r_vga <= "000";
								g_vga <= "000";
								b_vga <= "111";	
							else
								r_vga <= "111";
								g_vga <= "111";
								b_vga <= "111";	
							end if;
						else
							r_vga <= "000";
							g_vga <= "000";
							b_vga <= "000";
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
									-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ Inner Special Range 150x200 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ --
									--r_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
									--g_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
									--b_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
									r_vga <= LTP_Edge3_Value(buf_vga_Y_out_cnt)(7 downto 5);
									g_vga <= LTP_Edge3_Value(buf_vga_Y_out_cnt)(7 downto 5);
									b_vga <= LTP_Edge3_Value(buf_vga_Y_out_cnt)(7 downto 5);

									-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ Inner Special Range 150x200 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ --
								end if;
							end if;
						else					
							if((cnt_v_sync_vga > 300 and cnt_v_sync_vga < 480)) then
								if(cnt_h_sync_vga > 1 and cnt_h_sync_vga < 5) and (cnt_v_sync_vga > 480-25 and cnt_v_sync_vga < 480) then								
									r_vga <= "111";
									g_vga <= "111";
									b_vga <= "000";
								-- elsif((cnt_h_sync_vga > 5 and cnt_h_sync_vga < 10) and (cnt_v_sync_vga > 480-50 and cnt_v_sync_vga < 480)) then 
									-- r_vga <= "000";
									-- g_vga <= "111";
									-- b_vga <= "000";
								-- elsif((cnt_h_sync_vga > 10 and cnt_h_sync_vga < 15) and(cnt_v_sync_vga > 480-75 and cnt_v_sync_vga < 480)) then 
									-- r_vga <= "111";
									-- g_vga <= "111";
									-- b_vga <= "000";														
								else	
									-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ Palm Identify Range of show Result $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ --
									if((cnt_h_sync_vga > 540 and cnt_h_sync_vga < 580) and(cnt_v_sync_vga > 480-150 and cnt_v_sync_vga < 480)) then 
										if (Sample_Hand_1_Flag = '1' and Sample_Hand_2_Flag = '1' and Sample_Hand_4_Flag = '1' and Sample_Hand_8_Flag = '1' and Sample_Hand_16_Flag = '1' and Sample_Hand_32_Flag = '1' and Sample_Hand_64_Flag = '1' and Sample_Hand_128_Flag = '1' ) then
											r_vga <= "000";
											g_vga <= "111";
											b_vga <= "000";
										else
											r_vga <= "111";
											g_vga <= "000";
											b_vga <= "111";
										end if;
									else
										r_vga <= "111";
										g_vga <= "111";
										b_vga <= "111";
									end if;
									-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ Palm Identify Range of show Result $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ --
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
								--r_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
								--g_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
								--b_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
								r_vga <= LTP_Edge3_Value(buf_vga_Y_out_cnt)(7 downto 5);
								g_vga <= LTP_Edge3_Value(buf_vga_Y_out_cnt)(7 downto 5);
								b_vga <= LTP_Edge3_Value(buf_vga_Y_out_cnt)(7 downto 5);								
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
				if cnt_h_sync_vga > 641 and DebugEn = '1' then						
					--LTP_Analyze(CONV_INTEGER(LTP_Value(buf_vga_Y_out_cnt)(7 downto 0)))(7 downto 0) <= LTP_Analyze(CONV_INTEGER(LTP_Value(buf_vga_Y_out_cnt)(7 downto 0)))(9 downto 2);	
					-- LTP_Analyze(cnt_h_sync_vga) <= (others=>'0');
					-- DebugEn <= '0';
					-- LTP_Analyze(1) <= (others=>'0');
					-- LTP_Analyze(2) <= (others=>'0');
					-- LTP_Analyze(4) <= (others=>'0');
					-- LTP_Analyze(8) <= (others=>'0');
					-- LTP_Analyze(16) <= (others=>'0');
					-- LTP_Analyze(32) <= (others=>'0');
					-- LTP_Analyze(64) <= (others=>'0');
					-- LTP_Analyze(128) <= (others=>'0');
				end if;
			end if;
		else
			r_vga <= "000";
			g_vga <= "000";
			b_vga <= "000";
			--available_frame_cnt <= 300;
			--available_frame_en <= '0';
			--available_frame_value <= 0;
		end if;
--	
end if;
end process Display_VGA;
--############################################### Display VGA ###############################################--

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
	LBP_Data_State <= "00";--######### new buffer matrix == State #########--
else
	if rising_edge(clk_video) then
		-- if (buf_vga_en = '1' and f_video_en = '0' and cnt_video_hsync < 1290) then
		if (buf_vga_en = '1' and cnt_video_hsync < 1290) then
			if buf_data_state = "11" then
				buf_data_state <= "00";
			else
				buf_data_state <= buf_data_state + '1';
			end if;
			--######### new buffer matrix == State #########--
			if LBP_Data_State = "11" then
				LBP_Data_State <= "00";
			else
				LBP_Data_State <= LBP_Data_State + '1';
			end if;
			--######### new buffer matrix == State #########--

			if (cnt_video_hsync >= 0 and cnt_video_hsync < 1290 and cnt_v_sync_vga >= 0 and cnt_v_sync_vga < 480) then
				if range_total_cnt_en = '0' then
					if buf_data_state = "11" then
						range_total_cnt_en <= '1';
						SBB_buf_en <= '1';
						SB_buf_012_en <= '1';
						buf_sobel_cc_en <= '1';
					end if;

					--######### new buffer matrix == State #########--
					if LBP_Data_State = "11"  then
						range_total_cnt_en <= '1';
						SBB_buf_en <= '1';
						SB_buf_012_en <= '1';
						buf_sobel_cc_en <= '1';
					end if;
					--######### new buffer matrix == State #########--
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
			LBP_Data_State <= "00"; --######### new buffer matrix == State #########--
		end if;
	end if;
end if;
end process Buffer_State;
--############################################### Buffer State ###############################################--


-- --############################################### Sobel Calculate ###############################################--
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
end process Sobel_Calculate;
-- --############################################### Sobel Calculate ###############################################--


--############################################### LTP_Edge Buffer Matrix ###############################################--
LTP_EdgeBufferMatrix:process(rst_system, clk_video)
begin
if rst_system = '0' then
	LTP_Edge_R1C1 <= "0000000000";
	LTP_Edge_R2C1 <= "0000000000";
	LTP_Edge_R3C1 <= "0000000000";
	
	LTP_Edge_R1C2 <= "0000000000";
	LTP_Edge_R2C2 <= "0000000000";
	LTP_Edge_R3C2 <= "0000000000";
	
	LTP_Edge_R1C3 <= "0000000000";
	LTP_Edge_R2C3 <= "0000000000";
	LTP_Edge_R3C3 <= "0000000000";
	LTP_Edge_Buf_Cnt <= 0;

else
	if rising_edge(clk_video) then
		if (buf_vga_en = '1' and cnt_video_hsync < 1280) then
			if LBP_Data_State(0) = '0' then				
				LTP_Edge_R1C1 <= "00" & LTP_Edge_Column_1(LTP_Edge_Buf_Cnt);
				LTP_Edge_R2C1 <= LTP_Edge_R1C1;
				LTP_Edge_R3C1 <= LTP_Edge_R2C1;
				
				LTP_Edge_R1C2 <= "00" & LTP_Edge_Column_2(LTP_Edge_Buf_Cnt);
				LTP_Edge_R2C2 <= LTP_Edge_R1C2;
				LTP_Edge_R3C2 <= LTP_Edge_R2C2;
				
				LTP_Edge_R1C3 <= "00" & LTP_Edge_Column_3(LTP_Edge_Buf_Cnt);
				LTP_Edge_R2C3 <= LTP_Edge_R1C3;
				LTP_Edge_R3C3 <= LTP_Edge_R2C3;
				
			else	

				LTP_Edge_Column_1(LTP_Edge_Buf_Cnt) <= data_video(7 downto 0);
				LTP_Edge_Column_2(LTP_Edge_Buf_Cnt) <= LTP_Edge_R3C1(7 downto 0);
				LTP_Edge_Column_3(LTP_Edge_Buf_Cnt) <= LTP_Edge_R3C2(7 downto 0);
				
				if LTP_Edge_Buf_Cnt = LTP_Edge_Buf_Length_Max then
					LTP_Edge_Buf_Cnt <= 0;
				else
					LTP_Edge_Buf_Cnt <= LTP_Edge_Buf_Cnt + 1 ;
				end if;				
			end if;
		else
			LTP_Edge_R1C1 <= "0000000000";
			LTP_Edge_R2C1 <= "0000000000";
			LTP_Edge_R3C1 <= "0000000000";
			
			LTP_Edge_R1C2 <= "0000000000";
			LTP_Edge_R2C2 <= "0000000000";
			LTP_Edge_R3C2 <= "0000000000";
			
			LTP_Edge_R1C3 <= "0000000000";
			LTP_Edge_R2C3 <= "0000000000";
			LTP_Edge_R3C3 <= "0000000000";
			LTP_Edge_Buf_Cnt <= 0;
		end if;
	end if;
end if;
end process LTP_EdgeBufferMatrix;
--############################################### LTP_Edge Buffer Matrix ###############################################--

--############################################### LTP_Edge to LTP Calculate ###############################################--
LTP_Edge_LTP_Calculate:process(rst_system, clk_video)
variable LTP_Edge_R2C2_Encode_Reg_U	: std_logic_vector(9 downto 0);
variable LTP_Edge_R2C2_Encode_Reg_D	: std_logic_vector(9 downto 0);
begin
if rst_system = '0' then
	LTP_Edge_R2C2_Encode <= (others =>'0');
	LTP_Edge_R2C2_Encode_Bit <= (others =>'0');
	LTP_Edge_R2C2_Encode_Bit2<= (others =>'0');
	LTP_Edge_Cnt <= 0;
else
	if rising_edge(clk_video) then
		if buf_sobel_cc_en = '1' then
			if Sobel_Cal_en = '1' then
			-- if buf_data_state(0) = '0' then
				LTP_Edge_R2C2_Encode_Reg_U := LTP_Edge_R2C2 + R2C2_Encode_Threshold ;
				LTP_Edge_R2C2_Encode_Reg_D := LTP_Edge_R2C2 - R2C2_Encode_Threshold ;

				if LTP_Edge_R1C1 > LTP_Edge_R2C2_Encode_Reg_U then
					LTP_Edge_R2C2_Encode_Bit(7) <= '1';
					LTP_Edge_R2C2_Encode_Bit2(7) <= '0';
				elsif LTP_Edge_R1C1 < LTP_Edge_R2C2_Encode_Reg_D then
					LTP_Edge_R2C2_Encode_Bit(7) <= '0';
					LTP_Edge_R2C2_Encode_Bit2(7) <= '1';
				else 
					LTP_Edge_R2C2_Encode_Bit(7) <= '0';
					LTP_Edge_R2C2_Encode_Bit2(7) <= '0';
				end if;
				if LTP_Edge_R2C1 > LTP_Edge_R2C2_Encode_Reg_U then
					LTP_Edge_R2C2_Encode_Bit(6) <= '1';
					LTP_Edge_R2C2_Encode_Bit2(6) <= '0';
				elsif LTP_Edge_R2C1 < LTP_Edge_R2C2_Encode_Reg_D then
					LTP_Edge_R2C2_Encode_Bit(6) <= '0';
					LTP_Edge_R2C2_Encode_Bit2(6) <= '1';
				else 
					LTP_Edge_R2C2_Encode_Bit(6) <= '0';
					LTP_Edge_R2C2_Encode_Bit2(6) <= '0';
				end if;
				if LTP_Edge_R3C1 > LTP_Edge_R2C2_Encode_Reg_U then
					LTP_Edge_R2C2_Encode_Bit(5) <= '1';
					LTP_Edge_R2C2_Encode_Bit2(5) <= '0';
				elsif LTP_Edge_R3C1 < LTP_Edge_R2C2_Encode_Reg_D then
					LTP_Edge_R2C2_Encode_Bit(5) <= '0';
					LTP_Edge_R2C2_Encode_Bit2(5) <= '1';
				else 
					LTP_Edge_R2C2_Encode_Bit(5) <= '0';
					LTP_Edge_R2C2_Encode_Bit2(5) <= '0';
				end if;
				if LTP_Edge_R3C2 > LTP_Edge_R2C2_Encode_Reg_U then
					LTP_Edge_R2C2_Encode_Bit(4) <= '1';
					LTP_Edge_R2C2_Encode_Bit2(4) <= '0';
				elsif LTP_Edge_R3C2 < LTP_Edge_R2C2_Encode_Reg_D then
					LTP_Edge_R2C2_Encode_Bit(4) <= '0';
					LTP_Edge_R2C2_Encode_Bit2(4) <= '1';
				else 
					LTP_Edge_R2C2_Encode_Bit(4) <= '0';
					LTP_Edge_R2C2_Encode_Bit2(4) <= '0';
				end if;
				if LTP_Edge_R3C3 > LTP_Edge_R2C2_Encode_Reg_U then
					LTP_Edge_R2C2_Encode_Bit(3) <= '1';
					LTP_Edge_R2C2_Encode_Bit2(3) <= '0';
				elsif LTP_Edge_R3C3 < LTP_Edge_R2C2_Encode_Reg_D then
					LTP_Edge_R2C2_Encode_Bit(3) <= '0';
					LTP_Edge_R2C2_Encode_Bit2(3) <= '1';
				else 
					LTP_Edge_R2C2_Encode_Bit(3) <= '0';
					LTP_Edge_R2C2_Encode_Bit2(3) <= '0';
				end if;
				if LTP_Edge_R2C3 > LTP_Edge_R2C2_Encode_Reg_U then
					LTP_Edge_R2C2_Encode_Bit(2) <= '1';
					LTP_Edge_R2C2_Encode_Bit2(2) <= '0';
				elsif LTP_Edge_R2C3 < LTP_Edge_R2C2_Encode_Reg_D then
					LTP_Edge_R2C2_Encode_Bit(2) <= '0';
					LTP_Edge_R2C2_Encode_Bit2(2) <= '1';
				else 
					LTP_Edge_R2C2_Encode_Bit(2) <= '0';
					LTP_Edge_R2C2_Encode_Bit2(2) <= '0';
				end if;
				if LTP_Edge_R1C3 > LTP_Edge_R2C2_Encode_Reg_U then
					LTP_Edge_R2C2_Encode_Bit(1) <= '1';
					LTP_Edge_R2C2_Encode_Bit2(1) <= '0';
				elsif LTP_Edge_R1C3 < LTP_Edge_R2C2_Encode_Reg_D then
					LTP_Edge_R2C2_Encode_Bit(1) <= '0';
					LTP_Edge_R2C2_Encode_Bit2(1) <= '1';
				else 
					LTP_Edge_R2C2_Encode_Bit(1) <= '0';
					LTP_Edge_R2C2_Encode_Bit2(1) <= '0';
				end if;
				if LTP_Edge_R1C2 > LTP_Edge_R2C2_Encode_Reg_U then
					LTP_Edge_R2C2_Encode_Bit(0) <= '1';
					LTP_Edge_R2C2_Encode_Bit2(0) <= '0';
				elsif LTP_Edge_R1C2 < LTP_Edge_R2C2_Encode_Reg_D then
					LTP_Edge_R2C2_Encode_Bit(0) <= '0';
					LTP_Edge_R2C2_Encode_Bit2(0) <= '1';
				else 
					LTP_Edge_R2C2_Encode_Bit(0) <= '0';
					LTP_Edge_R2C2_Encode_Bit2(0) <= '0';
				end if;

			else
				if ImageSelect = '0' then
					LTP_Edge_R2C2_Encode <= LTP_Edge_R2C2_Encode_Bit;
				else
					LTP_Edge_R2C2_Encode <= LTP_Edge_R2C2_Encode_Bit2;
				end if;
				--if ImageSelect = '0' then
				--	LTP_Edge_R2C2_Encode <= LTP_Edge_R2C2_Encode_Bit and LTP_Edge_R2C2_Encode_Bit2;
				--else
				--	LTP_Edge_R2C2_Encode <= LTP_Edge_R2C2_Encode_Bit xor LTP_Edge_R2C2_Encode_Bit2;					
				--end if;
				LTP_Edge_Value(LTP_Edge_Cnt) <= LTP_Edge_R2C2_Encode;
				if LTP_Edge_Cnt < 639 then
					LTP_Edge_Cnt <= LTP_Edge_Cnt + 1;
				else
					LTP_Edge_Cnt <= 0;
				end if;

			end if;
		else
			LTP_Edge_R2C2_Encode <= (others =>'0');
			LTP_Edge_R2C2_Encode_Bit <= (others =>'0');
-- when cnt_video_hsync > 1280, let redata_cnt be reset
			LTP_Edge_Cnt <= 0;
		end if;
	end if;
end if;
end process LTP_Edge_LTP_Calculate;
--############################################### LTP_Edge to LTP Calculate ###############################################--


--############################################### LTP_Edge2 Buffer Matrix ###############################################--
--LTP_Edge2BufferMatrix:process(rst_system, clk_video)
--begin
--if rst_system = '0' then
--	LTP_Edge2_R1C1 <= "0000000000";
--	LTP_Edge2_R2C1 <= "0000000000";
--	LTP_Edge2_R3C1 <= "0000000000";
	
--	LTP_Edge2_R1C2 <= "0000000000";
--	LTP_Edge2_R2C2 <= "0000000000";
--	LTP_Edge2_R3C2 <= "0000000000";
	
--	LTP_Edge2_R1C3 <= "0000000000";
--	LTP_Edge2_R2C3 <= "0000000000";
--	LTP_Edge2_R3C3 <= "0000000000";
--	LTP_Edge2_Buf_Cnt <= 0;

--else
--	if rising_edge(clk_video) then
--		if (buf_vga_en = '1' and cnt_video_hsync < 1280) then
--			if LBP_Data_State(0) = '0' then				
--				LTP_Edge2_R1C1 <= "00" & LTP_Edge2_Column_1(LTP_Edge2_Buf_Cnt);
--				LTP_Edge2_R2C1 <= LTP_Edge2_R1C1;
--				LTP_Edge2_R3C1 <= LTP_Edge2_R2C1;
				
--				LTP_Edge2_R1C2 <= "00" & LTP_Edge2_Column_2(LTP_Edge2_Buf_Cnt);
--				LTP_Edge2_R2C2 <= LTP_Edge2_R1C2;
--				LTP_Edge2_R3C2 <= LTP_Edge2_R2C2;
				
--				LTP_Edge2_R1C3 <= "00" & LTP_Edge2_Column_3(LTP_Edge2_Buf_Cnt);
--				LTP_Edge2_R2C3 <= LTP_Edge2_R1C3;
--				LTP_Edge2_R3C3 <= LTP_Edge2_R2C3;
				
--			else	

--				LTP_Edge2_Column_1(LTP_Edge2_Buf_Cnt) <= LTP_Edge_Value(LTP_Edge_Cnt)(7 downto 0);
--				LTP_Edge2_Column_2(LTP_Edge2_Buf_Cnt) <= LTP_Edge2_R3C1(7 downto 0);
--				LTP_Edge2_Column_3(LTP_Edge2_Buf_Cnt) <= LTP_Edge2_R3C2(7 downto 0);
				
--				if LTP_Edge2_Buf_Cnt = LTP_Edge2_Buf_Length_Max then
--					LTP_Edge2_Buf_Cnt <= 0;
--				else
--					LTP_Edge2_Buf_Cnt <= LTP_Edge2_Buf_Cnt + 1 ;
--				end if;				
--			end if;
--		else
--			LTP_Edge2_R1C1 <= "0000000000";
--			LTP_Edge2_R2C1 <= "0000000000";
--			LTP_Edge2_R3C1 <= "0000000000";
			
--			LTP_Edge2_R1C2 <= "0000000000";
--			LTP_Edge2_R2C2 <= "0000000000";
--			LTP_Edge2_R3C2 <= "0000000000";
			
--			LTP_Edge2_R1C3 <= "0000000000";
--			LTP_Edge2_R2C3 <= "0000000000";
--			LTP_Edge2_R3C3 <= "0000000000";
--			LTP_Edge2_Buf_Cnt <= 0;
--		end if;
--	end if;
--end if;
--end process LTP_Edge2BufferMatrix;
--############################################### LTP_Edge Buffer Matrix ###############################################--

--############################################### LTP_Edge2 to LTP Calculate ###############################################--
LTP_Edge2_LTP_Calculate:process(rst_system, clk_video)
variable LTP_Edge2_R2C2_Encode_Reg_U	: std_logic_vector(9 downto 0);
variable LTP_Edge2_R2C2_Encode_Reg_D	: std_logic_vector(9 downto 0);
begin
if rst_system = '0' then
	LTP_Edge2_R2C2_Encode <= (others =>'0');
	LTP_Edge2_R2C2_Encode_Bit <= (others =>'0');
	LTP_Edge2_R2C2_Encode_Bit2<= (others =>'0');
	LTP_Edge2_Cnt <= 0;
else
	if rising_edge(clk_video) then
		if buf_sobel_cc_en = '1' then
			if Sobel_Cal_en = '1' then
			-- if buf_data_state(0) = '0' then
				LTP_Edge2_R2C2_Encode_Reg_U := LTP_Edge2_R2C2 + R2C2_Encode_Threshold ;
				LTP_Edge2_R2C2_Encode_Reg_D := LTP_Edge2_R2C2 - R2C2_Encode_Threshold ;

				if LTP_Edge2_R1C1 > LTP_Edge2_R2C2_Encode_Reg_U then
					LTP_Edge2_R2C2_Encode_Bit(7) <= '1';
					LTP_Edge2_R2C2_Encode_Bit2(7) <= '0';
				elsif LTP_Edge2_R1C1 < LTP_Edge2_R2C2_Encode_Reg_D then
					LTP_Edge2_R2C2_Encode_Bit(7) <= '0';
					LTP_Edge2_R2C2_Encode_Bit2(7) <= '1';
				else 
					LTP_Edge2_R2C2_Encode_Bit(7) <= '0';
					LTP_Edge2_R2C2_Encode_Bit2(7) <= '0';
				end if;
				if LTP_Edge2_R2C1 > LTP_Edge2_R2C2_Encode_Reg_U then
					LTP_Edge2_R2C2_Encode_Bit(6) <= '1';
					LTP_Edge2_R2C2_Encode_Bit2(6) <= '0';
				elsif LTP_Edge2_R2C1 < LTP_Edge2_R2C2_Encode_Reg_D then
					LTP_Edge2_R2C2_Encode_Bit(6) <= '0';
					LTP_Edge2_R2C2_Encode_Bit2(6) <= '1';
				else 
					LTP_Edge2_R2C2_Encode_Bit(6) <= '0';
					LTP_Edge2_R2C2_Encode_Bit2(6) <= '0';
				end if;
				if LTP_Edge2_R3C1 > LTP_Edge2_R2C2_Encode_Reg_U then
					LTP_Edge2_R2C2_Encode_Bit(5) <= '1';
					LTP_Edge2_R2C2_Encode_Bit2(5) <= '0';
				elsif LTP_Edge2_R3C1 < LTP_Edge2_R2C2_Encode_Reg_D then
					LTP_Edge2_R2C2_Encode_Bit(5) <= '0';
					LTP_Edge2_R2C2_Encode_Bit2(5) <= '1';
				else 
					LTP_Edge2_R2C2_Encode_Bit(5) <= '0';
					LTP_Edge2_R2C2_Encode_Bit2(5) <= '0';
				end if;
				if LTP_Edge2_R3C2 > LTP_Edge2_R2C2_Encode_Reg_U then
					LTP_Edge2_R2C2_Encode_Bit(4) <= '1';
					LTP_Edge2_R2C2_Encode_Bit2(4) <= '0';
				elsif LTP_Edge2_R3C2 < LTP_Edge2_R2C2_Encode_Reg_D then
					LTP_Edge2_R2C2_Encode_Bit(4) <= '0';
					LTP_Edge2_R2C2_Encode_Bit2(4) <= '1';
				else 
					LTP_Edge2_R2C2_Encode_Bit(4) <= '0';
					LTP_Edge2_R2C2_Encode_Bit2(4) <= '0';
				end if;
				if LTP_Edge2_R3C3 > LTP_Edge2_R2C2_Encode_Reg_U then
					LTP_Edge2_R2C2_Encode_Bit(3) <= '1';
					LTP_Edge2_R2C2_Encode_Bit2(3) <= '0';
				elsif LTP_Edge2_R3C3 < LTP_Edge2_R2C2_Encode_Reg_D then
					LTP_Edge2_R2C2_Encode_Bit(3) <= '0';
					LTP_Edge2_R2C2_Encode_Bit2(3) <= '1';
				else 
					LTP_Edge2_R2C2_Encode_Bit(3) <= '0';
					LTP_Edge2_R2C2_Encode_Bit2(3) <= '0';
				end if;
				if LTP_Edge2_R2C3 > LTP_Edge2_R2C2_Encode_Reg_U then
					LTP_Edge2_R2C2_Encode_Bit(2) <= '1';
					LTP_Edge2_R2C2_Encode_Bit2(2) <= '0';
				elsif LTP_Edge2_R2C3 < LTP_Edge2_R2C2_Encode_Reg_D then
					LTP_Edge2_R2C2_Encode_Bit(2) <= '0';
					LTP_Edge2_R2C2_Encode_Bit2(2) <= '1';
				else 
					LTP_Edge2_R2C2_Encode_Bit(2) <= '0';
					LTP_Edge2_R2C2_Encode_Bit2(2) <= '0';
				end if;
				if LTP_Edge2_R1C3 > LTP_Edge2_R2C2_Encode_Reg_U then
					LTP_Edge2_R2C2_Encode_Bit(1) <= '1';
					LTP_Edge2_R2C2_Encode_Bit2(1) <= '0';
				elsif LTP_Edge2_R1C3 < LTP_Edge2_R2C2_Encode_Reg_D then
					LTP_Edge2_R2C2_Encode_Bit(1) <= '0';
					LTP_Edge2_R2C2_Encode_Bit2(1) <= '1';
				else 
					LTP_Edge2_R2C2_Encode_Bit(1) <= '0';
					LTP_Edge2_R2C2_Encode_Bit2(1) <= '0';
				end if;
				if LTP_Edge2_R1C2 > LTP_Edge2_R2C2_Encode_Reg_U then
					LTP_Edge2_R2C2_Encode_Bit(0) <= '1';
					LTP_Edge2_R2C2_Encode_Bit2(0) <= '0';
				elsif LTP_Edge2_R1C2 < LTP_Edge2_R2C2_Encode_Reg_D then
					LTP_Edge2_R2C2_Encode_Bit(0) <= '0';
					LTP_Edge2_R2C2_Encode_Bit2(0) <= '1';
				else 
					LTP_Edge2_R2C2_Encode_Bit(0) <= '0';
					LTP_Edge2_R2C2_Encode_Bit2(0) <= '0';
				end if;

			else
				if ImageSelect = '0' then
					LTP_Edge2_R2C2_Encode <= LTP_Edge2_R2C2_Encode_Bit;
				else
					LTP_Edge2_R2C2_Encode <= LTP_Edge2_R2C2_Encode_Bit2;
				end if;
				
				LTP_Edge2_Value(LTP_Edge2_Cnt) <= LTP_Edge2_R2C2_Encode;
				if LTP_Edge2_Cnt < 639 then
					LTP_Edge2_Cnt <= LTP_Edge2_Cnt + 1;
				else
					LTP_Edge2_Cnt <= 0;
				end if;

			end if;
		else
			LTP_Edge2_R2C2_Encode <= (others =>'0');
			LTP_Edge2_R2C2_Encode_Bit <= (others =>'0');
-- when cnt_video_hsync > 1280, let redata_cnt be reset
			LTP_Edge2_Cnt <= 0;
		end if;
	end if;
end if;
end process LTP_Edge2_LTP_Calculate;
--############################################### LTP_Edge2 to LTP Calculate ###############################################--

--############################################### LTP_Edge3 to LTP Calculate ###############################################--
LTP_Edge3_LTP_Calculate:process(rst_system, clk_video)
variable LTP_Edge3_R2C2_Encode_Reg_U	: std_logic_vector(9 downto 0);
variable LTP_Edge3_R2C2_Encode_Reg_D	: std_logic_vector(9 downto 0);
begin
if rst_system = '0' then
	LTP_Edge3_R2C2_Encode <= (others =>'0');
	LTP_Edge3_R2C2_Encode_Bit <= (others =>'0');
	LTP_Edge3_R2C2_Encode_Bit2<= (others =>'0');
	LTP_Edge3_Cnt <= 0;
else
	if rising_edge(clk_video) then
		if buf_sobel_cc_en = '1' then
			if Sobel_Cal_en = '1' then
			-- if buf_data_state(0) = '0' then
				LTP_Edge3_R2C2_Encode_Reg_U := LTP_Edge3_R2C2 + R2C2_Encode_Threshold ;
				LTP_Edge3_R2C2_Encode_Reg_D := LTP_Edge3_R2C2 - R2C2_Encode_Threshold ;

				if LTP_Edge3_R1C1 > LTP_Edge3_R2C2_Encode_Reg_U then
					LTP_Edge3_R2C2_Encode_Bit(7) <= '1';
					LTP_Edge3_R2C2_Encode_Bit2(7) <= '0';
				elsif LTP_Edge3_R1C1 < LTP_Edge3_R2C2_Encode_Reg_D then
					LTP_Edge3_R2C2_Encode_Bit(7) <= '0';
					LTP_Edge3_R2C2_Encode_Bit2(7) <= '1';
				else 
					LTP_Edge3_R2C2_Encode_Bit(7) <= '0';
					LTP_Edge3_R2C2_Encode_Bit2(7) <= '0';
				end if;
				if LTP_Edge3_R2C1 > LTP_Edge3_R2C2_Encode_Reg_U then
					LTP_Edge3_R2C2_Encode_Bit(6) <= '1';
					LTP_Edge3_R2C2_Encode_Bit2(6) <= '0';
				elsif LTP_Edge3_R2C1 < LTP_Edge3_R2C2_Encode_Reg_D then
					LTP_Edge3_R2C2_Encode_Bit(6) <= '0';
					LTP_Edge3_R2C2_Encode_Bit2(6) <= '1';
				else 
					LTP_Edge3_R2C2_Encode_Bit(6) <= '0';
					LTP_Edge3_R2C2_Encode_Bit2(6) <= '0';
				end if;
				if LTP_Edge3_R3C1 > LTP_Edge3_R2C2_Encode_Reg_U then
					LTP_Edge3_R2C2_Encode_Bit(5) <= '1';
					LTP_Edge3_R2C2_Encode_Bit2(5) <= '0';
				elsif LTP_Edge3_R3C1 < LTP_Edge3_R2C2_Encode_Reg_D then
					LTP_Edge3_R2C2_Encode_Bit(5) <= '0';
					LTP_Edge3_R2C2_Encode_Bit2(5) <= '1';
				else 
					LTP_Edge3_R2C2_Encode_Bit(5) <= '0';
					LTP_Edge3_R2C2_Encode_Bit2(5) <= '0';
				end if;
				if LTP_Edge3_R3C2 > LTP_Edge3_R2C2_Encode_Reg_U then
					LTP_Edge3_R2C2_Encode_Bit(4) <= '1';
					LTP_Edge3_R2C2_Encode_Bit2(4) <= '0';
				elsif LTP_Edge3_R3C2 < LTP_Edge3_R2C2_Encode_Reg_D then
					LTP_Edge3_R2C2_Encode_Bit(4) <= '0';
					LTP_Edge3_R2C2_Encode_Bit2(4) <= '1';
				else 
					LTP_Edge3_R2C2_Encode_Bit(4) <= '0';
					LTP_Edge3_R2C2_Encode_Bit2(4) <= '0';
				end if;
				if LTP_Edge3_R3C3 > LTP_Edge3_R2C2_Encode_Reg_U then
					LTP_Edge3_R2C2_Encode_Bit(3) <= '1';
					LTP_Edge3_R2C2_Encode_Bit2(3) <= '0';
				elsif LTP_Edge3_R3C3 < LTP_Edge3_R2C2_Encode_Reg_D then
					LTP_Edge3_R2C2_Encode_Bit(3) <= '0';
					LTP_Edge3_R2C2_Encode_Bit2(3) <= '1';
				else 
					LTP_Edge3_R2C2_Encode_Bit(3) <= '0';
					LTP_Edge3_R2C2_Encode_Bit2(3) <= '0';
				end if;
				if LTP_Edge3_R2C3 > LTP_Edge3_R2C2_Encode_Reg_U then
					LTP_Edge3_R2C2_Encode_Bit(2) <= '1';
					LTP_Edge3_R2C2_Encode_Bit2(2) <= '0';
				elsif LTP_Edge3_R2C3 < LTP_Edge3_R2C2_Encode_Reg_D then
					LTP_Edge3_R2C2_Encode_Bit(2) <= '0';
					LTP_Edge3_R2C2_Encode_Bit2(2) <= '1';
				else 
					LTP_Edge3_R2C2_Encode_Bit(2) <= '0';
					LTP_Edge3_R2C2_Encode_Bit2(2) <= '0';
				end if;
				if LTP_Edge3_R1C3 > LTP_Edge3_R2C2_Encode_Reg_U then
					LTP_Edge3_R2C2_Encode_Bit(1) <= '1';
					LTP_Edge3_R2C2_Encode_Bit2(1) <= '0';
				elsif LTP_Edge3_R1C3 < LTP_Edge3_R2C2_Encode_Reg_D then
					LTP_Edge3_R2C2_Encode_Bit(1) <= '0';
					LTP_Edge3_R2C2_Encode_Bit2(1) <= '1';
				else 
					LTP_Edge3_R2C2_Encode_Bit(1) <= '0';
					LTP_Edge3_R2C2_Encode_Bit2(1) <= '0';
				end if;
				if LTP_Edge3_R1C2 > LTP_Edge3_R2C2_Encode_Reg_U then
					LTP_Edge3_R2C2_Encode_Bit(0) <= '1';
					LTP_Edge3_R2C2_Encode_Bit2(0) <= '0';
				elsif LTP_Edge3_R1C2 < LTP_Edge3_R2C2_Encode_Reg_D then
					LTP_Edge3_R2C2_Encode_Bit(0) <= '0';
					LTP_Edge3_R2C2_Encode_Bit2(0) <= '1';
				else 
					LTP_Edge3_R2C2_Encode_Bit(0) <= '0';
					LTP_Edge3_R2C2_Encode_Bit2(0) <= '0';
				end if;

			else
				if ImageSelect = '0' then
					LTP_Edge3_R2C2_Encode <= LTP_Edge3_R2C2_Encode_Bit;
				else
					LTP_Edge3_R2C2_Encode <= LTP_Edge3_R2C2_Encode_Bit2;
				end if;
				
				LTP_Edge3_Value(LTP_Edge3_Cnt) <= LTP_Edge3_R2C2_Encode;
				if LTP_Edge3_Cnt < 639 then
					LTP_Edge3_Cnt <= LTP_Edge3_Cnt + 1;
				else
					LTP_Edge3_Cnt <= 0;
				end if;

			end if;
		else
			LTP_Edge3_R2C2_Encode <= (others =>'0');
			LTP_Edge3_R2C2_Encode_Bit <= (others =>'0');
-- when cnt_video_hsync > 1280, let redata_cnt be reset
			LTP_Edge3_Cnt <= 0;
		end if;
	end if;
end if;
end process LTP_Edge3_LTP_Calculate;
--############################################### LTP_Edge3 to LTP Calculate ###############################################--



--############################################### LBP Buffer Matrix ###############################################--
LoadtoBufferMatrix:process(rst_system, clk_video)
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
end process LoadtoBufferMatrix;
--############################################### LBP Buffer Matrix ###############################################--


--############################################### MySobel Buffer Matrix ###############################################--
MySobelBufferMatrix:process(rst_system, clk_video)
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

				Sobel_Cal_Column_1(Sobel_Cal_Buf_Cnt) <= SB_buf_redata(redata_cnt)(7 downto 0);	-- Data Input
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
end process MySobelBufferMatrix;
--############################################### MySobel Buffer Matrix ###############################################--


--############################################### Sobel_Cal to LTP Calculate ###############################################--
Sobel_LTP_Calculate:process(rst_system, clk_video)
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
end process Sobel_LTP_Calculate;
--############################################### Sobel_Cal to LTP Calculate ###############################################--

-- 註解

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
ThresholdSelect:process(DebugMux)
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
end process ThresholdSelect;
--############################################### DebugMux Matrix ###############################################--
end architecture_LTP_Implement;
