
library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity video_count is
port (
        clk_video  : IN  std_logic;
        rst_system : IN  std_logic;
        cnt_video_en : IN  std_logic;
        cnt_video_hsync : inout  integer range 0 to 1715;
        f0_vga_en : out std_logic
);
end video_count;
architecture architecture_video_count of video_count is

--signal cnt_video_hsync : integer range 0 to 1715:=0;
--signal f0_vga_en : std_logic:='0'; --Field 0

begin

  --video-count------------------------------------------------------------------------------------------------
process(rst_system, clk_video)
begin
if rst_system = '0' then
	cnt_video_hsync <= 0;
	f0_vga_en <= '0';
else
	if rising_edge(clk_video) then
		if cnt_video_en = '1' then
			if cnt_video_hsync = 1715 then
				cnt_video_hsync <= 0;
			else
				cnt_video_hsync <= cnt_video_hsync + 1;
			end if;
			
			if cnt_video_hsync = 857 then
				f0_vga_en <= '1';
			end if;		
		end if;
	end if;
end if;
end process;
--video-count------------------------------------------------------------------------------------------------

end architecture_video_count;
