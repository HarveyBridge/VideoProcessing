
library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity i2c is
port (
    clk_video  : IN  std_logic;
    rst_system : IN  std_logic;
    scl : out std_logic;
	sda : inout std_logic

);
end i2c;
architecture architecture_i2c of i2c is
  

 --inin i2c
type state_t is(ready,start,commend,ack,addrs,data,stop);
signal state:state_t;
signal count:integer range 0 to 10:=0;
signal sdata:std_logic_vector(7 downto 0);
signal flat:std_logic_vector(2 downto 0);
signal flat_t:std_logic;
signal flat_t2:std_logic;
signal flat_t3:std_logic;
--signal flat_t4:std_logic;
signal set_numble:std_logic_vector(3 downto 0);
signal div:std_logic_vector(19 downto 0);
signal up:std_logic;
signal down:std_logic;
signal div_clk_sda:std_logic;
signal div_clk_scl:std_logic;
signal div_clk:std_logic;
signal i2c_end:std_logic;
 --inin i2c


begin

div_clk <= div(10);
scl <= div_clk_scl;
divclk : process(clk_video, rst_system)
begin
	if rst_system = '0' then
		div <= (others=>'0');
        
	elsif rising_edge(clk_video) then
		div <= div + '1';
        if div=x"FFFFF" then 
			div<=x"00000";
		end if ;
         
	end if;
	
end process;

Master_scl : process(rst_system,clk_video)
begin 
	if rst_system = '0' then
		flat_t <= '0';
		up <= '0';
		down <= '0';
		div_clk_sda <= '1';
		div_clk_scl <= '1';
	elsif rising_edge(clk_video) then
		if div_clk = '1' then 
			if flat_t = '1' then 
				flat_t <= '0';
					if up = '0' then 		
						if i2c_end = '1' then  --finish i2c
										 div_clk_scl <= '1';
                     else
										 div_clk_scl <= '0';
						end if ;
						down <= '1';
					elsif up = '1' then 
						div_clk_scl <= '1';
						down <= '0';
					end if;
			end if ;
		elsif div_clk = '0' then 
			if flat_t = '0' then 
			flat_t <= '1';
					if down = '0' then 
						up <= '0';
						div_clk_sda <= '0';
					elsif down = '1' then 
						up <= '1';
						div_clk_sda <= '1';
					end if;
			end if ;
		end if ;
	 end if ;
end process;

Master_sda : process(rst_system,clk_video)
begin
	if rst_system = '0' then
		sda <= '1';		
		sdata <= "00000000";
		state <= ready;
		flat <= "000";
		flat_t2 <= '0';
		flat_t3 <= '0';
		
		set_numble <= "0000";
		count<= 0;
		i2c_end <= '0' ; 
	elsif rising_edge(clk_video) then
		-----------------********---------------------
		if  div_clk_scl = '1' then
			if flat_t3 = '0' then 
				count <= count + 1;
				flat_t3 <= '1';
			end if ;
		elsif  div_clk_scl = '0' then
			flat_t3 <= '0';
		end if ; 
		---------------*******-------------------------
		case state is 
	
		when ready =>
							if set_numble = "0101" then  --finsh
                     i2c_end <= '1' ; 
							else
								if div_clk_scl = '0' and div_clk_sda = '1' then 
                            state <= start ; 
                        end if ;
                    end if ;
			    
		when start =>
		if  div_clk_sda = '1' and div_clk_scl= '0' then  -- scl = 0
			sda <= '1' ;
		elsif div_clk_sda = '0' and div_clk_scl= '1' then --scl = 1
				sda <= '0';
				flat_t2 <= '0';
				count<=0;
				
				state <= commend; 
			
		end if ;
		when commend =>
		sdata <= "01000010";-----wr   --first  0x42
		if  div_clk_sda = '1' and div_clk_scl = '0' and flat_t2 = '0' then  -- scl = 0  --send data
						flat_t2 <= '1';
						if count <=7 then 
						sda <= sdata(7-count);
						end if ;
		elsif div_clk = '1' then 
			flat_t2 <= '0';
		end if ;
		if count = 8 and div_clk_scl = '0' and div_clk_sda = '1' then 
			
				flat <= "001" ;
			
		state <= ack ;
		
		count <= 0 ;
		end if ;

		when ack =>
		sda <= 'Z';
		--if flat = "110" then
		--SDA <= '0';
		--end if ;
		if div_clk_sda = '0' and div_clk_scl ='0' then 
				if flat = "001" then  --addrs
					flat_t2 <= '0';
					count<=0;
					state <= addrs;
				elsif flat = "010" then  --data
					flat_t2 <= '0';
					count<=0;
					state <= data;
				elsif flat = "011"  then  --stop
					state <= stop;
				end if ;
			end if ;
		
		when addrs =>
        if set_numble = "0000" then 
        sdata<= "00000110";  --set       0x06 (640*480 60hz)        
		elsif set_numble = "0001" then 
        sdata<= "00000101";  --set       0x05
        elsif set_numble = "0010" then 
        sdata<= "00000001";  --set video 0x01  (hs/vs)
        elsif set_numble = "0011" then 
        sdata<= "00000011";  --set output control  0x03
--------------------
        elsif set_numble = "0100" then 
          sdata<= "00000000";  --set input control 0x00 
        elsif set_numble = "0101" then 
        sdata<= "00111010";  --set ADC control 0x3a                
        elsif set_numble = "0110" then 
        sdata<= "00000000";  --set input control 0x00 
        elsif set_numble = "0111" then 
        sdata<= "11000011";  --set adc0 control 0xc3 
        elsif set_numble = "1000" then 
        sdata<= "11000100";  --set adc1 control 0xc4 
        elsif set_numble = "1001" then 
        sdata<= "11110011";  --set adc set 0xf3
        elsif set_numble = "1010" then 
        sdata<= "11101101";  --set fast Blankin 0xED

        end if ;









		flat <= "010";
		if  div_clk_sda = '1' and div_clk_scl = '0' and flat_t2 = '0' then  -- scl = 0
						flat_t2 <= '1';
						if count <=7 then 
						sda <= sdata(7-count);
						end if ;
			elsif div_clk = '1' then 
				flat_t2 <= '0';
			end if ;
			if count = 8 and div_clk_sda = '1' and div_clk_scl = '0' then 
				state <= ack ;
				count <= 0 ;
			end if ;
		
		when data =>
        if set_numble = "0000" then 
        sdata<= "00001000";  --set       0x08 (640*480 60hz)
        elsif set_numble = "0001" then 
        sdata<= "00000000";  --set       0x00
        elsif set_numble = "0010" then 
        sdata<= "11001000";   --set video 0xc8
        elsif set_numble = "0011" then 
        sdata<= "00001100";  --set output control  0x0c
------------
        elsif set_numble = "0100" then 
          sdata<= "00001011";  --set input control 0x0b  av1
        elsif set_numble = "0101" then 
        sdata<= "00010000";--set adc control 0x10        
        elsif set_numble = "0110" then 
        sdata<= "00001101";--set input control 0x0b  av4
        elsif set_numble = "0111" then 
        sdata<= "10111001";--set adc0 control 0xc3 
        elsif set_numble = "1000" then 
        sdata<= "10000101";  ---set adc1 control 0xc4 
        elsif set_numble = "1001" then 
        sdata<= "00001111"; --set adc set 0xf3
        elsif set_numble = "1010" then 
        sdata<= "00010010"; --set fast Blankin 0xED





        end if ;
        flat <= "011"; 






          
            if  div_clk_sda = '1' and div_clk_scl = '0' and flat_t2 = '0' then  -- scl = 0
						flat_t2 <= '1';
						if count <=7 then 
						sda <= sdata(7-count);
						end if ;
			elsif div_clk_sda = '0' then 
				flat_t2 <= '0';
			end if ;
			if count = 8 and div_clk_sda = '1' and div_clk_scl = '0' then 
			state <= ack ;
			count <= 0 ;

            set_numble <= set_numble + '1' ; 
    
			end if ;

        

		when stop =>
		if  div_clk_sda = '1' and  div_clk_scl = '0' then  -- scl = 0
			sda <= '0' ;
		elsif div_clk_sda = '0' and  div_clk_scl = '1' then --scl = 1
				sda <= '1' ; 
				
				state <= ready; 
				
		
		end if ;

		when others => null;
		end case;

	end if ; 
end process;

-----------inin i2c------------------
end architecture_i2c;
