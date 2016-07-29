----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:19:43 07/25/2016 
-- Design Name: 
-- Module Name:    My_miniUART_testBuffer_Zynq - Behavioral 
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

entity My_miniUART_testBuffer_Zynq is
 Port ( 
    		clk_video  : in std_logic;    		
    		RxD        : in std_logic;
    		TxD        : out std_logic;			
			TestBuffer : out integer range 0 to 255;          
			rst_system : in  STD_LOGIC);
end My_miniUART_testBuffer_Zynq;

architecture My_miniUART_testBuffer_Zynq_arch of My_miniUART_testBuffer_Zynq is
signal TxD_Buffer : std_logic_vector(7 downto 0):="10010110"; --0x96
signal RxD_Buffer : std_logic_vector(7 downto 0);

component My_miniUART_Zynq is
	Port(
			clk_video  : in std_logic;    
			rst_system : in  std_logic;		
    		RxD        : in std_logic;
    		TxD        : out std_logic;
    		TxD_Buffer : in std_logic_vector(7 downto 0);
			RxD_Buffer : out std_logic_vector(7 downto 0)
		);
end component;
begin
TestBuffer <= CONV_INTEGER(RxD_Buffer(7 downto 0));
My_miniUART_F1:	My_miniUART_Zynq
	port map (
			clk_video  => clk_video,
			rst_system => rst_system,
    		RxD        => RxD,
    		TxD        => TxD,
    		TxD_Buffer => TxD_Buffer,
			RxD_Buffer => RxD_Buffer
			);

end My_miniUART_testBuffer_Zynq_arch;

