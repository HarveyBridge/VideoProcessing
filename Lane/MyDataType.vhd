library ieee;
use ieee.std_logic_1164.all;

package MyDataType is
	type Matrix_Buf is array (integer range 0 to 639) of std_logic_vector ((8-1) downto 0);
	type Sobel_buf is array (integer range 0 to 650) of std_logic_vector ((8-1) downto 0);
	type Histogram is array (integer range 0 to 639) of std_logic_vector ((8-1) downto 0);
	type Matrix_Buf_1Bit is array (integer range 0 to 639) of std_logic;		
end MyDataType;