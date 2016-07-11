library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.MyDataType.all;

entity LTP_Calculate is
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
end LTP_Calculate;

architecture LTP_Calculate_arch of LTP_Calculate is

begin

LTP_Calculate:process(rst_system, clk_video)
variable LTP_R2C2_Encode_Reg_U	: std_logic_vector(9 downto 0);
variable LTP_R2C2_Encode_Reg_D	: std_logic_vector(9 downto 0);
begin
if rst_system = '0' then
	LTP_R2C2_Encode <= (others =>'0');
	LTP_R2C2_Encode_Bit <= (others =>'0');
	LTP_R2C2_Encode_Bit2<= (others =>'0');
	LTP_Cnt <= 0;
else
	if rising_edge(clk_video) then
		if buf_sobel_cc_en = '1' then
			 if buf_data_state(0) = '1' then
				LTP_R2C2_Encode_Reg_U := LTP_R2C2 + R2C2_Encode_Threshold ;
				LTP_R2C2_Encode_Reg_D := LTP_R2C2 - R2C2_Encode_Threshold ;

				if LTP_R1C1 > LTP_R2C2_Encode_Reg_U then
					LTP_R2C2_Encode_Bit(7) <= '1';
					LTP_R2C2_Encode_Bit2(7) <= '0';
				elsif LTP_R1C1 < LTP_R2C2_Encode_Reg_D then
					LTP_R2C2_Encode_Bit(7) <= '0';
					LTP_R2C2_Encode_Bit2(7) <= '1';
				else 
					LTP_R2C2_Encode_Bit(7) <= '0';
					LTP_R2C2_Encode_Bit2(7) <= '0';
				end if;
				if LTP_R2C1 > LTP_R2C2_Encode_Reg_U then
					LTP_R2C2_Encode_Bit(6) <= '1';
					LTP_R2C2_Encode_Bit2(6) <= '0';
				elsif LTP_R2C1 < LTP_R2C2_Encode_Reg_D then
					LTP_R2C2_Encode_Bit(6) <= '0';
					LTP_R2C2_Encode_Bit2(6) <= '1';
				else 
					LTP_R2C2_Encode_Bit(6) <= '0';
					LTP_R2C2_Encode_Bit2(6) <= '0';
				end if;
				if LTP_R3C1 > LTP_R2C2_Encode_Reg_U then
					LTP_R2C2_Encode_Bit(5) <= '1';
					LTP_R2C2_Encode_Bit2(5) <= '0';
				elsif LTP_R3C1 < LTP_R2C2_Encode_Reg_D then
					LTP_R2C2_Encode_Bit(5) <= '0';
					LTP_R2C2_Encode_Bit2(5) <= '1';
				else 
					LTP_R2C2_Encode_Bit(5) <= '0';
					LTP_R2C2_Encode_Bit2(5) <= '0';
				end if;
				if LTP_R3C2 > LTP_R2C2_Encode_Reg_U then
					LTP_R2C2_Encode_Bit(4) <= '1';
					LTP_R2C2_Encode_Bit2(4) <= '0';
				elsif LTP_R3C2 < LTP_R2C2_Encode_Reg_D then
					LTP_R2C2_Encode_Bit(4) <= '0';
					LTP_R2C2_Encode_Bit2(4) <= '1';
				else 
					LTP_R2C2_Encode_Bit(4) <= '0';
					LTP_R2C2_Encode_Bit2(4) <= '0';
				end if;
				if LTP_R3C3 > LTP_R2C2_Encode_Reg_U then
					LTP_R2C2_Encode_Bit(3) <= '1';
					LTP_R2C2_Encode_Bit2(3) <= '0';
				elsif LTP_R3C3 < LTP_R2C2_Encode_Reg_D then
					LTP_R2C2_Encode_Bit(3) <= '0';
					LTP_R2C2_Encode_Bit2(3) <= '1';
				else 
					LTP_R2C2_Encode_Bit(3) <= '0';
					LTP_R2C2_Encode_Bit2(3) <= '0';
				end if;
				if LTP_R2C3 > LTP_R2C2_Encode_Reg_U then
					LTP_R2C2_Encode_Bit(2) <= '1';
					LTP_R2C2_Encode_Bit2(2) <= '0';
				elsif LTP_R2C3 < LTP_R2C2_Encode_Reg_D then
					LTP_R2C2_Encode_Bit(2) <= '0';
					LTP_R2C2_Encode_Bit2(2) <= '1';
				else 
					LTP_R2C2_Encode_Bit(2) <= '0';
					LTP_R2C2_Encode_Bit2(2) <= '0';
				end if;
				if LTP_R1C3 > LTP_R2C2_Encode_Reg_U then
					LTP_R2C2_Encode_Bit(1) <= '1';
					LTP_R2C2_Encode_Bit2(1) <= '0';
				elsif LTP_R1C3 < LTP_R2C2_Encode_Reg_D then
					LTP_R2C2_Encode_Bit(1) <= '0';
					LTP_R2C2_Encode_Bit2(1) <= '1';
				else 
					LTP_R2C2_Encode_Bit(1) <= '0';
					LTP_R2C2_Encode_Bit2(1) <= '0';
				end if;
				if LTP_R1C2 > LTP_R2C2_Encode_Reg_U then
					LTP_R2C2_Encode_Bit(0) <= '1';
					LTP_R2C2_Encode_Bit2(0) <= '0';
				elsif LTP_R1C2 < LTP_R2C2_Encode_Reg_D then
					LTP_R2C2_Encode_Bit(0) <= '0';
					LTP_R2C2_Encode_Bit2(0) <= '1';
				else 
					LTP_R2C2_Encode_Bit(0) <= '0';
					LTP_R2C2_Encode_Bit2(0) <= '0';
				end if;

			else
				if ImageSelect = '0' then
					LTP_R2C2_Encode <= LTP_R2C2_Encode_Bit;
				else
					LTP_R2C2_Encode <= LTP_R2C2_Encode_Bit2;
				end if;
				--if ImageSelect = '0' then
				--	LTP_R2C2_Encode <= LTP_R2C2_Encode_Bit and LTP_R2C2_Encode_Bit2;
				--else
				--	LTP_R2C2_Encode <= LTP_R2C2_Encode_Bit xor LTP_R2C2_Encode_Bit2;					
				--end if;
				LTP_Value(LTP_Cnt) <= LTP_R2C2_Encode;
				if LTP_Cnt < 639 then
					LTP_Cnt <= LTP_Cnt + 1;
				else
					LTP_Cnt <= 0;
				end if;

			end if;
		else
			LTP_R2C2_Encode <= (others =>'0');
			LTP_R2C2_Encode_Bit <= (others =>'0');
-- when cnt_video_hsync > 1280, let redata_cnt be reset
			LTP_Cnt <= 0;
		end if;
	end if;
end if;
end process LTP_Calculate;


end LTP_Calculate_arch;