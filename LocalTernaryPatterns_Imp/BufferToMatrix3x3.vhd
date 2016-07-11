library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity BufferToMatrix3x3 is
port(
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
end BufferToMatrix3x3;

architecture BufferToMatrix3x3_arch of BufferToMatrix3x3 is

type Matrix_Buf is array (integer range 0 to 639) of std_logic_vector ((8-1) downto 0);
signal Matrix_Column_1 : Matrix_Buf;
signal Matrix_Column_2 : Matrix_Buf;
signal Matrix_Column_3 : Matrix_Buf;
signal Matrix_Buf_Length_Max : integer range 0 to 639:=639;
begin

LoadtoBufferMatrix:process(rst_system, clk_video)
begin
if rst_system = '0' then
	Matrix_R1C1 <= "0000000000";
	Matrix_R2C1 <= "0000000000";
	Matrix_R3C1 <= "0000000000";
	
	Matrix_R1C2 <= "0000000000";
	Matrix_R2C2 <= "0000000000";
	Matrix_R3C2 <= "0000000000";
	
	Matrix_R1C3 <= "0000000000";
	Matrix_R2C3 <= "0000000000";
	Matrix_R3C3 <= "0000000000";
	Matrix_Buf_Cnt <= 0;

else
	if rising_edge(clk_video) then
		if (buf_vga_en = '1' and cnt_video_hsync < 1280) then
			if buf_data_state(0) = '0' then				
				Matrix_R1C1 <= "00" & Matrix_Column_1(Matrix_Buf_Cnt);
				Matrix_R2C1 <= Matrix_R1C1;
				Matrix_R3C1 <= Matrix_R2C1;
				
				Matrix_R1C2 <= "00" & Matrix_Column_2(Matrix_Buf_Cnt);
				Matrix_R2C2 <= Matrix_R1C2;
				Matrix_R3C2 <= Matrix_R2C2;
				
				Matrix_R1C3 <= "00" & Matrix_Column_3(Matrix_Buf_Cnt);
				Matrix_R2C3 <= Matrix_R1C3;
				Matrix_R3C3 <= Matrix_R2C3;
				
			else	

				Matrix_Column_1(Matrix_Buf_Cnt) <= data_video(7 downto 0);
				Matrix_Column_2(Matrix_Buf_Cnt) <= Matrix_R3C1(7 downto 0);
				Matrix_Column_3(Matrix_Buf_Cnt) <= Matrix_R3C2(7 downto 0);
				
				if Matrix_Buf_Cnt = Matrix_Buf_Length_Max then
					Matrix_Buf_Cnt <= 0;
				else
					Matrix_Buf_Cnt <= Matrix_Buf_Cnt + 1 ;
				end if;				
			end if;
		else
			Matrix_R1C1 <= "0000000000";
			Matrix_R2C1 <= "0000000000";
			Matrix_R3C1 <= "0000000000";
			
			Matrix_R1C2 <= "0000000000";
			Matrix_R2C2 <= "0000000000";
			Matrix_R3C2 <= "0000000000";
			
			Matrix_R1C3 <= "0000000000";
			Matrix_R2C3 <= "0000000000";
			Matrix_R3C3 <= "0000000000";
			Matrix_Buf_Cnt <= 0;
		end if;
	end if;
end if;
end process LoadtoBufferMatrix;
end BufferToMatrix3x3_arch;