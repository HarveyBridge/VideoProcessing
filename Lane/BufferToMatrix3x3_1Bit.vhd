library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity BufferToMatrix3x3_1Bit is
port(
	clk_video	: in std_logic;
	rst_system	: in std_logic;
	data_video 	: in std_logic;
	buf_vga_en	: in std_logic;	
	buf_data_state: in std_logic_vector(1 downto 0);
	Sobel_Cal_en : in std_logic;
	cnt_video_hsync : in  integer range 0 to 1715;
	Matrix_R1C1	: buffer std_logic;
	Matrix_R2C1	: buffer std_logic;
	Matrix_R3C1	: buffer std_logic;
	Matrix_R1C2	: buffer std_logic;
	Matrix_R2C2	: buffer std_logic;
	Matrix_R3C2	: buffer std_logic;
	Matrix_R1C3	: buffer std_logic;
	Matrix_R2C3	: buffer std_logic;
	Matrix_R3C3	: buffer std_logic;
	Matrix_Buf_Cnt	 : buffer integer range 0 to 639:=0
	);
end BufferToMatrix3x3_1Bit;

architecture BufferToMatrix3x3_1Bit_arch of BufferToMatrix3x3_1Bit is

type Matrix_Buf is array (integer range 0 to 639) of std_logic;
signal Matrix_Column_1 : Matrix_Buf;
signal Matrix_Column_2 : Matrix_Buf;
signal Matrix_Column_3 : Matrix_Buf;
signal Matrix_Buf_Length_Max : integer range 0 to 639:=639;
begin

--############################################### Matrix Expression ###############################################--
--			 Col-1   Col-2  Col-3
--			[ R1C1 , R1C2 , R1C3 ]
--Matrix =	[ R2C1 , R2C2 , R2C3 ]
--			[ R3C1 , R3C2 , R3C3 ]
--############################################### Matrix Expression ###############################################--

LoadtoBufferMatrix:process(rst_system, clk_video)
begin
if rst_system = '0' then
	Matrix_R1C1 <= '0';
	Matrix_R2C1 <= '0';
	Matrix_R3C1 <= '0';
	
	Matrix_R1C2 <= '0';
	Matrix_R2C2 <= '0';
	Matrix_R3C2 <= '0';
	
	Matrix_R1C3 <= '0';
	Matrix_R2C3 <= '0';
	Matrix_R3C3 <= '0';
	Matrix_Buf_Cnt <= 0;

else
	if rising_edge(clk_video) then
		if (buf_vga_en = '1' and cnt_video_hsync < 1280) then
			if Sobel_Cal_en = '0' then				
				Matrix_R1C1 <= Matrix_Column_1(Matrix_Buf_Cnt);
				Matrix_R2C1 <= Matrix_R1C1;
				Matrix_R3C1 <= Matrix_R2C1;
				
				Matrix_R1C2 <= Matrix_Column_2(Matrix_Buf_Cnt);
				Matrix_R2C2 <= Matrix_R1C2;
				Matrix_R3C2 <= Matrix_R2C2;
				
				Matrix_R1C3 <= Matrix_Column_3(Matrix_Buf_Cnt);
				Matrix_R2C3 <= Matrix_R1C3;
				Matrix_R3C3 <= Matrix_R2C3;
				
			else	

				Matrix_Column_1(Matrix_Buf_Cnt) <= data_video;
				Matrix_Column_2(Matrix_Buf_Cnt) <= Matrix_R3C1;
				Matrix_Column_3(Matrix_Buf_Cnt) <= Matrix_R3C2;
				
				if Matrix_Buf_Cnt = Matrix_Buf_Length_Max then
					Matrix_Buf_Cnt <= 0;
				else
					Matrix_Buf_Cnt <= Matrix_Buf_Cnt + 1 ;
				end if;				
			end if;
		else
			Matrix_R1C1 <= '0';
			Matrix_R2C1 <= '0';
			Matrix_R3C1 <= '0';
			
			Matrix_R1C2 <= '0';
			Matrix_R2C2 <= '0';
			Matrix_R3C2 <= '0';
			
			Matrix_R1C3 <= '0';
			Matrix_R2C3 <= '0';
			Matrix_R3C3 <= '0';
			Matrix_Buf_Cnt <= 0;
		end if;
	end if;
end if;
end process LoadtoBufferMatrix;
end BufferToMatrix3x3_1Bit_arch;