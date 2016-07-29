library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity My_miniUART_Zynq is
    Port ( 
    		clk_video  : in std_logic;    		
    		RxD        : in std_logic;
    		TxD        : out std_logic;
			TxD_Buffer : in std_logic_vector(7 downto 0);
			RxD_Buffer : out std_logic_vector(7 downto 0);
            --I2C-port----------------------------------------------------------------------------------------
				--scl_slave : in  STD_LOGIC;
    --        sda_slave : inout  STD_LOGIC;
				--scl_master : inout  STD_LOGIC;
				--sda_master : inout  STD_LOGIC;
				--scl : inout  STD_LOGIC;
				--sda : inout  STD_LOGIC;
			  --I2C-port----------------------------------------------------------------------------------------
			  
			  --RS232-port--------------------------------------------------------------------------------------
				--td            : out std_logic;    -- RS232 transmitter line
				--rd            : in  std_logic;    -- RS232 receiver line
				--ethernet_cs_n : out std_logic;    -- Ethernet chip-enable			
				
				
				
			   --csss: in std_logic;
			   --rs_Load: in std_logic;
			  --RS232-port--------------------------------------------------------------------------------------
			
			  --Video-port----------------------------------------------------------------------------------------
			   --data_video : in std_logic_vector(7 downto 0);
			   

			 --  h_sync_vga : out std_logic;
				--v_sync_vga : out std_logic;
				--r_vga : out  STD_LOGIC_vector(2 downto 0); --bit 0 reserved for ram addr
				--g_vga : out  STD_LOGIC_vector(2 downto 0); --bit 0 reserved for ram addr
				--b_vga : out  STD_LOGIC_vector(2 downto 0); --bit 0 reserved for ram addr
			  --VGA-port----------------------------------------------------------------------------------------
			   
				rst_system : in  STD_LOGIC);
end My_miniUART_Zynq;

architecture My_miniUART_Zynq_arch of My_miniUART_Zynq is
signal csss				: std_logic;
signal rs_Load			: std_logic;
signal td				: std_logic;
signal rd				: std_logic;
signal ethernet_cs_n	: std_logic;


signal HWDATATmp        : std_logic_vector(31 downto 0);
signal UartOut          : std_logic_vector(7 downto 0);
signal code_out_state	: integer range 0 to 10 :=0;
signal RD_WR            : std_logic;
signal RD_WR_v          : std_logic;
signal RD_WR_cnt		: integer range 0 to 30000 :=0;

component UART is
                   generic(BRDIVISOR :     integer range 0 to 65535 := 130);  -- Baud rate divisor
                 port (
-- Wishbone signals
                   WB_CLK_I          : in  std_logic;  -- clock
                   WB_RST_I          : in  std_logic;  -- Reset input
                   WB_ADR_I          : in  std_logic_vector(1 downto 0);  -- Adress bus          
                   WB_DAT_I          : in  std_logic_vector(7 downto 0);  -- DataIn Bus
                   WB_DAT_O          : out std_logic_vector(7 downto 0);  -- DataOut Bus
                   WB_WE_I           : in  std_logic;  -- Write Enable
                   WB_STB_I          : in  std_logic;  -- Strobe
                   WB_ACK_O          : out std_logic;  -- Acknowledge
-- process signals     
                   IntTx_O           : out std_logic;  -- Transmit interrupt: indicate waiting for Byte
                   IntRx_O           : out std_logic;  -- Receive interrupt: indicate Byte received
                   BR_Clk_I          : in  std_logic;  -- Clock used for Transmit/Receive
                   TxD_PAD_O         : out std_logic;  -- Tx RS232 Line
                   RxD_PAD_I         : in  std_logic);  -- Rx RS232 Line     
  end component;

component miniUART_2 is
  port (
     SysClk   : in  Std_Logic;  -- System Clock
     Reset    : in  Std_Logic;  -- Reset input
     CS_N     : in  Std_Logic;
     RD_N     : in  Std_Logic;
     WR_N     : in  Std_Logic;
     RxD      : in  Std_Logic;
     TxD      : out Std_Logic;
     IntRx_N  : out Std_Logic;  -- Receive interrupt
     IntTx_N  : out Std_Logic;  -- Transmit interrupt
     Addr     : in  Std_Logic_Vector(1 downto 0); -- 
     DataIn   : in  Std_Logic_Vector(7 downto 0); -- 
     DataOut  : out Std_Logic_Vector(7 downto 0)); -- 
end component;

type fsm_state is (read_char_state, write_char_state);  		-- FSM states
signal state_n, state_x     	: fsm_state;  					-- FSM state variable
signal reset_n              	: std_logic;  					-- inversion of reset signal
signal rcv, tx, tx_x      		: std_logic_vector(7 downto 0); -- receive/transmit character data
signal write_n, strobe, ack_n 	: std_logic;  					-- Wishbone interface control signals
signal td_rdy, rd_rdy     		: std_logic;  					-- UART transmit/receive ready flags
signal td_rdy_2, rd_rdy_2     	: std_logic;  					-- UART transmit/receive ready flags
signal reg0               		: std_logic_vector(1 downto 0); -- register address for UART module  
signal tx_t 					: std_logic_vector(7 downto 0);


begin


 --RS232------------------------------------------------------------------------------------------------------

  -- Disable the Ethernet controller so it can't interfere with the peripheral bus
  -- that is also used by the switches and LEDs.
  ethernet_cs_n <= '1';

  -- The UART module needs an active-high reset, so invert it.
  reset_n <= not rst_system;

  -- UART register 0 is used to get data in and out of the UART module, so set the
  -- register address to 0 whenever the receiver has received a character or the
  -- transmitter is ready to send a character.¡@
  reg0 <= "0" & not(rd_rdy or td_rdy);

  -- Instantiation of the UART module.
  u2 : uart
    generic map(
      -- The baud-rate divisor is calculated by dividing the clock frequency by
      -- the baud-rate and then dividing again by four (because the UART receiver
      -- module samples four times within each bit interval).  So for a 50 MHz clock
      -- and a baud-rate of 9600 bps, the divisor is (50,000,000 / 9600) / 4 = 1302.
      brdivisor => 703
      )
    port map(
      wb_clk_i  => clk_video,
      wb_rst_i  => rst_system,
      wb_adr_i  => reg0,
      wb_dat_i  => UartOut,
      wb_dat_o  => rcv,
      wb_we_i   => write_n,
      wb_stb_i  => strobe,
      wb_ack_o  => ack_n,
      inttx_o   => td_rdy,
      intrx_o   => rd_rdy,
      br_clk_i  => clk_video,
      txd_pad_o => td,
      rxd_pad_i => rd
      );

  -- The combinational part of a simple FSM that repeatedly waits for a character to be 
  -- received and then echoes the character back to the sender.
  process(rcv, td_rdy, rd_rdy, state_n)
  begin
    -- Set the default values of these signals so they don't inadvertently become latches.
    state_x       <= state_n;             -- Next state is the same as the current state.
    tx_x          <= tx;                -- Next character to transmit is the same as the current character.
    strobe        <= '0';               -- Don't initiate a Wishbone transaction.
    write_n         <= '0';               -- Don't write data to the UART.
    case state_n is
      when write_char_state =>
        if td_rdy = '1' then            -- Wait for the UART transmitter to be ready to accept a character.
          -- The UART transmitter is available so ...
          strobe  <= '1';               -- activate the Wishbone bus ...
          write_n   <= '1';               -- write data in the transmit character register to the UART, ...
          state_x <= read_char_state;   -- and go back to wait for another character to be received.
        end if;
      when others           => null;
    end case;
  end process;
  u0_miniUART : miniUART_2
  port map (
     SysClk		=>	clk_video ,  -- System Clock
     Reset		=>	rst_system,  -- Reset input
     CS_N     => csss,
     RD_N     => not RD_WR,
     WR_N     => RD_WR,
     RxD      => RxD,
     TxD      => TxD,
     IntRx_N  => rd_rdy_2,  -- Receive interrupt
     IntTx_N  => td_rdy_2,  -- Transmit interrupt
     Addr	  => "00", -- 
     DataIn   => UartOut, -- HWDATAReg; -- 
     DataOut  => HWDATATmp(7 downto 0)); -- 
--UartOut <= " 11 1  11 11 1  1";	  
--UartOut <= "11110111";
				--RD_WR <= '1'; Start TxD
				--RD_WR <= '0'; Start RxD
				--HWDATATmp(7 downto 0)
				
				
process(rst_system,clk_video)--SAH_Y_threshold_8bit
begin
	if rst_system = '0' then
		UartOut <= "00001111";
		RD_WR_cnt <= 0;
		RD_WR <= '1';
		code_out_state <= 0;
	elsif rising_edge(clk_video) then
		case(code_out_state)is
			when 0 =>		
				RD_WR <= '1';
				code_out_state <= 1;
			when 1 =>				
				UartOut <= "10010110";
				if RD_WR_cnt < 28120 then
					RD_WR_cnt <= RD_WR_cnt + 1 ;
					RD_WR <= '0';
				else
					RD_WR <= '0';
					RD_WR_cnt <= 0;
					code_out_state <= 2;
				end if;				
			when 2 =>
				--UartOut <= code1(7 downto 0);
				UartOut <= "00010001";
				if RD_WR_cnt < 28120 then
					RD_WR_cnt <= RD_WR_cnt + 1 ;
					RD_WR <= '1';
				else
					RD_WR <= '0';
					RD_WR_cnt <= 0;
					code_out_state <= 3;
				end if;
			when 3 =>
				--UartOut <= code1(15 downto 8);
				UartOut <= "00100010";
				if RD_WR_cnt < 28120 then
					RD_WR_cnt <= RD_WR_cnt + 1 ;
					RD_WR <= '1';
				else
					RD_WR <= '0';
					RD_WR_cnt <= 0;
					code_out_state <= 4;
				end if;
			when 4 =>
				--UartOut <= code1(23 downto 16);
				UartOut <= "00110011";
				if RD_WR_cnt < 28120 then
					RD_WR_cnt <= RD_WR_cnt + 1 ;
					RD_WR <= '1';
				else
					RD_WR <= '0';
					RD_WR_cnt <= 0;
					code_out_state <= 5;
				end if;
			when 5 =>
				--UartOut <= code1(31 downto 24);
				UartOut <= "10001000";
				if RD_WR_cnt < 28120 then
					RD_WR_cnt <= RD_WR_cnt + 1 ;
					RD_WR <= '1';
				else
					RD_WR <= '0';
					RD_WR_cnt <= 0;
					code_out_state <= 6;
				end if;
			when 6 =>				
				if RD_WR_cnt < 28120 then
					--UartOut <= "10101010";
					RD_WR <= '1';
					RD_WR_cnt <= RD_WR_cnt + 1 ;
				else
					--UartOut <= "01010101";
					--UartOut <= "10010110";
					UartOut <= TxD_Buffer;
					RD_WR <= '0';
					RD_WR_cnt <= 0;
					code_out_state <= 7;
				end if;
			when 7 =>
				--UartOut <= code1(31 downto 24);
				UartOut <= HWDATATmp(7 downto 0);
				RxD_Buffer <= HWDATATmp(7 downto 0);
				if RD_WR_cnt < 28120 then
					RD_WR_cnt <= RD_WR_cnt + 1 ;
					RD_WR <= '1';
				else
					RD_WR <= '0';
					RD_WR_cnt <= 0;
					code_out_state <= 6;
				end if;	
			--when 8 =>
			--	--UartOut <= code1(31 downto 24);
			--	if( HWDATATmp(7 downto 0) = "10000001") then
			--		UartOut <= HWDATATmp(7 downto 0);
			--	end if;
			--	if RD_WR_cnt < 28120 then
			--		RD_WR_cnt <= RD_WR_cnt + 1 ;
			--		RD_WR <= '1';
			--	else
			--		RD_WR <= '0';
			--		RD_WR_cnt <= 0;
			--		code_out_state <= 9;
			--	end if;	
			--when 9 =>				
			--	if RD_WR_cnt < 28120 then
			--		--UartOut <= "10101010";
			--		RD_WR <= '1';
			--		RD_WR_cnt <= RD_WR_cnt + 1 ;
			--	else
			--		UartOut <= "01010101";
			--		--UartOut <= "10010110";
			--		RD_WR <= '0';
			--		RD_WR_cnt <= 0;
			--		code_out_state <= 6;
			--	end if;	
			when others =>
				RD_WR <= '1';
				code_out_state <= 0;
      end case;
   end if;
end process;


end My_miniUART_Zynq_arch;
