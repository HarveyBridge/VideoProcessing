
library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity min0514 is
port (
                --clk : in std_logic;
				--avid: in std_logic;
                --fid : in std_logic;
				scl : out std_logic;
				sda : inout std_logic;
			    --intreq: in std_logic;
                --alarm: out std_logic;--buzzer
			   data_video : in std_logic_vector(7 downto 0);
			   clk_video : in std_logic;
			  --Video-port----------------------------------------------------------------------------------------
				--hsync: in std_logic;-- to 
                --vsync: in std_logic;
			  --VGA-port----------------------------------------------------------------------------------------
			    h_sync_vga : out std_logic;
				v_sync_vga : out std_logic;
				r_vga : out  STD_LOGIC_vector(2 downto 0);
				g_vga : out  STD_LOGIC_vector(2 downto 0);
				b_vga : out  STD_LOGIC_vector(2 downto 0);
				
			  --VGA-port----------------------------------------------------------------------------------------
                --ledarray_D : out  STD_LOGIC_vector(7 downto 0);
                --ledarray_U : out  STD_LOGIC_vector(7 downto 0);
               --fpga_to_arduino----------------------------------------------------------------------------------------      
                -- Debug
				DebugOut : out  STD_LOGIC_vector(7 downto 0);
				DebugPulse : inout  STD_LOGIC;
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
end min0514;
architecture architecture_min0514 of min0514 is

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

type SquareArray is ARRAY (integer range 0 to 300) of std_logic_vector(7 downto 0);
signal available_frame	: SquareArray;
signal available_frame_cnt : integer range 0 to 32767:=0;

signal available_frame_en : std_logic;
signal available_frame_value : integer range 0 to 7:=0;
signal available_frame_buf : std_logic_vector(2 downto 0);

signal show_frame_en : std_logic;
signal show_frame_Icnt : integer range 0 to 32767:=0;
--signal buf_vga_CbYCr_state : std_logic:='0';
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

begin



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

--int <= CONV_INTEGER(std_logic(MSB downto LSB));
--VGA-RGB-9bit----------------------------------------------------------------------------------------------------
process(rst_system, clk_video)
begin
if rst_system = '0' then
	r_vga <= "000";
	g_vga <= "000";
	b_vga <= "000";
	buf_vga_Y_out_cnt <= 0;
	show_frame_en <= '0';
	available_frame_value <= 0;
elsif rising_edge(clk_video) then
			-- even  odd
		if (((f_video_en = '0' and black_vga_en = '0') or (f_video_en = '1' and black_vga_en = '1')) and cnt_h_sync_vga > 1 and cnt_h_sync_vga < 640 and cnt_v_sync_vga > 1 and cnt_v_sync_vga < 480)   then
			
			-- 50x100 pixel		
			buf_vga_Y_out_cnt <= buf_vga_Y_out_cnt - 1;	
			------------------------
			if(cnt_v_sync_vga > 1 and cnt_v_sync_vga < 10) then
				if((cnt_h_sync_vga = 50)or(cnt_h_sync_vga = 100)or(cnt_h_sync_vga = 150)or(cnt_h_sync_vga = 200)or(cnt_h_sync_vga = 250)or(cnt_h_sync_vga = 300)or(cnt_h_sync_vga = 350)or(cnt_h_sync_vga = 400)or(cnt_h_sync_vga = 450)or(cnt_h_sync_vga = 500)or(cnt_h_sync_vga = 550)or(cnt_h_sync_vga = 600)) then										
					if(cnt_h_sync_vga = 50)then
						r_vga <= "111";
						g_vga <= "000";
						b_vga <= "000";
					else
						if(cnt_h_sync_vga = 100)then
							r_vga <= "000";
							g_vga <= "111";
							b_vga <= "111";
						else
							if(cnt_h_sync_vga = 150)then
								r_vga <= "111";
								g_vga <= "000";
								b_vga <= "000";
							else
								if(cnt_h_sync_vga = 200)then
									r_vga <= "000";
									g_vga <= "111";
									b_vga <= "111";
								else
									if(cnt_h_sync_vga = 250)then
										r_vga <= "111";
										g_vga <= "000";
										b_vga <= "000";
									else
										if(cnt_h_sync_vga = 300)then
											r_vga <= "000";
											g_vga <= "111";
											b_vga <= "111";
										else
											if(cnt_h_sync_vga = 350)then
												r_vga <= "111";
												g_vga <= "000";
												b_vga <= "000";
											else
												if(cnt_h_sync_vga = 400)then
													r_vga <= "000";
													g_vga <= "111";
													b_vga <= "111";
												else
													if(cnt_h_sync_vga = 450)then
														r_vga <= "111";
														g_vga <= "000";
														b_vga <= "000";
													else
														if(cnt_h_sync_vga = 500)then
															r_vga <= "000";
															g_vga <= "111";
															b_vga <= "111";
														else
															if(cnt_h_sync_vga = 550)then
																r_vga <= "111";
																g_vga <= "000";
																b_vga <= "000";
															else -- 600
																r_vga <= "000";
																g_vga <= "111";
																b_vga <= "111";
															end if;
														end if;	
													end if;	
												end if;
											end if;
										end if;	
									end if;	
								end if;
							end if;
						end if;
					end if;
				else
					r_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
					g_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
					b_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
				end if;				
			else
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
							--int <= CONV_INTEGER(std_logic(MSB downto LSB));
							if available_frame_cnt > 29999 then
								available_frame_cnt <= 0;
								show_frame_en <= '1';
								r_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
								g_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
								b_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);	
							else
								if show_frame_en = '0' then
									available_frame_cnt <= available_frame_cnt + 1;
									available_frame(available_frame_cnt)(7 downto 0) <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 0);
									r_vga <= "000";
									g_vga <= "000";
									b_vga <= "000";
								else
									if available_frame_en = '1' then
										available_frame_cnt <= available_frame_cnt + 1;
										available_frame(available_frame_cnt)(7 downto 0) <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 0);
										r_vga <= "000";
										g_vga <= "000";
										b_vga <= "000";
									else
										r_vga <= "111";
										g_vga <= "000";
										b_vga <= "000";
									end if;
								end if;
							end if;
							
							--available_frame_buf <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);								
							-- r_vga <= "000";
							-- g_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
							-- b_vga <= "000";
							
						end if;
					end if;
				else					
					if((cnt_v_sync_vga > 300 and cnt_v_sync_vga < 480)) then
						-- if((cnt_h_sync_vga > 1 and cnt_h_sync_vga < available_frame_value)and(cnt_v_sync_vga > 300 and (cnt_v_sync_vga < available_frame_cnt)))then
							-- r_vga <= "111";
							-- g_vga <= "000";
							-- b_vga <= "000";
						-- else
							-- r_vga <= "000";
							-- g_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
							-- b_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);	
						-- end if;
						-- if((cnt_h_sync_vga > 1 and cnt_h_sync_vga < 8)and(cnt_v_sync_vga > 300 and (cnt_v_sync_vga < 302)))then
							-- r_vga <= "111";
							-- g_vga <= "000";
							-- b_vga <= "000";
						-- else
							 -- r_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
							 -- g_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
							 -- b_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);	
						-- end if;
						r_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
						g_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
						b_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
					else
						r_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
						g_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
						b_vga <= buf_vga_Y2(buf_vga_Y_out_cnt)(7 downto 5);
					end if;				
				end if;				
			end if;
		else
			r_vga <= "000";
			g_vga <= "000";
			b_vga <= "000";
			buf_vga_Y_out_cnt <= 639;
			--available_frame_cnt <= 300;
			--available_frame_en <= '0';
			--available_frame_value <= 0;
		end if;
--	
end if;
end process;
----VGA-RGB-9bit---------------------------------------------------------------------------------------------------

process(rst_system, clk_video)
begin
	if rst_system = '0' then
		DebugOut <= (others => '0');
		show_frame_Icnt <= 0;
		available_frame_en <= '0';
		DebugPulse <= '0';
	elsif rising_edge(clk_video) then
		if show_frame_en = '1' then
			if show_frame_Icnt > 29999 then
				show_frame_Icnt <= 0;
				available_frame_en <= '1';
				DebugOut <= (others => '0');
				DebugPulse <= not DebugPulse;
			else
				-- if show_frame_Icnt = 150 then
					-- DebugPulse <= not DebugPulse;
				-- else
					-- DebugPulse <= DebugPulse;
				-- end if;	
				DebugPulse <= DebugPulse;
				show_frame_Icnt <= show_frame_Icnt + 1;						
				DebugOut <= available_frame(show_frame_Icnt)(7 downto 0);
			end if;			
		else			
			DebugOut <= (others => '0');
		end if;
	end if;
end process;
end architecture_min0514;
