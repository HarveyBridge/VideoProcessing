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
	Matrix_Full : inout Matrix_Buf_Full;
	cnt_h_sync_vga :in integer range 0 to 857;
	cnt_v_sync_vga :in integer range 0 to 524
	);
end BufferToMatrix3x3_Pos;

architecture BufferToMatrix3x3_Pos_arch of BufferToMatrix3x3_Pos is

signal Matrix_X 	: integer range 0 to 639:=639;
signal Matrix_Y		: integer range 0 to 479:=479;

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
	Matrix_X <= 0;
	Matrix_Y <= 0;
else
	if rising_edge(clk_video) then
		if ( cnt_v_sync_vga >= 0 and cnt_v_sync_vga < 480) then	
			if ( cnt_h_sync_vga >= 0 and cnt_h_sync_vga < 641) then	
				if ( cnt_h_sync_vga >= 0 and cnt_h_sync_vga < 640) then	
					Matrix_X <= Matrix_X + 1;
					Matrix_Full(Matrix_Y)(Matrix_X)(7 downto 0) <= data_video(7 downto 0);						
				else
					Matrix_Y <= Matrix_Y + 1;
				end if;
			else
				Matrix_X <= 0;
				Matrix_Y <= Matrix_Y;
			end if;
		else
			Matrix_X <= 0;
			Matrix_Y <= 0;
		end if;		
	end if;
end if;
end process LoadtoBufferMatrix;
end BufferToMatrix3x3_Pos_arch;