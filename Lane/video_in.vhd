
library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity video_in is
port (
    clk_video  : IN  std_logic;
    rst_system : IN  std_logic;
	data_video : IN  std_logic_vector(7 downto 0)  ;
    f_video_en : inOUT std_logic;
    cnt_video_en : OUT std_logic;
    cnt_vga_en : inOUT std_logic ;
    buf_vga_en : OUT std_logic ;
    cnt_video_hsync : out  integer range 0 to 1715;
    f0_vga_en : inout std_logic;
    black_vga_en :out  std_logic;
    cnt_h_sync_vga :out integer range 0 to 857;
    cnt_v_sync_vga :out integer range 0 to 524;
    sync_vga_en : out  std_logic;
    v_sync_vga : out  std_logic;
    h_sync_vga : out  std_logic
);
end video_in;
architecture architecture_video_in of video_in is


component videoin
	Port ( 
  			    clk_video  : IN  std_logic;
                rst_system : IN  std_logic;
                data_video : IN  std_logic_vector(7 downto 0)  ;
                f_video_en : OUT std_logic;
                cnt_video_en : OUT std_logic;
                cnt_vga_en : OUT std_logic ;
                buf_vga_en : OUT std_logic ;
                cnt_video_hsync : out  integer range 0 to 1715;
                f0_vga_en : out std_logic
 
         );

end component;




component VGA_count
	Port ( 
  			    clk_video  : IN  std_logic;
                rst_system : IN  std_logic;
                f_video_en : IN std_logic;
                f0_vga_en  : IN std_logic;
                cnt_vga_en : IN std_logic;
                black_vga_en :out  std_logic;
                cnt_h_sync_vga :out integer range 0 to 857;
                cnt_v_sync_vga :out integer range 0 to 524;
                sync_vga_en : out  std_logic;
                h_sync_vga : out  std_logic;
                v_sync_vga : out  std_logic
         );

end component;




signal f_video_en_t : std_logic:='0'; --Field 0
signal f0_vga_en_t : std_logic:='0'; --Field 0
signal cnt_vga_en_t : std_logic:='0'; --Field 0
begin
f_video_en_t <=f_video_en;
f0_vga_en_t  <=f0_vga_en ;
cnt_vga_en_t <=cnt_vga_en;

video_in_1 :videoin
		port map (
                clk_video  =>clk_video ,
                rst_system =>rst_system ,
                data_video =>data_video ,
                f_video_en =>f_video_en ,
                cnt_video_en =>cnt_video_en ,
                cnt_vga_en =>cnt_vga_en ,
                buf_vga_en =>buf_vga_en ,
                cnt_video_hsync =>cnt_video_hsync ,
                f0_vga_en =>f0_vga_en

			);



vgacount: VGA_count
	Port map( 
        clk_video  =>clk_video ,
        rst_system =>rst_system,
        f_video_en =>f_video_en_t,
        f0_vga_en =>f0_vga_en_t,
        cnt_vga_en =>cnt_vga_en_t,
        black_vga_en =>black_vga_en,
        cnt_h_sync_vga =>cnt_h_sync_vga,
        cnt_v_sync_vga =>cnt_v_sync_vga,
        sync_vga_en =>sync_vga_en,
        h_sync_vga =>h_sync_vga,
        v_sync_vga =>v_sync_vga
               
         );

end architecture_video_in;
