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
use ieee.math_real.all;
use work.MyDataType.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Lane is
port (
				scl : out std_logic;
				sda : inout std_logic;
			   data_video : in std_logic_vector(7 downto 0);
			   clk_video : in std_logic;
			  --Video-port----------------------------------------------------------------------------------------
			  --VGA-port----------------------------------------------------------------------------------------
			    h_sync_vga : out std_logic;
				v_sync_vga : out std_logic;
				r_vga : out  STD_LOGIC_vector(2 downto 0);
				g_vga : out  STD_LOGIC_vector(2 downto 0);
				b_vga : out  STD_LOGIC_vector(2 downto 0);
				
					DebugMux	:in std_logic_vector(3 downto 0);
					ImageSelect : in std_logic;
				--DebugLEDOut : inout  STD_LOGIC_vector(7 downto 0);
				-- Test Zed pin
				--JB	: out std_logic_vector(3 downto 0);
				--JC	: out std_logic_vector(3 downto 0);
				--JD	: out std_logic_vector(3 downto 0);
				--JE	: out std_logic_vector(7 downto 0);
                --led_text : out std_logic;
                ---
                rst_system : in  STD_LOGIC
);
end Lane;
architecture Lane_arch of Lane is

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


signal boundary_edge_H : integer range 0 to 639:=250; -- 100 to 250
signal boundary_edge_V : integer range 0 to 639:=300; -- 100 to 300

--VGA-8bit-------------------------------------------------------------------------------------------------------

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





--state-------------------------------------------------------------------------------------------------------
signal range_total_cnt : integer range 0 to 1289:=0;
signal range_total_cnt_en : std_logic:='0';
signal buf_Y_temp_en : std_logic:='0';
signal SB_buf_012_en : std_logic:='0';
signal buf_sobel_cc_en : std_logic:='0';
signal buf_sobel_cc_delay : integer range 0 to 3:=0;
signal SBB_buf_en : std_logic:='0';
signal buf_data_state : std_logic_vector(1 downto 0):="00";
--state-------------------------------------------------------------------------------------------------------

---------------------|
--SB = Sobel Buffer--|
---------------------|



signal SB_CRB_data : std_logic:='0';

signal redata_en : std_logic:='0';



----------|
--SB End--|
----------|

signal SB_XSCR : std_logic_vector((10-1) downto 0):="0000000000";
signal SB_YSCR : std_logic_vector((10-1) downto 0):="0000000000";
signal SB_SUM : std_logic_vector((11-1) downto 0):="00000000000";
signal SB_Encode_Threshold : std_logic_vector((12-1) downto 0):="000111111111";
signal SB_buf_redata : Sobel_buf;
signal redata_cnt : integer range 0 to 650:=0;
signal Sobel_Cal_en : std_logic;

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
			Encode_Threshold	: in std_logic_vector((12-1) downto 0);
			redata_cnt : buffer integer range 0 to 650						
			--SB_CRB_data : in std_logic:='0';
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
signal R2C2_Encode_Threshold	: std_logic_vector(7 downto 0):="00001111";

component LTP_Calculate is
	Port(
			clk_video				: in std_logic;
			rst_system				: in std_logic;			
			buf_sobel_cc_en 		: in std_logic;
			buf_vga_en				: in std_logic;	
			ImageSelect				: in std_logic;
			buf_data_state			: in std_logic_vector(1 downto 0);	
			cnt_video_hsync			: in  integer range 0 to 1715;	
			R2C2_Encode_Threshold	: in std_logic_vector(7 downto 0);
			LTP_R1C1  				: in std_logic_vector(10-1 downto 0);
			LTP_R2C1  				: in std_logic_vector(10-1 downto 0);		
			LTP_R3C1  				: in std_logic_vector(10-1 downto 0);
			LTP_R1C2  				: in std_logic_vector(10-1 downto 0);
			LTP_R2C2  				: in std_logic_vector(10-1 downto 0);		
			LTP_R3C2  				: in std_logic_vector(10-1 downto 0);
			LTP_R1C3  				: in std_logic_vector(10-1 downto 0);
			LTP_R2C3  				: in std_logic_vector(10-1 downto 0);		
			LTP_R3C3  				: in std_logic_vector(10-1 downto 0);		
			LTP_Cnt					: buffer integer range 0 to 639:=0;
			LTP_R2C2_Encode 		: buffer std_logic_vector(7 downto 0);
			LTP_R2C2_Encode_Bit 	: buffer std_logic_vector(7 downto 0);
			LTP_R2C2_Encode_Bit2 	: buffer std_logic_vector(7 downto 0);
			LTP_Value				: inout Matrix_Buf
		);
end component;

---------------------|@@@@ | ----------->  H
--Display Parameter--|@@@@ |
---------------------|@@@@ |
------ 640 x 480 ----|@@@@ v
---------------------|@@@@ 
-- Draw Judge Area --|@@@@ V

constant Boundary_Hs : integer := 80;
constant Boundary_He : integer := 600;
constant Boundary_Vs : integer := 240;
constant Boundary_Ve : integer := 430;

-- Width = 50 , Height = 60
constant CaptureFrameLeft_Hs : integer := 85;
constant CaptureFrameLeft_He : integer := 135;
constant CaptureFrameLeft_Vs : integer := 305; --335
constant CaptureFrameLeft_Ve : integer := 365; --365
-- Width = 50 , Height = 60
constant CaptureFrameRight_Hs : integer := 545;
constant CaptureFrameRight_He : integer := 595;
constant CaptureFrameRight_Vs : integer := 295;
constant CaptureFrameRight_Ve : integer := 355;




-- Draw others Object --|
signal Draw_Cnt : integer range 0 to 639:= 10;

--signal Draw_PI : real:= MATH_PI;
--signal Draw_k : real:= 150.0;
--signal Draw_h : real:= 150.0;
--signal Draw_a : real:= 1.0;
--signal Draw_b : real:= 1.0;
--signal Draw_PosX : real:= 0.0;
--signal Draw_PosY : real:= 0.0;

begin

--################################### Component Defination ###################################--
VIDEO_IN2 : video_in
		port map (
				    clk_video  		=> clk_video,
				    rst_system 		=> rst_system,
					data_video 		=> data_video,
				    f_video_en 		=> f_video_en,
				    cnt_video_en 	=> cnt_video_en,
				    cnt_vga_en 		=> cnt_vga_en,
				    buf_vga_en 		=> buf_vga_en,
				    cnt_video_hsync => cnt_video_hsync,
				    f0_vga_en 		=> f0_vga_en,
				    black_vga_en 	=> black_vga_en,
				    cnt_h_sync_vga 	=> cnt_h_sync_vga,
				    cnt_v_sync_vga 	=> cnt_v_sync_vga,
				    sync_vga_en 	=> sync_vga_en,
				    v_sync_vga 		=> v_sync_vga,
				    h_sync_vga 		=> h_sync_vga
                
			);

buf_vga_Y(buf_vga_Y_in_cnt)<= buf_vga_Y_buf ;

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


Sobel_Cal_Functions: Sobel_Calculate
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
		Encode_Threshold=> SB_Encode_Threshold,
		redata_cnt 		=> redata_cnt
		);

--LTP_Edge_BTM3x3 : BufferToMatrix3x3
--	port map (
--		clk_video 		=> clk_video,
--		rst_system 		=> rst_system,		
--		buf_vga_en 		=> buf_vga_en,
--		buf_data_state 	=> buf_data_state,
--		cnt_video_hsync => cnt_video_hsync,

--		data_video 		=> SB_buf_redata(redata_cnt)(7 downto 0),
--		Matrix_R1C1 	=> LTP_Edge_R1C1,
--		Matrix_R2C1 	=> LTP_Edge_R2C1,
--		Matrix_R3C1 	=> LTP_Edge_R3C1,
--		Matrix_R1C2 	=> LTP_Edge_R1C2,
--		Matrix_R2C2 	=> LTP_Edge_R2C2,
--		Matrix_R3C2 	=> LTP_Edge_R3C2,
--		Matrix_R1C3 	=> LTP_Edge_R1C3,
--		Matrix_R2C3 	=> LTP_Edge_R2C3,
--		Matrix_R3C3 	=> LTP_Edge_R3C3,
--		Matrix_Buf_Cnt 	=> LTP_Edge_Buf_Cnt
--		);

--LTP_Edge_LTP_Cal : LTP_Calculate
--	port map(
--		clk_video 				=> clk_video,
--		rst_system 				=> rst_system,		
--		buf_sobel_cc_en 		=> buf_sobel_cc_en,
--		buf_vga_en 				=> buf_vga_en,
--		buf_data_state 			=> buf_data_state,
--		cnt_video_hsync 		=> cnt_video_hsync,
--		R2C2_Encode_Threshold 	=> R2C2_Encode_Threshold,
--		ImageSelect				=> ImageSelect,
--		LTP_R1C1 				=> LTP_Edge_R1C1,
--		LTP_R2C1 				=> LTP_Edge_R2C1,
--		LTP_R3C1 				=> LTP_Edge_R3C1,
--		LTP_R1C2 				=> LTP_Edge_R1C2,
--		LTP_R2C2 				=> LTP_Edge_R2C2,
--		LTP_R3C2 				=> LTP_Edge_R3C2,
--		LTP_R1C3 				=> LTP_Edge_R1C3,
--		LTP_R2C3 				=> LTP_Edge_R2C3,
--		LTP_R3C3 				=> LTP_Edge_R3C3,		
--		LTP_Cnt 				=> LTP_Edge_Cnt,
--		LTP_R2C2_Encode 		=> LTP_Edge_R2C2_Encode,
--		LTP_R2C2_Encode_Bit   	=> LTP_Edge_R2C2_Encode_Bit,
--		LTP_R2C2_Encode_Bit2  	=> LTP_Edge_R2C2_Encode_Bit2,
--		LTP_Value  				=> LTP_Edge_Value
--		);
--################################### Component Defination ###################################--



--int <= CONV_INTEGER(std_logic(MSB downto LSB));
--VGA-RGB-9bit----------------------------------------------------------------------------------------------------
process(rst_system, clk_video)


begin
if rst_system = '0' then
	r_vga <= "000";
	g_vga <= "000";
	b_vga <= "000";
	buf_vga_Y_out_cnt <= 0;
	-- show_frame_en <= '0';
	-- available_frame_value <= 0;
	Draw_Cnt <= 10;
elsif rising_edge(clk_video) then
			-- even  odd
		-- if (((f_video_en = '0' and black_vga_en = '0') or (f_video_en = '1' and black_vga_en = '1')) and cnt_h_sync_vga > 1 and cnt_h_sync_vga < 640 and cnt_v_sync_vga > 1 and cnt_v_sync_vga < 480)   then			

				
			-- r_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
			-- g_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
			-- b_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);

--############################################### Note ###############################################--	
		    --cnt_h_sync_vga :out integer range 0 to 857;
            --cnt_v_sync_vga :out integer range 0 to 524;
            --constant Boundary_Vs : integer := 240;
            --constant Boundary_Ve : integer := 430;
            --constant Boundary_Hs : integer := 80;
            --constant Boundary_He : integer := 600;

            -- Width = 50 , Height = 60
            --constant CaptureFrameLeft_Hs : integer := 85;
            --constant CaptureFrameLeft_He : integer := 135;
            --constant CaptureFrameLeft_Vs : integer := 305; --335
            --constant CaptureFrameLeft_Ve : integer := 365; --365
            ---- Width = 50 , Height = 30
            --constant CaptureFrameRight_Hs : integer := 545;
            --constant CaptureFrameRight_He : integer := 595;
            --constant CaptureFrameRight_Vs : integer := 395;
            --constant CaptureFrameRight_Ve : integer := 425;
--############################################### Note ###############################################--		
			-- -- ((f_video_en = '0' and black_vga_en = '0') or (f_video_en = '1' and black_vga_en = '1'))
		--if ( cnt_h_sync_vga > 1 and cnt_h_sync_vga < 640 and cnt_v_sync_vga > 1 and cnt_v_sync_vga < 480)   then	
		if ( cnt_v_sync_vga > 1 and cnt_v_sync_vga < 480)   then	
			if ( cnt_h_sync_vga > 1 and cnt_h_sync_vga < 641 )   then			
				if ( cnt_h_sync_vga > 1 and cnt_h_sync_vga < 640 )   then			
					buf_vga_Y_out_cnt <= buf_vga_Y_out_cnt + 1;		
					if( (cnt_h_sync_vga > Draw_Cnt and cnt_h_sync_vga < (Draw_Cnt+3)) ) then -- draw m Line
						r_vga <= "111";
						g_vga <= "111";
						b_vga <= "000";
					else -- below big frame
						if( (cnt_h_sync_vga > Boundary_Hs and cnt_h_sync_vga < Boundary_He)and(cnt_v_sync_vga > Boundary_Vs and cnt_v_sync_vga < Boundary_Ve) )then
							if( (cnt_v_sync_vga > Boundary_Vs and cnt_v_sync_vga < (Boundary_Vs+2))or ((cnt_v_sync_vga > (Boundary_Ve-2)) and cnt_v_sync_vga < Boundary_Ve) )then
								r_vga <= "111";
								g_vga <= "000";
								b_vga <= "000";
							else					
								if( (cnt_h_sync_vga > Boundary_Hs and cnt_h_sync_vga < (Boundary_Hs+2)) or  (cnt_h_sync_vga>(Boundary_He-2)  and cnt_h_sync_vga < Boundary_He) )then					
									r_vga <= "000";
									g_vga <= "111";							
									b_vga <= "000";
								else -- small frame ==> Left Frame
									if( ( (cnt_h_sync_vga > CaptureFrameLeft_Hs and cnt_h_sync_vga < CaptureFrameLeft_He)   and
										  (cnt_v_sync_vga > CaptureFrameLeft_Vs and cnt_v_sync_vga < CaptureFrameLeft_Ve) ) or 
										( (cnt_h_sync_vga > CaptureFrameRight_Hs and cnt_h_sync_vga < CaptureFrameRight_He) and
										  (cnt_v_sync_vga > CaptureFrameRight_Vs and cnt_v_sync_vga < CaptureFrameRight_Ve)))then										
										if( ((cnt_v_sync_vga > CaptureFrameLeft_Vs)and(cnt_v_sync_vga < (CaptureFrameLeft_Vs+2)))or 
											((cnt_v_sync_vga > (CaptureFrameLeft_Ve-2))and(cnt_v_sync_vga < CaptureFrameLeft_Ve))or
											((cnt_v_sync_vga > CaptureFrameRight_Vs)and(cnt_v_sync_vga < (CaptureFrameRight_Vs+2)))or 
											((cnt_v_sync_vga > (CaptureFrameRight_Ve-2))and(cnt_v_sync_vga < CaptureFrameRight_Ve)))then
											r_vga <= "111";
											g_vga <= "111";
											b_vga <= "000";
										else
											if( ((cnt_h_sync_vga > CaptureFrameLeft_Hs)and(cnt_h_sync_vga < (CaptureFrameLeft_Hs+2)))or 
												((cnt_h_sync_vga > (CaptureFrameLeft_He-2))and(cnt_h_sync_vga < CaptureFrameLeft_He))or
												((cnt_h_sync_vga > CaptureFrameRight_Hs)and(cnt_h_sync_vga < (CaptureFrameRight_Hs+2)))or 
												((cnt_h_sync_vga > (CaptureFrameRight_He-2))and(cnt_h_sync_vga < CaptureFrameRight_He)))then
												r_vga <= "111";
												g_vga <= "000";
												b_vga <= "111";
											else -- else area ==> Left Frame Data
												-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ Inner Special Range 150x200 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ --
												--r_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
												--g_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
												--b_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
												--r_vga <= LTP_Edge2_Value(buf_vga_Y_out_cnt)(7 downto 5);
												--g_vga <= LTP_Edge2_Value(buf_vga_Y_out_cnt)(7 downto 5);
												--b_vga <= LTP_Edge2_Value(buf_vga_Y_out_cnt)(7 downto 5);
												r_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);
												g_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);
												b_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);	
												-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ Inner Special Range 150x200 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ --		
											end if;											
										end if;
									else
										r_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);
										g_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);
										b_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);	
									end if;		
									-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
									---- below small frame ==> Right Frame
									--if( (cnt_h_sync_vga > CaptureFrameRight_Hs and cnt_h_sync_vga < CaptureFrameRight_He)and(cnt_v_sync_vga > CaptureFrameRight_Vs and cnt_v_sync_vga < CaptureFrameRight_Ve) )then
									--	if( ((cnt_v_sync_vga > CaptureFrameRight_Vs)and(cnt_v_sync_vga < (CaptureFrameRight_Vs+2))) or ((cnt_v_sync_vga > (CaptureFrameRight_Ve-2))and(cnt_v_sync_vga < CaptureFrameRight_Ve)) ) then
									--		r_vga <= "000";
									--		g_vga <= "111";
									--		b_vga <= "111";
									--	else
									--		if( ((cnt_h_sync_vga > CaptureFrameRight_Hs)and(cnt_h_sync_vga < (CaptureFrameRight_Hs+2))) or ((cnt_h_sync_vga > (CaptureFrameRight_He-2))and(cnt_h_sync_vga < CaptureFrameRight_He)) ) then
									--			r_vga <= "111";
									--			g_vga <= "111";
									--			b_vga <= "000";
									--		else										
									--			-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ Inner Special Range 150x200 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ --
									--			--r_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
									--			--g_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
									--			--b_vga <= LTP_Value(buf_vga_Y_out_cnt)(7 downto 5);
									--			--r_vga <= LTP_Edge2_Value(buf_vga_Y_out_cnt)(7 downto 5);
									--			--g_vga <= LTP_Edge2_Value(buf_vga_Y_out_cnt)(7 downto 5);
									--			--b_vga <= LTP_Edge2_Value(buf_vga_Y_out_cnt)(7 downto 5);
									--			r_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);
									--			g_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);
									--			b_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);	
									--			-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ Inner Special Range 150x200 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ --
									--		end if;
									--	end if;
									--else
									--	r_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);
									--	g_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);
									--	b_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);	
									--end if;							
								end if;
							end if;
						else
							r_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);
							g_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);
							b_vga <= SB_buf_redata(buf_vga_Y_out_cnt)(7 downto 5);
						end if;
					end if;								
				else			
					r_vga <= "000";
					g_vga <= "000";
					b_vga <= "000";
					buf_vga_Y_out_cnt <= 0;
					if(Draw_Cnt = 639)then
						Draw_Cnt <= 10;
					else
						Draw_Cnt <= Draw_Cnt + 1;
					end if;
				end if;
			else
				r_vga <= "000";
				g_vga <= "000";
				b_vga <= "000";
				buf_vga_Y_out_cnt <= 0;
			end if;				
		else
			r_vga <= "000";
			g_vga <= "000";
			b_vga <= "000";
			buf_vga_Y_out_cnt <= 0;
			Draw_Cnt <= 10;
		end if;
--	
end if;
end process;
----VGA-RGB-9bit---------------------------------------------------------------------------------------------------
----
--Buf-state---------------------------------------------------------------------------------------------------
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
else
	if rising_edge(clk_video) then
		-- if (buf_vga_en = '1' and f_video_en = '0' and cnt_video_hsync < 1290) then
		if (buf_vga_en = '1' and cnt_video_hsync < 1290) then
			if buf_data_state = "11" then
				buf_data_state <= "00";
			else
				buf_data_state <= buf_data_state + '1';
			end if;
			
			if (cnt_video_hsync >= 0 and cnt_video_hsync < 1290 and cnt_v_sync_vga >= 0 and cnt_v_sync_vga < 480) then
				if range_total_cnt_en = '0' then
					if buf_data_state = "11" then
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
		end if;
	end if;
end if;
end process;
--Buf-state---------------------------------------------------------------------------------------------------
ThresholdSelect:process(DebugMux)
begin
	case DebugMux is --"0001 1111 1111"
		when "0000"	=> SB_Encode_Threshold <= x"1FF";
		when "0001"	=> SB_Encode_Threshold <= x"2FF";
		when "0010"	=> SB_Encode_Threshold <= x"3FF";
		when "0011"	=> SB_Encode_Threshold <= x"4FF";
		when "0100"	=> SB_Encode_Threshold <= x"0FF";
		when "0101"	=> SB_Encode_Threshold <= x"07F";
		when "0110"	=> SB_Encode_Threshold <= x"03F";
		when "0111"	=> SB_Encode_Threshold <= x"01F";
		when "1000"	=> SB_Encode_Threshold <= x"00F";
		when "1001"	=> SB_Encode_Threshold <= x"007";
		when "1010"	=> SB_Encode_Threshold <= x"003";
		when "1011"	=> SB_Encode_Threshold <= x"001";
		when "1100"	=> SB_Encode_Threshold <= x"1AF";
		when "1101"	=> SB_Encode_Threshold <= x"1BF";
		when "1110"	=> SB_Encode_Threshold <= x"1CF";		
		when "1111"	=> SB_Encode_Threshold <= x"1DF";	
		when others	=> SB_Encode_Threshold <= x"1EF";
	end case;
end process ThresholdSelect;

end Lane_arch;

