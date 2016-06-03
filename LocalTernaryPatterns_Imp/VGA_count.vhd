
library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity VGA_count is
port (
        clk_video  : IN  std_logic;
        rst_system : IN  std_logic;
        f_video_en : IN std_logic;
        f0_vga_en  : IN std_logic;
        cnt_vga_en : IN std_logic;
        black_vga_en :inout  std_logic;
        cnt_h_sync_vga :inout integer range 0 to 857;
        cnt_v_sync_vga :inout integer range 0 to 524;
        sync_vga_en : inout  std_logic;
        h_sync_vga : out  std_logic;
        v_sync_vga : out  std_logic

);
end VGA_count;
architecture architecture_VGA_count of VGA_count is
begin

process(rst_system, clk_video)
begin
if rst_system = '0' then
	black_vga_en <= '0';
	cnt_h_sync_vga <= 0;
	cnt_v_sync_vga <= 0;
	sync_vga_en <= '0';

else
	if rising_edge(clk_video) then
		if cnt_vga_en = '1' then		
			if (f_video_en = '1' or (f_video_en = '0' and f0_vga_en = '1')) then
				sync_vga_en <= '1';
				if cnt_h_sync_vga = 857 then
					cnt_h_sync_vga <= 0;
					if cnt_v_sync_vga = 524 then
						cnt_v_sync_vga <= 0;
						black_vga_en <= '0';
					else
						cnt_v_sync_vga <= cnt_v_sync_vga + 1;
						black_vga_en <= not black_vga_en;
					end if;
				else
					cnt_h_sync_vga <= cnt_h_sync_vga + 1;
				end if;
			end if;
		end if;
	end if;
end if;
end process;
--VGA-Sync---------------------------------------------------------------------------------------------------
process(rst_system, clk_video)
begin
if rst_system = '0' then
	h_sync_vga <= '1';
	v_sync_vga <= '1';
else
	if rising_edge(clk_video) then
		if (cnt_vga_en = '1' and sync_vga_en = '1') then
			if (cnt_h_sync_vga >= 665 and cnt_h_sync_vga < 768)then ----640 -705-808
				h_sync_vga <= '1';
			else
				h_sync_vga <= '0';
			end if;
			
			if (cnt_v_sync_vga >= 494 and cnt_v_sync_vga < 497)then --480
				v_sync_vga <= '1';
			else
				v_sync_vga <= '0';
			end if;
		else
			h_sync_vga <= '1';
			v_sync_vga <= '1';
		end if;
	end if;
end if;
end process;
--VGA-Sync---------------------------------------------------------------------------------------------------


end architecture_VGA_count;
