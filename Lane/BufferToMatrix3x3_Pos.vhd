library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity BufferToMatrix3x3_Pos is
port(
	clk_video	: in std_logic;
	rst_system	: in std_logic;
	data_video 	: in std_logic_vector(7 downto 0);
	cnt_h_sync_vga :in integer range 0 to 857;
	cnt_v_sync_vga :in integer range 0 to 524;
	Matrix_R1C1	: buffer std_logic_vector((8-1) downto 0);
	Matrix_R2C1	: buffer std_logic_vector((8-1) downto 0);
	Matrix_R3C1	: buffer std_logic_vector((8-1) downto 0);
	Matrix_R1C2	: buffer std_logic_vector((8-1) downto 0);
	Matrix_R2C2	: buffer std_logic_vector((8-1) downto 0);
	Matrix_R3C2	: buffer std_logic_vector((8-1) downto 0);
	Matrix_R1C3	: buffer std_logic_vector((8-1) downto 0);
	Matrix_R2C3	: buffer std_logic_vector((8-1) downto 0);
	Matrix_R3C3	: buffer std_logic_vector((8-1) downto 0);
	Matrix_Buf_Cnt	 : buffer integer range 0 to 639:=0
	);
end BufferToMatrix3x3_Pos;

architecture BufferToMatrix3x3_Pos_arch of BufferToMatrix3x3_Pos is

type Matrix_Buf is array (integer range 0 to 639) of std_logic_vector ((8-1) downto 0);
signal Matrix_Column_1 : Matrix_Buf;
signal Matrix_Column_2 : Matrix_Buf;
signal Matrix_Column_3 : Matrix_Buf;
signal Matrix_Buf_Length_Max 	: integer range 0 to 639:=639;
signal Matrix_SaveCase			: integer range 0 to 3:=0;
signal Matrix_SaveCase_Max		: integer range 0 to 3:=2;
signal Matrix_Buf_Full			: std_logic:='0';
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
	Matrix_R1C1 <= "00000000";
	Matrix_R2C1 <= "00000000";
	Matrix_R3C1 <= "00000000";
	
	Matrix_R1C2 <= "00000000";
	Matrix_R2C2 <= "00000000";
	Matrix_R3C2 <= "00000000";
	
	Matrix_R1C3 <= "00000000";
	Matrix_R2C3 <= "00000000";
	Matrix_R3C3 <= "00000000";
	Matrix_Buf_Cnt <= 0;
	Matrix_SaveCase <= 0;
	Matrix_Buf_Full <= '0';
else
	if rising_edge(clk_video) then
		if ( cnt_v_sync_vga >= 0 and cnt_v_sync_vga < 480) then	
			if ( cnt_h_sync_vga >= 0 and cnt_h_sync_vga < 640) then	
				if 	Matrix_Buf_Cnt = Matrix_Buf_Length_Max then
					Matrix_Buf_Cnt <= 0;
					if Matrix_SaveCase = Matrix_SaveCase_Max then
						Matrix_SaveCase <= 0;
						Matrix_Buf_Full <= '1';
					else
						Matrix_SaveCase <= Matrix_SaveCase + 1;
					end if;
				else
					case Matrix_SaveCase is
						when 0 => Matrix_Column_1(Matrix_Buf_Cnt) <= data_video(7 downto 0);							
						when 1 => Matrix_Column_2(Matrix_Buf_Cnt) <= data_video(7 downto 0);							
						when 2 => Matrix_Column_3(Matrix_Buf_Cnt) <= data_video(7 downto 0);
						when others => Matrix_Column_1(Matrix_Buf_Cnt) <= data_video(7 downto 0);
					end case;
					Matrix_Buf_Cnt <= Matrix_Buf_Cnt + 1;					
				end if;				
			else
				Matrix_Buf_Cnt <= 0;
			end if;
		else
			if Matrix_Buf_Full = '1' then
				if 	Matrix_Buf_Cnt = Matrix_Buf_Length_Max then
					Matrix_Buf_Cnt <= 0;	
					Matrix_Buf_Full <= '0';				
				else
					Matrix_R1C1 <= Matrix_Column_1(Matrix_Buf_Cnt);
					Matrix_R1C2 <= Matrix_R1C1;
					Matrix_R1C3 <= Matrix_R1C2;
					Matrix_R2C1 <= Matrix_Column_2(Matrix_Buf_Cnt);
					Matrix_R2C2 <= Matrix_R2C1;
					Matrix_R2C3 <= Matrix_R2C2;
					Matrix_R3C1 <= Matrix_Column_3(Matrix_Buf_Cnt);
					Matrix_R3C2 <= Matrix_R3C1;
					Matrix_R3C3 <= Matrix_R3C2;
					Matrix_Buf_Cnt <= Matrix_Buf_Cnt + 1;					
				end if;
			end if;
		end if;		
	end if;
end if;
end process LoadtoBufferMatrix;
end BufferToMatrix3x3_Pos_arch;