----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:33:30 08/02/2016 
-- Design Name: 
-- Module Name:    m_VideoIn - Behavioral 
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

entity m_VideoIn is
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
end m_VideoIn;

architecture m_VideoIn_arch of m_VideoIn is

signal f0_vga_en_std: std_logic:='0';
signal cnt_video_hsync_int : integer range 0 to 1715;	
signal cnt_video_en_std : std_logic:='0';

signal video_state:std_logic_vector(2 downto 0);
signal cnt_vga_en_std	: std_logic:='0';
signal buf_vga_en_std	: std_logic:='0';

signal f_video_en_std	: std_logic:='0';

signal black_vga_en_std	: std_logic:='0';
signal sync_vga_en_std	: std_logic:='0';
signal cnt_h_sync_vga_int : integer range 0 to 857;
signal cnt_v_sync_vga_int : integer range 0 to 524;

signal v_sync_vga_std : std_logic:='0';
signal h_sync_vga_std : std_logic:='0';

begin

cnt_video_hsync <= cnt_video_hsync_int;
f0_vga_en <= f0_vga_en_std;
cnt_video_en <= cnt_video_en_std;

cnt_vga_en <= cnt_vga_en_std;
buf_vga_en <= buf_vga_en_std;
f_video_en <= f_video_en_std;

black_vga_en <= black_vga_en_std;
cnt_h_sync_vga <= cnt_h_sync_vga_int;
cnt_v_sync_vga <= cnt_v_sync_vga_int;
sync_vga_en <= sync_vga_en_std;

v_sync_vga <= v_sync_vga_std;
h_sync_vga <= h_sync_vga_std;

video_count:process(rst_system, clk_video)
begin
if rst_system = '0' then
	cnt_video_hsync_int <= 0;
	f0_vga_en_std <= '0';
else
	if rising_edge(clk_video) then
		if cnt_video_en_std = '1' then
			if cnt_video_hsync_int = 1715 then
				cnt_video_hsync_int <= 0;
			else
				cnt_video_hsync_int <= cnt_video_hsync_int + 1;
			end if;
			
			if cnt_video_hsync_int = 857 then
				f0_vga_en_std <= '1';
			end if;		
		end if;
	end if;
end if;
end process video_count;


VideoDataAlignment:process(clk_video,rst_system)
begin
	if rst_system = '0' then 
		video_state <= "000";	  
		f_video_en_std <= 'Z';
		cnt_video_en_std <= '0';
		cnt_vga_en_std <= '0';
		buf_vga_en_std <= '0';
	elsif rising_edge(clk_video) then
		case video_state is 
			when "000" => 
							if  data_video =x"ff" then 
									video_state <= "001";
							else
									video_state <= "000";
							end if ;
			when "001" => 
							if  data_video =x"00" then 
									video_state <= "010";
							else
									video_state <= "000";
							end if ;
								
			when "010" => 
							if  data_video =x"00" then 
									video_state <= "011";
							else
									video_state <= "000";
							end if ;
			when "011" => 
							if  data_video(5 downto 4)= "11" then 
								video_state <= "100";
							else
								video_state <= "000";
							end if ;
			when "100" => --wait a one peso
							if  data_video =x"ff" then 
									video_state <= "101";
							else
									video_state <= "100";
							end if ;
			when "101" => 
							if  data_video =x"00" then 
									video_state <= "110";
							else
									video_state <= "000";
							end if ;								
			when "110" => 
							if  data_video =x"00" then 
									video_state <= "111";
							else
									video_state <= "000";
							end if ;
			when "111" => 
							if  data_video(6 downto 4)= "100"  then  --even
								cnt_video_en_std <= '1';
								cnt_vga_en_std <= '1';
								buf_vga_en_std <= '1';
								f_video_en_std <= '1';
								video_state <= "000";
							elsif  data_video(6 downto 4)= "000"  then  --odd
								cnt_video_en_std <= '1';
								cnt_vga_en_std <= '1';
								buf_vga_en_std <= '1';									
								f_video_en_std <= '0';									
								video_state <= "000"; 
							else
								video_state <= "100";
							end if ;
			when others => null;
		end case;
	end if ;
end process VideoDataAlignment;

VGA_Sync_Generator:process(rst_system, clk_video)
begin
if rst_system = '0' then
	black_vga_en_std <= '0';
	cnt_h_sync_vga_int <= 0;
	cnt_v_sync_vga_int <= 0;
	sync_vga_en_std <= '0';

else
	if rising_edge(clk_video) then
		if cnt_vga_en_std = '1' then		
			if (f_video_en_std = '1' or (f_video_en_std = '0' and f0_vga_en_std = '1')) then
				sync_vga_en_std <= '1';
				if cnt_h_sync_vga_int = 857 then
					cnt_h_sync_vga_int <= 0;
					if cnt_v_sync_vga_int = 524 then
						cnt_v_sync_vga_int <= 0;
						black_vga_en_std <= '0';
					else
						cnt_v_sync_vga_int <= cnt_v_sync_vga_int + 1;
						black_vga_en_std <= not black_vga_en_std;
					end if;
				else
					cnt_h_sync_vga_int <= cnt_h_sync_vga_int + 1;
				end if;
			end if;
		end if;
	end if;
end if;
end process VGA_Sync_Generator;

VGA_Sync_Controler:process(rst_system, clk_video)
begin
if rst_system = '0' then
	h_sync_vga_std <= '1';
	v_sync_vga_std <= '1';
else
	if rising_edge(clk_video) then
		if (cnt_vga_en_std = '1' and sync_vga_en_std = '1') then
			if (cnt_h_sync_vga_int >= 665 and cnt_h_sync_vga_int < 768)then ----640 -705-808
				h_sync_vga_std <= '1';
			else
				h_sync_vga_std <= '0';
			end if;
			
			if (cnt_v_sync_vga_int >= 494 and cnt_v_sync_vga_int < 497)then --480
				v_sync_vga_std <= '1';
			else
				v_sync_vga_std <= '0';
			end if;
		else
			h_sync_vga_std <= '1';
			v_sync_vga_std <= '1';
		end if;
	end if;
end if;
end process VGA_Sync_Controler;


end m_VideoIn_arch;

