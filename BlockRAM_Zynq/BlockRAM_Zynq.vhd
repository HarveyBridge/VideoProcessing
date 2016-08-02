----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    00:23:16 07/30/2016 
-- Design Name: 
-- Module Name:    BlockRAM_Zynq - Behavioral 
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

-- My Testing 00:23:16 07/30/2016 
--wea is 'High' Write Data to Block RAM
--wea is 'Low' Read Data to Block RAM by Address Number
--addra is memory address ==> 4 bits have 0000~1111 ===> Total 16 
--dina is 16 bits of data 

--for example below
--Time1: 
--		wea 	= '0' 
--		addra	= "0000"
--		dina 	= x"5678"
--		LED 	= x"78"
--Time2: 
--		wea 	= '1' Write
--		addra	= "0000"
--		dina 	= x"2222"
--		LED 	= x"22"


entity BlockRAM_Zynq is
port(
		clk_video 	: in std_logic;
		wea			: in std_logic_vector(0 downto 0);
		addra		: in std_logic_vector(3 downto 0);	
		DebugMux	: in std_logic_vector(2 downto 0);
		DataOut		: out std_logic_vector(7 downto 0)			
	);
end BlockRAM_Zynq;

architecture BlockRAM_Zynq_arch of BlockRAM_Zynq is

signal DataIn		: std_logic_vector(15 downto 0):=x"1234";
signal DataOut_sig 	: std_logic_vector(15 downto 0);
component blk_mem_gen_v7_3 IS
  port (
    	clka 	: IN STD_LOGIC;
    	wea 	: IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    	addra 	: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    	dina 	: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    	douta 	: OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
end component;

begin
DataOut(7 downto 0) <= DataOut_sig(7 downto 0);

BlockRAM_1:blk_mem_gen_v7_3
	port map(
		clka 	=> clk_video,
    	wea 	=> wea,
    	addra 	=> addra,
    	dina 	=> DataIn,
    	douta 	=> DataOut_sig
		);

SelectData:process(DebugMux)
begin
	case DebugMux is --"0001 1111 1111"
		when "000"	=> DataIn <= x"5678";
		when "001"	=> DataIn <= x"1111";
		when "010"	=> DataIn <= x"2222";
		when "011"	=> DataIn <= x"3333";
		when "100"	=> DataIn <= x"4444";
		when "101"	=> DataIn <= x"5555";
		when "110"	=> DataIn <= x"6666";
		when "111"	=> DataIn <= x"7777";		
		when others	=> DataIn <= x"FFFF";
	end case;
end process SelectData;
end BlockRAM_Zynq_arch;

