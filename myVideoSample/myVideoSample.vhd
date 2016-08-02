----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:11:20 08/02/2016 
-- Design Name: 
-- Module Name:    myVideoSample - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity myVideoSample is
	port(
			scl 		: out std_logic;
			sda 		: inout std_logic;
			data_video 	: in std_logic_vector(7 downto 0);
			clk_video 	: in std_logic;
			--Video-port----------------------------------------------------------------------------------------
			-- ## VGA-port ## 
			h_sync_vga 	: out std_logic;
			v_sync_vga 	: out std_logic;
			r_vga 		: out  std_logic_vector(2 downto 0);
			g_vga 		: out  std_logic_vector(2 downto 0);
			b_vga 		: out  std_logic_vector(2 downto 0);

			rst_system 	: in  std_logic
		);
end myVideoSample;

architecture myVideoSample_arch of myVideoSample is
signal f_video_en 		: std_logic:='Z'; --Field
signal cnt_video_en 	: std_logic:='0';
signal cnt_vga_en 		: std_logic:='0';
signal buf_vga_en 		: std_logic:='0';
signal cnt_video_hsync 	: integer range 0 to 1715:=0;
signal f0_vga_en 		: std_logic:='0'; --Field 0
signal black_vga_en 	: std_logic:='0';
signal cnt_h_sync_vga 	: integer range 0 to 857:=0;
signal cnt_v_sync_vga 	: integer range 0 to 524:=0;
signal sync_vga_en 		: std_logic:='0';

component m_VideoIn 
port(
	    clk_video  		: in  std_logic;
	    rst_system 		: in  std_logic;
		data_video 		: in  std_logic_vector(7 downto 0)  ;
	    f_video_en 		: inout std_logic;		    
	    cnt_vga_en 		: inout std_logic;
	    f0_vga_en 		: inout std_logic;		    
		cnt_video_en 	: out std_logic;
	    buf_vga_en 		: out std_logic ;
	    cnt_video_hsync : out  integer range 0 to 1715;		  
	    black_vga_en 	: out  std_logic;
	    cnt_h_sync_vga 	: out integer range 0 to 857;
	    cnt_v_sync_vga 	: out integer range 0 to 524;
	    sync_vga_en 	: out  std_logic;
	    v_sync_vga 		: out  std_logic;
	    h_sync_vga 		: out  std_logic
	);
end component;

component i2c
port( 
		clk_video  	: in  std_logic;
        rst_system 	: in  std_logic;
        scl 		: out std_logic;
        sda 		: inout std_logic
    );
end component;

--VGA buf-------------------------------------------------------------------------------------------------------
type Array_Y is ARRAY (integer range 0 to 639) of std_logic_vector(7 downto 0);
signal buf_vga_Y : Array_Y;
signal buf_vga_Y2 : Array_Y;
signal buf_vga_Y_buf : std_logic_vector(7 downto 0);
signal buf_vga_Y_in_cnt : integer range 0 to 639:=0;
signal buf_vga_Y_in_cnt2 : integer range 0 to 639:=0;
signal buf_vga_Y_out_cnt : integer range 0 to 639:=639;
signal buf_vga_state : std_logic_vector(1 downto 0):="00";
--state-------------------------------------------------------------------------------------------------------
signal range_total_cnt : integer range 0 to 1289:=0;
signal range_total_cnt_en : std_logic:='0';
signal buf_Y_temp_en : std_logic:='0';
signal SB_buf_012_en : std_logic:='0';
signal buf_sobel_cc_en : std_logic:='0';
signal buf_sobel_cc_delay : integer range 0 to 3:=0;
signal SBB_buf_en : std_logic:='0';
signal buf_data_state : std_logic_vector(1 downto 0):="00";
--VGA Boundary of Square-------------------------------------------------------------------------------------------------------
constant Boundary_Hs : integer := 80;
constant Boundary_He : integer := 600;
constant Boundary_Vs : integer := 240;
constant Boundary_Ve : integer := 430;
-- Width = 50 , Height = 60
constant CaptureFrameLeft_Hs : integer := 80; --85
constant CaptureFrameLeft_He : integer := 135;
constant CaptureFrameLeft_Vs : integer := 305; --335
constant CaptureFrameLeft_Ve : integer := 355; --365
-- Width = 50 , Height = 60
constant CaptureFrameRight_Hs : integer := 545;
constant CaptureFrameRight_He : integer := 600; --595
constant CaptureFrameRight_Vs : integer := 305;
constant CaptureFrameRight_Ve : integer := 355;
signal Draw_Cnt : integer range 0 to 255:= 0;
begin
buf_vga_Y(buf_vga_Y_in_cnt)<= buf_vga_Y_buf ;

myVideoIn : m_VideoIn
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

i2c_1:i2c
port map (
            rst_system => rst_system,
            clk_video => clk_video,
            scl => scl,
            sda => sda           
);

--####### Buffer #######--
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

--####### VGA Buffer #######--
process(rst_system, clk_video, buf_vga_en, cnt_video_hsync)
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

process(rst_system, clk_video)
begin
if rst_system = '0' then
	r_vga <= "000";
	g_vga <= "000";
	b_vga <= "000";
	buf_vga_Y_out_cnt <= 0;
elsif rising_edge(clk_video) then
			-- even  odd
		-- if (((f_video_en = '0' and black_vga_en = '0') or (f_video_en = '1' and black_vga_en = '1')) and cnt_h_sync_vga > 1 and cnt_h_sync_vga < 640 and cnt_v_sync_vga > 1 and cnt_v_sync_vga < 480)   then			

				
			-- r_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
			-- g_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
			-- b_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);

--############################################### Note ###############################################--	
		    --cnt_h_sync_vga :out integer range 0 to 857;
            --cnt_v_sync_vga :out integer range 0 to 524;
            --constant Boundary_Hs : integer := 80;
            --constant Boundary_He : integer := 600;
            --constant Boundary_Vs : integer := 240;
            --constant Boundary_Ve : integer := 430;

            ---- Width = 50 , Height = 60
            --constant CaptureFrameLeft_Hs : integer := 80; --85
            --constant CaptureFrameLeft_He : integer := 135;
            --constant CaptureFrameLeft_Vs : integer := 305; --335
            --constant CaptureFrameLeft_Ve : integer := 355; --365
            ---- Width = 50 , Height = 60
            --constant CaptureFrameRight_Hs : integer := 545;
            --constant CaptureFrameRight_He : integer := 600; --595
            --constant CaptureFrameRight_Vs : integer := 305;
            --constant CaptureFrameRight_Ve : integer := 355;
            
--############################################### Note ###############################################--		
		if ( cnt_v_sync_vga > 1 and cnt_v_sync_vga < 480)   then	
			if ( cnt_h_sync_vga > 1 and cnt_h_sync_vga < 641 )   then			
				if ( cnt_h_sync_vga > 1 and cnt_h_sync_vga < 640 )   then			
					buf_vga_Y_out_cnt <= buf_vga_Y_out_cnt + 1;		
					--if( (cnt_h_sync_vga > Draw_Cnt and cnt_h_sync_vga < (Draw_Cnt+10)) ) then -- draw m Line
					if( cnt_h_sync_vga = Draw_Cnt ) then -- draw m Line
						r_vga <= "111";
						g_vga <= "111";
						b_vga <= "000";
					else -- below big frame
						if( (cnt_h_sync_vga > Boundary_Hs and cnt_h_sync_vga < Boundary_He)and(cnt_v_sync_vga > Boundary_Vs and cnt_v_sync_vga < Boundary_Ve) )then
							if( (cnt_v_sync_vga > Boundary_Vs and cnt_v_sync_vga < (Boundary_Vs+2))or ((cnt_v_sync_vga > (Boundary_Ve-2)) and cnt_v_sync_vga < Boundary_Ve) )then
								r_vga <= "111";		-- Draw Horizon Line
								g_vga <= "000";
								b_vga <= "000";
							else					
								if( (cnt_h_sync_vga > Boundary_Hs and cnt_h_sync_vga < (Boundary_Hs+2)) or  (cnt_h_sync_vga>(Boundary_He-2)  and cnt_h_sync_vga < Boundary_He) )then					
									r_vga <= "000";	-- Draw Vertical Line
									g_vga <= "111";							
									b_vga <= "000";
								else -- small frame ==> Left Frame
									if( ( (cnt_h_sync_vga > CaptureFrameLeft_Hs and cnt_h_sync_vga < CaptureFrameLeft_He)   and
										  (cnt_v_sync_vga > CaptureFrameLeft_Vs and cnt_v_sync_vga < CaptureFrameLeft_Ve) ) or 
										( (cnt_h_sync_vga > CaptureFrameRight_Hs and cnt_h_sync_vga < CaptureFrameRight_He) and
										  (cnt_v_sync_vga > CaptureFrameRight_Vs and cnt_v_sync_vga < CaptureFrameRight_Ve)))then										
										if( ( ((cnt_v_sync_vga > CaptureFrameLeft_Vs)and(cnt_v_sync_vga < (CaptureFrameLeft_Vs+2)))		 or 
											  ((cnt_v_sync_vga > (CaptureFrameLeft_Ve-2))and(cnt_v_sync_vga < CaptureFrameLeft_Ve)) ) 	 or
											( ((cnt_v_sync_vga > CaptureFrameRight_Vs)and(cnt_v_sync_vga < (CaptureFrameRight_Vs+2)))	 or 
											  ((cnt_v_sync_vga > (CaptureFrameRight_Ve-2))and(cnt_v_sync_vga < CaptureFrameRight_Ve)) ) )then
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
												--TxD_Buffer <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 0);
												r_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
												g_vga <= "111";
												b_vga <= "111";
												-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ Inner Special Range 150x200 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ --		
											end if;											
										end if;
									else
										r_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
										g_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
										b_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
									end if;																	
								end if;
							end if;
						else
							r_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
							g_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
							b_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
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
			end if;				
		else
			r_vga <= "000";
			g_vga <= "000";
			b_vga <= "000";
			buf_vga_Y_out_cnt <= 0;
		end if;
end if;
end process;

end myVideoSample_arch;

