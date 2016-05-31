
library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity videoin is
port (
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
end videoin;
architecture architecture_videoin of videoin is





component SAV_EAV
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




begin


saveav:  SAV_EAV
	Port map( 
  			    clk_video  => clk_video,
                rst_system => rst_system,
                data_video =>data_video,
                f_video_en =>f_video_en,
                cnt_video_en =>cnt_video_en,
                cnt_vga_en => cnt_vga_en,
                buf_vga_en =>buf_vga_en,
                cnt_video_hsync => cnt_video_hsync,
                f0_vga_en => f0_vga_en
         );



end architecture_videoin;
