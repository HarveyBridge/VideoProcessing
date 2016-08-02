
library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity SAV_EAV is
port (
    clk_video  : IN  std_logic;
    rst_system : IN  std_logic;
	data_video : IN  std_logic_vector(7 downto 0)  ;
    f_video_en : OUT std_logic;
    cnt_video_en : inOUT std_logic;
    cnt_vga_en : OUT std_logic ;
    buf_vga_en : OUT std_logic ;
    cnt_video_hsync : inout  integer range 0 to 1715;
    f0_vga_en : out std_logic

);
end SAV_EAV;
architecture architecture_SAV_EAV of SAV_EAV is


--inin video start --
signal video_state:std_logic_vector(2 downto 0);
--inin video start --

signal cnt_video_en_t:std_logic;

component video_count
	Port ( 
  			    clk_video  : IN  std_logic;
                rst_system : IN  std_logic;
                cnt_video_en : INout  std_logic;
                cnt_video_hsync : inout  integer range 0 to 1715;
                f0_vga_en : out std_logic
         );

end component;
begin
cnt_video_en_t <= cnt_video_en;
video_count_1 :video_count
		port map (
                rst_system => rst_system,
                clk_video => clk_video,
                cnt_video_en => cnt_video_en_t,
                cnt_video_hsync => cnt_video_hsync,
                f0_vga_en => f0_vga_en
			);

first_point : process(clk_video,rst_system)
begin
	if rst_system = '0' then 
	  video_state <= "000";	  

		f_video_en <= 'Z';
		cnt_video_en <= '0';
		cnt_vga_en <= '0';
		buf_vga_en <= '0';
	
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
									cnt_video_en <= '1';
									cnt_vga_en <= '1';
									buf_vga_en <= '1';
									f_video_en <= '1';

									video_state <= "000";
								elsif  data_video(6 downto 4)= "000"  then  --odd
									cnt_video_en <= '1';
									cnt_vga_en <= '1';
									buf_vga_en <= '1';
									
									f_video_en <= '0';
									
									video_state <= "000"; 
								else
									video_state <= "100";
								end if ;
			when others => null;
		end case;
	end if ;
end process;
----inin video start--

end architecture_SAV_EAV;
