library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use work.i2c.all;
--use WORK.sdramj.all;                   --modified xess sdramcntl package for XSA brds.
--use WORK.USBF_Declares.all;             --constants and user type declarations for USB_IFC

entity LDW is
    Port ( 

              --clkm : out std_logic;
              --dinm : out std_logic_VECTOR(7 downto 0);
              --doutm : in std_logic_VECTOR(7 downto 0);
--
              --wem : out std_logic;
              --enm : out std_logic;
              --addrm : out std_logic_VECTOR(15 downto 0);

            --I2C-port----------------------------------------------------------------------------------------
				scl_slave : in  STD_LOGIC;
            sda_slave : inout  STD_LOGIC;
				scl_master : inout  STD_LOGIC;
				sda_master : inout  STD_LOGIC;
				scl : inout  STD_LOGIC;
				sda : inout  STD_LOGIC;
			  --I2C-port----------------------------------------------------------------------------------------
			  
			  --RS232-port--------------------------------------------------------------------------------------
				td            : out std_logic;    -- RS232 transmitter line
				rd            : in  std_logic;    -- RS232 receiver line
				ethernet_cs_n : out std_logic;    -- Ethernet chip-enable
				
				RxD            : in std_logic;
				TxD            : out std_logic;
				
			   csss: in std_logic;
			   rs_Load: in std_logic;
			  --RS232-port--------------------------------------------------------------------------------------
			
			  --Video-port----------------------------------------------------------------------------------------
			   data_video : in std_logic_vector(7 downto 0);
			   clk_video  : in std_logic;
               --hsync      : in std_logic;
               --vsync      : in std_logic;
               --fid        : in std_logic;
               --intreq     : in std_logic;
               --avid       : in std_logic;
			  --Video-port----------------------------------------------------------------------------------------
--				clk_in : in std_logic;
--			
--				data_out : out std_logic;
			  --VGA-port----------------------------------------------------------------------------------------
			   h_sync_vga : out std_logic;
				v_sync_vga : out std_logic;
				r_vga : out  STD_LOGIC_vector(2 downto 0); --bit 0 reserved for ram addr
				g_vga : out  STD_LOGIC_vector(2 downto 0); --bit 0 reserved for ram addr
				b_vga : out  STD_LOGIC_vector(2 downto 0); --bit 0 reserved for ram addr
			  --VGA-port----------------------------------------------------------------------------------------
		
			  --ledarray----------------------------------------------------------------------------------------
--			  ledarray_U :  out  STD_LOGIC_vector(7 downto 0);
--			  ledarray_D :  out  STD_LOGIC_vector(7 downto 0);
--              buzzer: out STD_LOGIC;
			  --ledarray----------------------------------------------------------------------------------------
			  
			  --switch----------------------------------------------------------------------------------------			  
--			  switch_select : in std_logic_vector(3 downto 0);
			  --switch----------------------------------------------------------------------------------------
			  	  
				--others
--                disable_but : in STD_LOGIC;
--                setup_but : in STD_LOGIC;

				rst_system : in  STD_LOGIC);
end LDW;

 architecture Behavioral of LDW is
--

signal HWDATATmp                      : std_logic_vector(31 downto 0);
signal UartOut                        : std_logic_vector(7 downto 0);
signal code_out_state					  : integer range 0 to 10 :=0;
signal RD_WR              : std_logic;
signal RD_WR_v              : std_logic;

signal RD_WR_cnt					  : integer range 0 to 30000 :=0;


--
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
  signal reset_n              : std_logic;  -- inversion of reset signal
  signal rcv, tx, tx_x      : std_logic_vector(7 downto 0);  -- receive/transmit character data
  signal write_n, strobe, ack_n : std_logic;  -- Wishbone interface control signals
  signal td_rdy, rd_rdy     : std_logic;  -- UART transmit/receive ready flags
  signal td_rdy_2, rd_rdy_2     : std_logic;  -- UART transmit/receive ready flags
  signal reg0               : std_logic_vector(1 downto 0);  -- register address for UART module
  type fsm_state is (read_char_state, write_char_state);  -- FSM states
  signal state_n, state_x     : fsm_state;  -- FSM state variable
  signal tx_t : std_logic_vector(7 downto 0);
  
signal timeout_i2c : integer range 0 to 27000000 :=0;

signal SAH_Y_threshold_8bit : std_logic_vector(7 downto 0) := "10100000";
signal SAH_Y_threshold_4bit : std_logic_vector(3 downto 0) := "1010";

signal SAH_Y_threshold_3bit : std_logic_vector(2 downto 0) := "101";

type focus_matrix_type is ARRAY (integer range 0 to 7) of std_logic_vector(7 downto 0);
signal focus_matrix : focus_matrix_type;
signal led_matrix_cnt : integer range 0 to 60000000 :=0;

signal whiteword_cnt : integer range 0 to 60000000 :=0;
signal whiteword_state : integer range 0 to 10 :=0;
signal whiteword_en	: STD_LOGIC:='0';

signal I2C_ADDR : std_logic_vector(6 downto 0) := "1011100";
--signal warning_cnt_max : integer := 100;

signal ldw_level_one_base : integer := 360;
signal ldw_level_two_base : integer := 330;
signal ldw_level_three_base : integer := 310;
signal ldw_level_range : integer := 10;
signal ldw_preview_range : integer := 40;


signal ld_focus_x : integer := 90;
signal ld_focus_y : integer := 355;
signal rd_focus_x : integer := 550;
signal rd_focus_y : integer := 355;

signal lu_focus_x : integer := 170;
signal lu_focus_y : integer := 305;
signal ru_focus_x : integer := 470;
signal ru_focus_y : integer := 305;
signal focus_range : integer := 10;
--signal warning_cnt_max : integer := 100;


signal system_state : integer range 0 to 3 :=0;-- system_state => 0 : disable , 1 : setup mode , 2 : system working

signal warning_limit_cnt : integer range 0 to 60000000 :=0;
signal warning_limit_cnt_en	: STD_LOGIC:='0';
signal rst_button_click	: STD_LOGIC:='0';
signal rst_button_click_times_LDW : integer range 0 to 19 :=0;
signal rst_button_click_times_SAH : integer range 0 to 19 :=0;
signal rst_button_push_cnt : integer range 0 to 50000000 :=0;
--signal rst_cnt : integer range 0 to 50000000 :=0;
signal warning_cnt : integer range 0 to 200 :=0;
signal warning_cnt_level : integer range 0 to 200 :=0;

--3*3 filter by Chueh-Han Lo 20120822------------------------------------------------------------------------------------------
signal SB_F33_total : std_logic_vector(11 downto 0);
signal F33_total : std_logic;
--3*3 filter by Chueh-Han Lo 20120822------------------------------------------------------------------------------------------
--signal squarelight_1 : std_logic_vector(7 downto 0);
--signal squarelight_2 : std_logic_vector(7 downto 0);
--signal squarelight_state : integer range 0 to 27000001 :=0;

signal ALL_TIME : integer range 0 to 27000001 :=0;
--
-------------------i2c--------------------------------------------------------------------------------------
-----I2C----------------------------------------
type STATE_I2C is (start, slv_ack, wr , stop); 
signal I2C_state : STATE_I2C ;
signal I2C_device_address : std_logic_vector(7 downto 0):= "10111010";
signal I2C_word_address : std_logic_vector(7 downto 0):= "00000011";
signal I2C_write_data : std_logic_vector(7 downto 0):= "00001001";
signal I2C_bit_cnt : integer range 0 to 8;
signal I2C_data_state : integer range 0 to 2 ;
signal divcount : std_logic_vector(23 downto 0);

-------------------i2cmaster--------------------------------------------------------------------------------------
type i2c_data_state_master is (ready,start,commend,mastack,readcode1,readack1,readcode2,readack2,
								readcode3,readack3,readcode4,readack4,stop);
signal state_i2c_master	: i2c_data_state_master;
signal cntcode 	: integer range 0 to 10 :=0;
signal changstate	: integer range 0 to 10 :=0;
signal wrrd			: integer range 0 to 10 :=0;
signal code4		: STD_LOGIC_VECTOR (7 downto 0);
signal divcount_master	: STD_LOGIC_VECTOR (25 downto 0);
signal divclk  	: STD_LOGIC;
---------------------------------------------------------------------------------------------------------------

-----I2Cslave----------------------------------------
type i2c_data_state_slave is (ready,start,commend,slvackup,slvackdown,code_1,masack_1up,masack_1down,code_2,masack_2up,
								masack_2down,code_3,masack_3up,masack_3down,code_4,masack_4up,masack_4down,stop);
signal state_i2c_slave	: i2c_data_state_slave;
signal code_cnt 	: integer range 0 to 8 :=0;
signal commend_cnt: integer range 0 to 8 :=0;
signal code_cnt_en: STD_LOGIC;
signal code0		: STD_LOGIC_VECTOR (7 downto 0);
signal code1		: STD_LOGIC_VECTOR (31 downto 0);
signal code2		: STD_LOGIC_VECTOR (31 downto 0);
signal sda_reg		: STD_LOGIC;
signal sda_sure	: integer range 0 to 8 :=0;

------------------------------------|
--DFB = Differential Binary Buffer--|
------------------------------------|
signal DFB_buf_out_data : std_logic_vector((8-1) downto 0):="00000000";
signal DFB_buf_cnt : integer range 0 to 38400-1:=0;
signal DFB_buf_cnt_max : integer range 0 to 38400-1:=38400-1;
signal DFB_data_delay_1 : std_logic_vector((8-1) downto 0):="00000000";
signal DFB_data_delay_2 : std_logic_vector((8-1) downto 0):="00000000";
signal DFB_data_delay_3 : std_logic_vector((8-1) downto 0):="00000000";
signal DFB_data_delay_4 : std_logic_vector((8-1) downto 0):="00000000";
signal DFB_data_delay_5 : std_logic_vector((8-1) downto 0):="00000000";
-----------|
--DFB End--|
-----------|

----------------------lane line---------------------
type laneline_state_0 is (start_0,edge1_0,width_0,edge2_0,edgeend_0,road0);
signal state_laneline_0	: laneline_state_0;
type laneline_state_1 is (start_1,edge1_1,width_1,edge2_1,edgeend_1,road1);
signal state_laneline_1	: laneline_state_1;
type laneline_state_2 is (start_2,edge1_2,width_2,edge2_2,edgeend_2,road2);
signal state_laneline_2	: laneline_state_2;
type laneline_state_3 is (start_3,edge1_3,width_3,edge2_3,edgeend_3,road3);
signal state_laneline_3	: laneline_state_3;

signal state_laneline_0_0	: laneline_state_0;
signal state_laneline_1_0	: laneline_state_1;
signal state_laneline_2_0	: laneline_state_2;
signal state_laneline_3_0	: laneline_state_3;

signal h_line_0_0		: integer range 0 to 640 :=0;
signal h_line_0_out_0	: integer range 0 to 640 :=0;
signal h_line_0_cnt_0  : integer range 0 to 100 :=0;
signal h_line_0_en_0	: STD_LOGIC;
signal h_line_1_0 		: integer range 0 to 640 :=0;
signal h_line_1_out_0	: integer range 0 to 640 :=0;
signal h_line_1_cnt_0 	: integer range 0 to 100 :=0;
signal h_line_1_en_0 	: STD_LOGIC;
signal h_line_2_0 		: integer range 0 to 640 :=0;
signal h_line_2_out_0	: integer range 0 to 640 :=0;
signal h_line_2_cnt_0 	: integer range 0 to 100 :=0;
signal h_line_2_en_0	: STD_LOGIC;
signal h_line_3_0 		: integer range 0 to 640 :=0;
signal h_line_3_out_0	: integer range 0 to 640 :=0;
signal h_line_3_cnt_0 	: integer range 0 to 100 :=0;
signal h_line_3_en_0	: STD_LOGIC;
signal laneline_cnt_0  : integer range 0 to 27000000 :=0; 
signal laneline_sure_L_0 : STD_LOGIC;
signal laneline_cnt_1_0  : integer range 0 to 27000000 :=0; 
signal laneline_sure_R_0 : STD_LOGIC;
signal road_cnt0_0	: integer range 0 to 100 :=0;
signal road_cnt1_0	: integer range 0 to 100 :=0;
signal road_cnt2_0	: integer range 0 to 100 :=0;
signal road_cnt3_0	: integer range 0 to 100 :=0;

signal laneline_R_out_0 : integer range 0 to 640 :=0;
signal laneline_L_out_0 : integer range 0 to 640 :=0;
signal lanelinefilter_0	: integer range 0 to 10 :=0; 
signal laneline_R_out_four_0 : integer range 0 to 2560 :=0;
signal laneline_L_out_four_0 : integer range 0 to 2560 :=0;
signal laneline_R_out_logic_0 : STD_LOGIC_VECTOR (11 downto 0);
signal laneline_L_out_logic_0 : STD_LOGIC_VECTOR (11 downto 0);
signal laneline_R_out_0_0 : integer range 0 to 640 :=0;
signal laneline_R_out_1_0 : integer range 0 to 640 :=0;
signal laneline_R_out_2_0 : integer range 0 to 640 :=0;
signal laneline_R_out_3_0 : integer range 0 to 640 :=0;
signal laneline_R_out_4_0 : integer range 0 to 640 :=0;
signal laneline_R_out_5_0 : integer range 0 to 640 :=0;
signal laneline_R_out_6_0 : integer range 0 to 640 :=0;
signal laneline_R_out_7_0 : integer range 0 to 640 :=0;
signal laneline_L_out_0_0 : integer range 0 to 640 :=0;
signal laneline_L_out_1_0 : integer range 0 to 640 :=0;
signal laneline_L_out_2_0 : integer range 0 to 640 :=0;
signal laneline_L_out_3_0 : integer range 0 to 640 :=0;
signal laneline_L_out_4_0 : integer range 0 to 640 :=0;
signal laneline_L_out_5_0 : integer range 0 to 640 :=0;
signal laneline_L_out_6_0 : integer range 0 to 640 :=0;
signal laneline_L_out_7_0 : integer range 0 to 640 :=0;
signal shift_state_0 : integer range 0 to 5 :=0;
signal laneline_half_state_0 : integer range 0 to 3 :=0;
signal laneline_half_0	: integer range 0 to 640 :=0;
signal laneline_quarter_0	: integer range 0 to 160 :=0;
signal laneline_half_two_0	: integer range 0 to 1280 :=0;
signal laneline_half_logic_0	: STD_LOGIC_VECTOR (10 downto 0);
signal laneline_half_en_0 : integer range 0 to 3 :=0;
signal laneline_halfsure_en_0 : STD_LOGIC;
signal laneline_width_0	: integer range 0 to 640 :=0;
signal laneline_width_sure_0 : STD_LOGIC;
signal laneline_widthhalf_0 : integer range 0 to 320 :=0;
signal laneline_width_logic_0 : STD_LOGIC_VECTOR (8 downto 0);
signal laneline_width_x_0	: integer range 0 to 640 :=0;
signal laneline_width_en_0	: STD_LOGIC;
signal laneline_point_cnt_0	: integer range 0 to 2000 :=0;
signal laneline_point_en_0	: STD_LOGIC;
signal laneline_pointrange_L_0	: integer range 0 to 640 :=0;
signal laneline_pointrange_R_0	: integer range 0 to 640 :=0;
signal delay_1s_cnt_0	: integer range 0 to 27000000 :=0; -- 1s = 27000000+
signal delay_sec_0 		: integer range 0 to 10 :=0;
signal delay_en_0 		: STD_LOGIC;
----------------------lane line---------------------
----------------------lane line---------------------

----------------------lane line---------------------

signal state_laneline_0_2	: laneline_state_0;
signal state_laneline_1_2	: laneline_state_1;
signal state_laneline_2_2	: laneline_state_2;
signal state_laneline_3_2	: laneline_state_3;

signal h_line_0_2		: integer range 0 to 640 :=0;
signal h_line_0_out_2	: integer range 0 to 640 :=0;
signal h_line_0_cnt_2  : integer range 0 to 100 :=0;
signal h_line_0_en_2	: STD_LOGIC;
signal h_line_1_2 		: integer range 0 to 640 :=0;
signal h_line_1_out_2	: integer range 0 to 640 :=0;
signal h_line_1_cnt_2 	: integer range 0 to 100 :=0;
signal h_line_1_en_2 	: STD_LOGIC;
signal h_line_2_2 		: integer range 0 to 640 :=0;
signal h_line_2_out_2	: integer range 0 to 640 :=0;
signal h_line_2_cnt_2 	: integer range 0 to 100 :=0;
signal h_line_2_en_2	: STD_LOGIC;
signal h_line_3_2 		: integer range 0 to 640 :=0;
signal h_line_3_out_2	: integer range 0 to 640 :=0;
signal h_line_3_cnt_2 	: integer range 0 to 100 :=0;
signal h_line_3_en_2	: STD_LOGIC;
signal laneline_cnt_2  : integer range 0 to 27000000 :=0; 
signal laneline_sure_L_2 : STD_LOGIC;
signal laneline_cnt_1_2  : integer range 0 to 27000000 :=0; 
signal laneline_sure_R_2 : STD_LOGIC;
signal road_cnt0_2	: integer range 0 to 100 :=0;
signal road_cnt1_2	: integer range 0 to 100 :=0;
signal road_cnt2_2	: integer range 0 to 100 :=0;
signal road_cnt3_2	: integer range 0 to 100 :=0;

signal laneline_R_out_2 : integer range 0 to 640 :=0;
signal laneline_L_out_2 : integer range 0 to 640 :=0;
signal lanelinefilter_2	: integer range 0 to 10 :=0; 
signal laneline_R_out_four_2 : integer range 0 to 2560 :=0;
signal laneline_L_out_four_2 : integer range 0 to 2560 :=0;
signal laneline_R_out_logic_2 : STD_LOGIC_VECTOR (11 downto 0);
signal laneline_L_out_logic_2 : STD_LOGIC_VECTOR (11 downto 0);
signal laneline_R_out_0_2 : integer range 0 to 640 :=0;
signal laneline_R_out_1_2 : integer range 0 to 640 :=0;
signal laneline_R_out_2_2 : integer range 0 to 640 :=0;
signal laneline_R_out_3_2 : integer range 0 to 640 :=0;
signal laneline_R_out_4_2 : integer range 0 to 640 :=0;
signal laneline_R_out_5_2 : integer range 0 to 640 :=0;
signal laneline_R_out_6_2 : integer range 0 to 640 :=0;
signal laneline_R_out_7_2 : integer range 0 to 640 :=0;
signal laneline_L_out_0_2 : integer range 0 to 640 :=0;
signal laneline_L_out_1_2 : integer range 0 to 640 :=0;
signal laneline_L_out_2_2 : integer range 0 to 640 :=0;
signal laneline_L_out_3_2 : integer range 0 to 640 :=0;
signal laneline_L_out_4_2 : integer range 0 to 640 :=0;
signal laneline_L_out_5_2 : integer range 0 to 640 :=0;
signal laneline_L_out_6_2 : integer range 0 to 640 :=0;
signal laneline_L_out_7_2 : integer range 0 to 640 :=0;
signal shift_state_2 : integer range 0 to 5 :=0;
signal laneline_half_state_2 : integer range 0 to 3 :=0;
signal laneline_half_2	: integer range 0 to 640 :=0;
signal laneline_quarter_2	: integer range 0 to 160 :=0;
signal laneline_half_two_2	: integer range 0 to 1280 :=0;
signal laneline_half_logic_2	: STD_LOGIC_VECTOR (10 downto 0);
signal laneline_half_en_2 : integer range 0 to 3 :=0;
signal laneline_halfsure_en_2 : STD_LOGIC;
signal laneline_width_2	: integer range 0 to 640 :=0;
signal laneline_width_sure_2 : STD_LOGIC;
signal laneline_widthhalf_2 : integer range 0 to 320 :=0;
signal laneline_width_logic_2 : STD_LOGIC_VECTOR (8 downto 0);
signal laneline_width_x_2	: integer range 0 to 640 :=0;
signal laneline_width_en_2	: STD_LOGIC;
signal laneline_point_cnt_2	: integer range 0 to 2000 :=0;
signal laneline_point_en_2	: STD_LOGIC;
signal laneline_pointrange_L_2	: integer range 0 to 640 :=0;
signal laneline_pointrange_R_2	: integer range 0 to 640 :=0;
signal delay_1s_cnt_2	: integer range 0 to 27000000 :=0; -- 1s = 27000000+
signal delay_sec_2 		: integer range 0 to 10 :=0;
signal delay_en_2 		: STD_LOGIC;
----------------------lane line---------------------

----------------------lane line---------------------
signal state_laneline_0_1	: laneline_state_0;
signal state_laneline_1_1	: laneline_state_1;
signal state_laneline_2_1	: laneline_state_2;
signal state_laneline_3_1	: laneline_state_3;

signal h_line_0_1		: integer range 0 to 640 :=0;
signal h_line_0_out_1	: integer range 0 to 640 :=0;
signal h_line_0_cnt_1  : integer range 0 to 100 :=0;
signal h_line_0_en_1	: STD_LOGIC;
signal h_line_1_1 		: integer range 0 to 640 :=0;
signal h_line_1_out_1	: integer range 0 to 640 :=0;
signal h_line_1_cnt_1 	: integer range 0 to 100 :=0;
signal h_line_1_en_1 	: STD_LOGIC;
signal h_line_2_1 		: integer range 0 to 640 :=0;
signal h_line_2_out_1	: integer range 0 to 640 :=0;
signal h_line_2_cnt_1 	: integer range 0 to 100 :=0;
signal h_line_2_en_1	: STD_LOGIC;
signal h_line_3_1 		: integer range 0 to 640 :=0;
signal h_line_3_out_1	: integer range 0 to 640 :=0;
signal h_line_3_cnt_1 	: integer range 0 to 100 :=0;
signal h_line_3_en_1	: STD_LOGIC;
signal laneline_cnt_1  : integer range 0 to 27000000 :=0; 
signal laneline_sure_L_1 : STD_LOGIC;
signal laneline_cnt_1_1  : integer range 0 to 27000000 :=0; 
signal laneline_sure_R_1 : STD_LOGIC;
signal road_cnt0_1	: integer range 0 to 100 :=0;
signal road_cnt1_1	: integer range 0 to 100 :=0;
signal road_cnt2_1	: integer range 0 to 100 :=0;
signal road_cnt3_1	: integer range 0 to 100 :=0;

signal laneline_R_out_1 : integer range 0 to 640 :=0;
signal laneline_L_out_1 : integer range 0 to 640 :=0;
signal lanelinefilter_1	: integer range 0 to 10 :=0; 
signal laneline_R_out_four_1 : integer range 0 to 2560 :=0;
signal laneline_L_out_four_1 : integer range 0 to 2560 :=0;
signal laneline_R_out_logic_1 : STD_LOGIC_VECTOR (11 downto 0);
signal laneline_L_out_logic_1 : STD_LOGIC_VECTOR (11 downto 0);
signal laneline_R_out_0_1 : integer range 0 to 640 :=0;
signal laneline_R_out_1_1 : integer range 0 to 640 :=0;
signal laneline_R_out_2_1 : integer range 0 to 640 :=0;
signal laneline_R_out_3_1 : integer range 0 to 640 :=0;
signal laneline_R_out_4_1 : integer range 0 to 640 :=0;
signal laneline_R_out_5_1 : integer range 0 to 640 :=0;
signal laneline_R_out_6_1 : integer range 0 to 640 :=0;
signal laneline_R_out_7_1 : integer range 0 to 640 :=0;
signal laneline_L_out_0_1 : integer range 0 to 640 :=0;
signal laneline_L_out_1_1 : integer range 0 to 640 :=0;
signal laneline_L_out_2_1 : integer range 0 to 640 :=0;
signal laneline_L_out_3_1 : integer range 0 to 640 :=0;
signal laneline_L_out_4_1 : integer range 0 to 640 :=0;
signal laneline_L_out_5_1 : integer range 0 to 640 :=0;
signal laneline_L_out_6_1 : integer range 0 to 640 :=0;
signal laneline_L_out_7_1 : integer range 0 to 640 :=0;
signal shift_state_1 : integer range 0 to 5 :=0;
signal laneline_half_state_1 : integer range 0 to 3 :=0;
signal laneline_half_1	: integer range 0 to 640 :=0;
signal laneline_quarter_1	: integer range 0 to 160 :=0;
signal laneline_half_two_1	: integer range 0 to 1280 :=0;
signal laneline_half_logic_1	: STD_LOGIC_VECTOR (10 downto 0);
signal laneline_half_en_1 : integer range 0 to 3 :=0;
signal laneline_halfsure_en_1 : STD_LOGIC;
signal laneline_width_1	: integer range 0 to 640 :=0;
signal laneline_width_sure_1 : STD_LOGIC;
signal laneline_widthhalf_1 : integer range 0 to 320 :=0;
signal laneline_width_logic_1 : STD_LOGIC_VECTOR (8 downto 0);
signal laneline_width_x_1	: integer range 0 to 640 :=0;
signal laneline_width_en_1	: STD_LOGIC;
signal laneline_point_cnt_1	: integer range 0 to 2000 :=0;
signal laneline_point_en_1	: STD_LOGIC;
signal laneline_pointrange_L_1	: integer range 0 to 640 :=0;
signal laneline_pointrange_R_1	: integer range 0 to 640 :=0;
signal delay_1s_cnt_1	: integer range 0 to 27000000 :=0; -- 1s = 27000000+
signal delay_sec_1 		: integer range 0 to 10 :=0;
signal delay_en_1 		: STD_LOGIC;
----------------------lane line---------------------


--video------------------------------------------------------------------------------------------------------
signal EAV_new : std_logic_vector(1 downto 0):="ZZ";
signal SAV_old : std_logic_vector(1 downto 0):="ZZ";
signal EAV_state : std_logic_vector(1 downto 0):="00";
signal SAV_state : std_logic_vector(1 downto 0):="00";
signal SAV_en : std_logic:='0';

signal cnt_video_hsync : integer range 0 to 1715:=0;

signal f_video_en : std_logic:='Z'; --Field
signal cnt_video_en : std_logic:='0';
signal cnt_vga_en : std_logic:='0';
signal buf_vga_en : std_logic:='0';

signal cnt_h_sync_vga : integer range 0 to 857:=0;
signal cnt_v_sync_vga : integer range 0 to 524:=0;
signal black_vga_en : std_logic:='0';
signal sync_vga_en : std_logic:='0';
signal f0_vga_en : std_logic:='0'; --Field 0
--video------------------------------------------------------------------------------------------------------

--VGA-8bit-------------------------------------------------------------------------------------------------------
signal buf_vga_state : std_logic_vector(1 downto 0):="00";

type Array_Y is ARRAY (integer range 0 to 639) of std_logic_vector(2 downto 0);
type Array_Y_4 is ARRAY (integer range 0 to 639) of std_logic_vector(3 downto 0);
type Array_Y_1 is ARRAY (integer range 0 to 639) of std_logic;
type Array_Y_full is ARRAY (integer range 0 to 639) of std_logic_vector(7 downto 0);
signal buf_vga_Y : Array_Y;
signal buf_vga_Y_2 : Array_Y_4;
signal buf_vga_Y_3 : Array_Y_full;
signal buf_vga_Y_in_cnt  : integer range 0 to 639:=0;
signal buf_vga_Y_out_cnt : integer range 0 to 639:=639;
signal buf_vga_Y_data_1  : std_logic:='0';
signal buf_vga_Y_data_2B  : std_logic:='0';
signal buf_vga_Y_data    : Array_Y_1;
signal buf_vga_Y_data_2    : Array_Y_1;
signal vga_CRB_data      : std_logic:='0';
signal vga_CRB_data_2      : std_logic:='0';


type Array_YUV is ARRAY (integer range 0 to 639) of std_logic_vector(7 downto 0);
--signal YCR : integer range 0 to 1023;
signal YCR : std_logic_vector(19 downto 0);
signal YCG : std_logic_vector(19 downto 0);
signal YCB : std_logic_vector(19 downto 0);
signal YCR_C1 : std_logic_vector(11 downto 0);
signal YCG_C1 : std_logic_vector(11 downto 0);
signal YCG_C2 : std_logic_vector(11 downto 0);
signal YCB_C1 : std_logic_vector(11 downto 0);
signal buf_vga_R, buf_vga_G, buf_vga_B : Array_YUV;
signal Cb_register, Cr_register : std_logic_vector(7 downto 0);
--signal buf_vga_CbYCr_state : std_logic:='0';


--VGA-8bit-------------------------------------------------------------------------------------------------------

--state-------------------------------------------------------------------------------------------------------
signal range_total_cnt : integer range 0 to 1289:=0;
signal range_total_cnt_en : std_logic:='0';
signal buf_Y_temp_en : std_logic:='0';
signal DF_buf_012_en : std_logic:='0';
signal buf_sobel_cc_en : std_logic:='0';
signal buf_sobel_cc_delay : integer range 0 to 3:=0;
signal DFB_buf_en : std_logic:='0';
signal buf_data_state : std_logic_vector(1 downto 0):="00";
--state-------------------------------------------------------------------------------------------------------

------------------------------|
--SSC = System State Control--|
------------------------------|
signal SSC_state : integer range 0 to 20:=0;
-------------|
--SSC = End--|
-------------|

--------------------------|
----FD = First Detection--|
--------------------------|
--signal MT_to_FD_en : std_logic:='1';
--signal MT_FD_en_end : std_logic:='0';
signal MT_YS_data : std_logic_vector(7 downto 0):="00000000";
--

---------------------|
--SB = Sobel Buffer--|
---------------------|
type Array_Sobel_buf is array (integer range 0 to 639) of std_logic_vector ((8-1) downto 0);

signal SB_buf_0 : Array_Sobel_buf;
signal SB_buf_0_data_1 : std_logic_vector((10-1) downto 0):="0000000000";
signal SB_buf_0_data_2 : std_logic_vector((10-1) downto 0):="0000000000";
signal SB_buf_0_data_3 : std_logic_vector((10-1) downto 0):="0000000000";

signal SB_buf_1 : Array_Sobel_buf;
signal SB_buf_1_data_1 : std_logic_vector((10-1) downto 0):="0000000000";
signal SB_buf_1_data_2 : std_logic_vector((10-1) downto 0):="0000000000";
signal SB_buf_1_data_3 : std_logic_vector((10-1) downto 0):="0000000000";

signal SB_buf_2 : Array_Sobel_buf;
signal SB_buf_2_data_1 : std_logic_vector((10-1) downto 0):="0000000000";
signal SB_buf_2_data_2 : std_logic_vector((10-1) downto 0):="0000000000";
signal SB_buf_2_data_3 : std_logic_vector((10-1) downto 0):="0000000000";

signal SB_buf_in_data : std_logic_vector((8-1) downto 0):="00000000";
signal SB_buf_cnt : integer range 0 to 639:=0;
signal SB_buf_cnt_max : integer range 0 to 639:=639; --0~639

signal SB_XSCR : std_logic_vector((10-1) downto 0):="0000000000";
signal SB_YSCR : std_logic_vector((10-1) downto 0):="0000000000";
signal SB_CRB_data : std_logic:='0';
----------|
--SB End--|
----------|


---------------------|
--DF = Differential--|
---------------------|
type Array_Dilation_buf is array (integer range 0 to 639) of std_logic;
signal DF_buf_0 : Array_Dilation_buf;
signal DF_buf_0_data_1 : std_logic;
signal DF_buf_0_data_2 : std_logic;
signal DF_buf_0_data_3 : std_logic;

signal DF_buf_1 : Array_Dilation_buf;
signal DF_buf_1_data_1 : std_logic;
signal DF_buf_1_data_2 : std_logic;
signal DF_buf_1_data_3 : std_logic;

signal DF_buf_2 : Array_Dilation_buf;
signal DF_buf_2_data_1 : std_logic;
signal DF_buf_2_data_2 : std_logic;
signal DF_buf_2_data_3 : std_logic;

signal DF_buf_in_data : std_logic_vector((8-1) downto 0):="00000000";
signal DF_buf_cnt : integer range 0 to 639:=0;
signal DF_buf_cnt_max : integer range 0 to 639:=639; --0~639

signal DF_XSCR : std_logic_vector((10-1) downto 0):="0000000000";
signal DF_YSCR : std_logic_vector((10-1) downto 0):="0000000000";
signal DF_CRB_data : std_logic:='0';
----------|
--DF End--|
----------|

------------------------------------------------------------------------------------------------------

---------------------|
--Skin = Sobel Buffer--|
---------------------|

signal Skin_buf_2 : Array_Dilation_buf;
signal Skin_buf_2_2 : Array_Dilation_buf;
signal Skin_buf_2_data_1 : std_logic;
signal Skin_buf_2_data_2 : std_logic;
signal Skin_buf_2_data_3 : std_logic;
signal Skin_buf_2_data_3_2 : std_logic;

signal Skin_buf_cnt : integer range 0 to 639:=0;
signal Skin_buf_cnt_max : integer range 0 to 639:=639; --0~639


signal Skin_CRB_data : std_logic:='0';
signal Skin_CRB_data_2 : std_logic:='0';
----------|
--Skin End--|
----------|


----------------------white-judge------------------------------------------------------
signal white_buf_2 : Array_Dilation_buf;
signal white_buf_2_2 : Array_Dilation_buf;
signal white_buf_2_data_1 : std_logic;
signal white_buf_2_data_2 : std_logic;
signal white_buf_2_data_3 : std_logic;
signal white_buf_2_data_3_2 : std_logic;
signal white_buf_cnt : integer range 0 to 639:=0;
signal white_buf_cnt_max : integer range 0 to 639:=639; --0~639


signal white_CRB_data : std_logic:='0';
signal white_CRB_data_2 : std_logic:='0';

----------------------white-judge------------------------------------------------------	


------------------------------------------------------------------------------------------------------

-----------------------|
--ER = Erosion Buffer--|
-----------------------|
signal ER_buf_012_en : std_logic:='0';
signal buf_erosion_cc_en : std_logic:='0';
signal ERB_buf_en : std_logic:='0';

--type Array_Sobel_buf is array (integer range 0 to 639) of std_logic_vector ((8-1) downto 0);
signal ER_buf_0 : Array_Dilation_buf;
signal ER_buf_0_data_1 : std_logic_vector(3 downto 0);
signal ER_buf_0_data_2 : std_logic_vector(3 downto 0);
signal ER_buf_0_data_3 : std_logic_vector(3 downto 0);

signal ER_buf_1 : Array_Dilation_buf;
signal ER_buf_1_data_1 : std_logic_vector(3 downto 0);
signal ER_buf_1_data_2 : std_logic_vector(3 downto 0);
signal ER_buf_1_data_3 : std_logic_vector(3 downto 0);

signal ER_buf_2 : Array_Dilation_buf;
signal ER_buf_2_data_1 : std_logic_vector(3 downto 0);
signal ER_buf_2_data_2 : std_logic_vector(3 downto 0);
signal ER_buf_2_data_3 : std_logic_vector(3 downto 0);

signal ER_buf_in_data : std_logic_vector((8-1) downto 0):="00000000";
signal ER_buf_cnt : integer range 0 to 639:=0;
signal ER_buf_cnt_max : integer range 0 to 639:=639; --0~639

signal ER_XSCR : std_logic_vector(3 downto 0);
signal ER_YSCR : std_logic_vector((10-1) downto 0):="0000000000";
signal ER_CRB_data : std_logic:='0';
----------|
--ER End--|
----------|

-------------------------------|
--ERB = Erosion Binary Buffer--|
-------------------------------|
signal ERB_buf_out_data : std_logic_vector((8-1) downto 0):="00000000";
signal ERB_buf_cnt : integer range 0 to 38400-1:=0;
signal ERB_buf_cnt_max : integer range 0 to 38400-1:=38400-1;
signal ERB_data_delay_1 : std_logic_vector((8-1) downto 0):="00000000";
signal ERB_data_delay_2 : std_logic_vector((8-1) downto 0):="00000000";
signal ERB_data_delay_3 : std_logic_vector((8-1) downto 0):="00000000";
signal ERB_data_delay_4 : std_logic_vector((8-1) downto 0):="00000000";
signal ERB_data_delay_5 : std_logic_vector((8-1) downto 0):="00000000";
-----------|
--ERB End--|
-----------|

------------------------------------------------------------------------------------------------------
------------------------|
--DI = Dilation Buffer--|
------------------------|
signal DI_buf_012_en : std_logic:='0';
signal buf_dilation_cc_en : std_logic:='0';
signal DIB_buf_en : std_logic:='0';

--type Array_Sobel_buf is array (integer range 0 to 639) of std_logic_vector ((8-1) downto 0);
signal DI_buf_0 : Array_Sobel_buf;
signal DI_buf_0_data_1 : std_logic_vector((10-1) downto 0):="0000000000";
signal DI_buf_0_data_2 : std_logic_vector((10-1) downto 0):="0000000000";
signal DI_buf_0_data_3 : std_logic_vector((10-1) downto 0):="0000000000";

signal DI_buf_1 : Array_Sobel_buf;
signal DI_buf_1_data_1 : std_logic_vector((10-1) downto 0):="0000000000";
signal DI_buf_1_data_2 : std_logic_vector((10-1) downto 0):="0000000000";
signal DI_buf_1_data_3 : std_logic_vector((10-1) downto 0):="0000000000";

signal DI_buf_2 : Array_Sobel_buf;
signal DI_buf_2_data_1 : std_logic_vector((10-1) downto 0):="0000000000";
signal DI_buf_2_data_2 : std_logic_vector((10-1) downto 0):="0000000000";
signal DI_buf_2_data_3 : std_logic_vector((10-1) downto 0):="0000000000";

signal DI_buf_3 : Array_Sobel_buf;
signal DI_buf_3_data_1 : std_logic_vector((10-1) downto 0):="0000000000";
signal DI_buf_3_data_2 : std_logic_vector((10-1) downto 0):="0000000000";
signal DI_buf_3_data_3 : std_logic_vector((10-1) downto 0):="0000000000";

signal DI_buf_4 : Array_Sobel_buf;
signal DI_buf_4_data_1 : std_logic_vector((10-1) downto 0):="0000000000";
signal DI_buf_4_data_2 : std_logic_vector((10-1) downto 0):="0000000000";
signal DI_buf_4_data_3 : std_logic_vector((10-1) downto 0):="0000000000";

signal DI_buf_in_data : std_logic_vector((8-1) downto 0):="00000000";
signal DI_buf_cnt : integer range 0 to 639:=0;
signal DI_buf_cnt_max : integer range 0 to 639:=639; --0~639

signal DI_XSCR : std_logic_vector((10-1) downto 0):="0000000000";
signal DI_YSCR : std_logic_vector((10-1) downto 0):="0000000000";
signal DI_CRB_data : std_logic:='0';
----------|
--DI End--|
----------|

--------------------------------|
--DIB = Dilation Binary Buffer--|
--------------------------------|
signal DIB_buf_out_data : std_logic_vector((8-1) downto 0):="00000000";
signal DIB_buf_cnt : integer range 0 to 38400-1:=0;
signal DIB_buf_cnt_max : integer range 0 to 38400-1:=38400-1;
signal DIB_data_delay_1 : std_logic_vector((8-1) downto 0):="00000000";
signal DIB_data_delay_2 : std_logic_vector((8-1) downto 0):="00000000";
signal DIB_data_delay_3 : std_logic_vector((8-1) downto 0):="00000000";
signal DIB_data_delay_4 : std_logic_vector((8-1) downto 0):="00000000";
signal DIB_data_delay_5 : std_logic_vector((8-1) downto 0):="00000000";
-----------|
--DIB End--|
-----------|

--type Array_mouse_buf is ARRAY (integer range 0 to 639) of std_logic_vector(479 downto 0);
--signal mouse_buf_is0, mouse_buf_is1 : Array_mouse_buf;

----------------------|
--YAB = Y AVG Buffer--|
----------------------|
type Array_YAB_buf is ARRAY (integer range 0 to 639) of std_logic_vector(7 downto 0);
signal YAB_buf_1 : Array_YAB_buf;
signal YAB_buf_1_in_cnt : integer range 0 to 639:=0;
signal YAB_buf_1_out_cnt : integer range 0 to 639:=0;
signal YAB_buf_1_data : std_logic_vector(7 downto 0):="00000000";

signal YAB_buf_2 : Array_YAB_buf;
signal YAB_buf_2_in_cnt : integer range 0 to 639:=0;
signal YAB_buf_2_out_cnt : integer range 0 to 639:=0;
signal YAB_buf_2_data : std_logic_vector(7 downto 0):="00000000";

signal YAB_XA_cnt : integer range 1 to 4:=1;
signal YAB_YA_cnt : integer range 1 to 4:=1;

signal YAB_X_data_1 : std_logic_vector(7 downto 0):="00000000";
signal YAB_X_data_2 : std_logic_vector(7 downto 0):="00000000";
signal YAB_X_data_3 : std_logic_vector(7 downto 0):="00000000";
signal YAB_X_data_4 : std_logic_vector(7 downto 0):="00000000";
signal YAB_buf_en : std_logic:='0';
signal YAB_buf_cnt_max : integer range 0 to 639:=639;
-----------|
--YAB End--|
-----------|

---------------------------------|
--CRB = Calculate Result Buffer--|
---------------------------------|
type Array_CRB_buf is ARRAY (integer range 0 to 639) of std_logic;
type Array_FV_buf is ARRAY (integer range 0 to 639) of std_logic_vector(11 downto 0);

signal CRB_buf_in_cnt : integer range 0 to 639:=639;
signal CRB_buf_out_cnt : integer range 0 to 639:=0;

signal CRB_FVbuf_in_cnt : integer range 0 to 639:=639;
signal CRB_FVbuf_out_cnt : integer range 0 to 639:=0;

signal CRB_Cb_en : std_logic:='0';
signal CRB_Cr_en : std_logic:='0';

signal CRB_MDF_buf : Array_CRB_buf;
signal CRB_MDF_buf_data : std_logic:='0';


signal CRB_Cb_buf : Array_CRB_buf;
signal CRB_Cr_buf : Array_CRB_buf;
signal CRB_skin_buf : Array_CRB_buf;
signal CRB_skin_buf_2 : Array_CRB_buf;
signal CRB_vga_buf : Array_CRB_buf;
signal CRB_vga_buf_2 : Array_CRB_buf;
signal CRB_skin_buf_data : std_logic:='0';
signal CRB_skin_buf_data_2 : std_logic:='0';
signal CRB_vga_buf_data : std_logic:='0';
signal CRB_vga_buf_data_2 : std_logic:='0';
signal CRB_vga_buf_data_cnt : integer range 0 to 8000:=0;
signal CRB_vga_buf_data_cnt_2 : integer range 0 to 8000:=0;
signal CRB_vga_buf_data_car_TF :std_logic:='0';
signal CRB_vga_buf_data_car_TF_2 :std_logic:='0';
signal CRB_vga_buf_data_car_TF_debug : std_logic_vector(2 downto 0);

signal CRB_white_buf : Array_CRB_buf;
signal CRB_white_buf_2 : Array_CRB_buf;
signal CRB_white_buf_data : std_logic:='0';
signal CRB_white_buf_data_2 : std_logic:='0';


--signal car_M_Y_ST_cnt : integer range 0 to 10:=0;
signal car_M_Y_ST : std_logic:='0';
signal car_M_Y_ST_2 : std_logic:='0';

signal CRB_Sobel_buf : Array_CRB_buf;
signal CRB_Sobel_buf_data : std_logic:='0';

signal CRB_FV_buf : Array_FV_buf;
signal CRB_FV_buf_data : std_logic_vector(11 downto 0);
signal CRB_FV_buf_data_T : std_logic:='0';

signal CRB_Erosion_buf : Array_CRB_buf;
signal CRB_Erosion_buf_data : std_logic:='0';

signal CRB_Dilation_buf : Array_CRB_buf;
signal CRB_Dilation_buf_data : std_logic:='0';

signal CRB_SF_buf : Array_CRB_buf;
signal CRB_SF_buf_data : std_logic:='0';

signal CRB_buf_cnt_max : integer range 0 to 639:=639;

type Array_YYY_buf is ARRAY (integer range 0 to 639) of std_logic_vector(7 downto 0);
signal CRB_YYY_buf : Array_YYY_buf;

-----------|
--CRB End--|
-----------|


signal box_size : integer range 0 to 100;


component BRAM
	port (
	clka: IN std_logic;
	dina: IN std_logic_VECTOR(7 downto 0);
	addra: IN std_logic_VECTOR(15 downto 0);
	ena: IN std_logic;
	wea: IN std_logic_VECTOR(0 downto 0);
	douta: OUT std_logic_VECTOR(7 downto 0));
end component;

signal dina : std_logic_VECTOR(7 downto 0):="00000000";
signal douta : std_logic_VECTOR(7 downto 0):="00000000";
signal wea : std_logic_VECTOR(0 downto 0):="0";
signal ena : std_logic:='0';
signal addra : std_logic_VECTOR(15 downto 0):="0000000000000000";




--------------------------------------------FULL-Color--------------------------------------------------------------------------

signal start_video_cnt : std_logic_vector(15 downto 0);
signal clk_video_cnt : std_logic_vector(1 downto 0);
signal clk_video_in : std_logic:='0';

type Array_Y_color is ARRAY (integer range 0 to 639) of std_logic_vector(7 downto 0);
signal buf_vga_Y_color : Array_Y_color;
signal buf_vga_Y_color_in_cnt : integer range 0 to 639:=0;
signal buf_vga_Y_color_out_cnt : integer range 0 to 639:=639;

---------------------------------------------------------------------------------------------------------
-------------00000000-------------0-----------000------000-----------------------------------------------
-----------000------000----------000----------000------000-----------------------------------------------
-----------000------------------00000---------000------000-----------------------------------------------
------------000----------------000-000--------000------000-----------------------------------------------
--------------0000000---------000---000-------000000000000-----------------------------------------------
--------------------000------00000000000------000000000000-----------------------------------------------
---------------------000----0000000000000-----000------000-----------------------------------------------
-----------000------000----000---------000----000------000-----------------------------------------------
------------0000000000----000-----------000---000------000-----------------------------------------------
---------------------------------------------------------------------------------------------------------

--Motion point average system by Chueh-Han Lo 20121226---------------------------------------------------------------------------------------------------------
-- MPAS = Motion point average system : 
signal MP_U_final : integer range 0 to 480 :=0;
signal MP_D_final : integer range 0 to 480 :=0;
signal MP_L_final : integer range 0 to 640 :=0;
signal MP_R_final : integer range 0 to 640 :=0;

signal MP_U : integer range 0 to 480 :=0;
signal MP_D : integer range 0 to 480 :=0;
signal MP_L : integer range 0 to 640 :=0;
signal MP_R : integer range 0 to 640 :=0;
signal MP_U_cnt : integer range 0 to 480 :=0;
signal MP_D_cnt : integer range 0 to 480 :=0;
signal MP_L_cnt : integer range 0 to 640 :=0;
signal MP_R_cnt : integer range 0 to 640 :=0;
signal MP_U_trace_cnt : integer range 0 to 480 :=0;
signal MP_D_trace_cnt : integer range 0 to 480 :=0;
signal MP_L_trace_cnt : integer range 0 to 640 :=0;
signal MP_R_trace_cnt : integer range 0 to 640 :=0;

signal MP_U_22 : integer range 0 to 480 :=0;
signal MP_D_22 : integer range 0 to 480 :=0;
signal MP_L_22 : integer range 0 to 640 :=0;
signal MP_R_22 : integer range 0 to 640 :=0;
signal MP_U_cnt_22 : integer range 0 to 480 :=0;
signal MP_D_cnt_22 : integer range 0 to 480 :=0;
signal MP_L_cnt_22 : integer range 0 to 640 :=0;
signal MP_R_cnt_22 : integer range 0 to 640 :=0;
signal MP_U_trace_cnt_22 : integer range 0 to 480 :=0;
signal MP_D_trace_cnt_22 : integer range 0 to 480 :=0; 
signal MP_L_trace_cnt_22 : integer range 0 to 640 :=0;
signal MP_R_trace_cnt_22 : integer range 0 to 640 :=0;

signal MPAS_brightness : STD_LOGIC;
signal MPAS_brightness_cnt : integer range 0 to 25600 :=0;
signal MPAS_brightness_cnt1 : integer range 0 to 12800 :=0;
signal MPAS_brightness_state : integer range 0 to 2 :=0;

signal MPAS_squarelight_cnt_0 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_1 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_2 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_3 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_4 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_5 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_6 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_7 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_8 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_9 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_10 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_11 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_12 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_13 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_14 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_15 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_16 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_17 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_18 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_19 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_20 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_21 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_22 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_23 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_24 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_25 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_26 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_27 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_28 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_29 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_30 : integer range 0 to 800 :=0;
signal MPAS_squarelight_cnt_31 : integer range 0 to 800 :=0;

signal MPAS_squarelight_0 : STD_LOGIC;
signal MPAS_squarelight_1 : STD_LOGIC;
signal MPAS_squarelight_2 : STD_LOGIC;
signal MPAS_squarelight_3 : STD_LOGIC;
signal MPAS_squarelight_4 : STD_LOGIC;
signal MPAS_squarelight_5 : STD_LOGIC;
signal MPAS_squarelight_6 : STD_LOGIC;
signal MPAS_squarelight_7 : STD_LOGIC;
signal MPAS_squarelight_8 : STD_LOGIC;
signal MPAS_squarelight_9 : STD_LOGIC;
signal MPAS_squarelight_10 : STD_LOGIC;
signal MPAS_squarelight_11 : STD_LOGIC;
signal MPAS_squarelight_12 : STD_LOGIC;
signal MPAS_squarelight_13 : STD_LOGIC;
signal MPAS_squarelight_14 : STD_LOGIC;
signal MPAS_squarelight_15 : STD_LOGIC;
signal MPAS_squarelight_16 : STD_LOGIC;
signal MPAS_squarelight_17 : STD_LOGIC;
signal MPAS_squarelight_18 : STD_LOGIC;
signal MPAS_squarelight_19 : STD_LOGIC;
signal MPAS_squarelight_20 : STD_LOGIC;
signal MPAS_squarelight_21 : STD_LOGIC;
signal MPAS_squarelight_22 : STD_LOGIC;
signal MPAS_squarelight_23 : STD_LOGIC;
signal MPAS_squarelight_24 : STD_LOGIC;
signal MPAS_squarelight_25 : STD_LOGIC;
signal MPAS_squarelight_26 : STD_LOGIC;
signal MPAS_squarelight_27 : STD_LOGIC;
signal MPAS_squarelight_28 : STD_LOGIC;
signal MPAS_squarelight_29 : STD_LOGIC;
signal MPAS_squarelight_30 : STD_LOGIC;
signal MPAS_squarelight_31 : STD_LOGIC;

signal squarelight_1 : std_logic_vector(7 downto 0);
signal squarelight_2 : std_logic_vector(7 downto 0);
signal standing_1 : std_logic_vector(7 downto 0);
signal standing_2 : std_logic_vector(7 downto 0);



signal squarelight_state  : integer range 0 to 16 :=0;

signal squarelight_left  : integer range 0 to 16 :=0;
signal squarelight_right : integer range 0 to 16 :=0;
signal ledarray_left  : integer range 0 to 16 :=0;
signal ledarray_right : integer range 0 to 16 :=0;

signal ledarrayscan_D : std_logic_vector(7 downto 0);

signal MPAS_square_range_cnt : integer range 0 to 79 :=0;
signal MPAS_square_cnt : integer range 0 to 7 :=0;

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
--
--component fpga_to_arduino
--	port (
--			clk : in std_logic;
--			clk_in : in std_logic;
--			rst : in std_logic;
--			data_out : out std_logic;
--			data_in : in std_logic_vector(31 downto 0)	);
--end component;
--signal data_in : std_logic_vector(31 downto 0);
--
--
begin
--
--fpga_to_arduino_T : fpga_to_arduino
--		port map (
--			clk => clk_video , --change here
--			clk_in => clk_in,
--			rst => rst_system, --change here
--			data_out => data_out,
--			data_in => code1 -- change here
--			);
----------------------------------------------------------------------
----- SAH begin ------------------------------------------------------
----------------------------------------------------------------------
-----------------brightness---------------------------------
process(rst_system,clk_video)--MPAS_brightness_cnt
begin
	if rst_system = '0' then
		MPAS_brightness_cnt <= 0;
		MPAS_brightness_state <= 0;
		MPAS_brightness_cnt1 <= 0;
		
	elsif rising_edge(clk_video) then
		if (f_video_en = '0' and black_vga_en = '0') then
			if ( cnt_h_sync_vga > 0 and cnt_h_sync_vga < 640 and cnt_v_sync_vga > 0 and cnt_v_sync_vga < 480) then
				if  ( CRB_vga_buf_data_2 ='1')then --or CRB_Skin_buf_data_2 ='1' ) or (MT_YS_data >= "00001010" or CRB_MDF_buf_data ='1')  then
					
					if ( cnt_h_sync_vga > 0 and cnt_h_sync_vga < 640 and cnt_v_sync_vga > 0 and cnt_v_sync_vga < 320) then
						if MPAS_brightness_cnt < 25600 then  --640*320/8 
							MPAS_brightness_cnt <= MPAS_brightness_cnt +1;
						else
							MPAS_brightness_cnt <= MPAS_brightness_cnt;
						end if;					
						
					elsif ( cnt_h_sync_vga > 0 and cnt_h_sync_vga < 640 and cnt_v_sync_vga > 320 and cnt_v_sync_vga < 480) then	
						if MPAS_brightness_cnt1 < 12800 then  --640*280/8 
							MPAS_brightness_cnt1 <= MPAS_brightness_cnt1 +1;
						else
							MPAS_brightness_cnt1 <= MPAS_brightness_cnt1;
						end if;
					end if;
					
					case MPAS_brightness_state is
						when 0 =>
							if MPAS_brightness_cnt < 5000 then
								MPAS_brightness_state <= 0;--brights light
							elsif MPAS_brightness_cnt > 5000 and MPAS_brightness_cnt < 20000 then
								MPAS_brightness_state <= 1;
							elsif MPAS_brightness_cnt > 20000 or MPAS_brightness_cnt1 > 5000 then
								MPAS_brightness_state <= 2;--regular light
							end if;	
						when 1 =>
							if MPAS_brightness_cnt < 5000 then
								MPAS_brightness_state <= 0;--brights light
							elsif MPAS_brightness_cnt > 5000 and MPAS_brightness_cnt < 20000 then
								MPAS_brightness_state <= 1;
							elsif MPAS_brightness_cnt > 20000 or MPAS_brightness_cnt1 > 5000 then
								MPAS_brightness_state <= 2;--regular light
							end if;							
						when 2=>
							if MPAS_brightness_cnt < 5000 then
								MPAS_brightness_state <= 0;--brights light
							elsif MPAS_brightness_cnt > 5000 and MPAS_brightness_cnt < 20000 then
								MPAS_brightness_state <= 1;
							elsif MPAS_brightness_cnt > 20000 or MPAS_brightness_cnt1 > 5000 then
								MPAS_brightness_state <= 2;--regular light
							end if;							
						when others=>null;
					end case;
				end if;
			elsif (cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480) then	
				MPAS_brightness_cnt <= 0;
				MPAS_brightness_cnt1 <= 0;
				
			end if;
        else
            MPAS_brightness_cnt <= 0;
            MPAS_brightness_state <= 0;
            MPAS_brightness_cnt1 <= 0;
		end if;
	end if;
end process;
-----------------brightness---------------------------------
------------------------------------------------------------
-------------------square range-----------------------------
process(rst_system,clk_video)--MPAS_square_cnt
begin
	if rst_system = '0' then
		MPAS_square_range_cnt <= 0;
		MPAS_square_cnt <= 0;
	elsif rising_edge(clk_video) then
		if (f_video_en = '0' and black_vga_en = '0') then
			if ( cnt_h_sync_vga > 0 and cnt_h_sync_vga < 640 and cnt_v_sync_vga > 0 and cnt_v_sync_vga < 480) then
				if MPAS_square_range_cnt < 79 then
					MPAS_square_range_cnt <= MPAS_square_range_cnt + 1;
				else
					MPAS_square_range_cnt <= 0;
					if MPAS_square_cnt < 7 then
						MPAS_square_cnt <= MPAS_square_cnt + 1;
					else
						MPAS_square_cnt <= 0;
					end if;
				end if;
			else
				MPAS_square_range_cnt <= 0;
				MPAS_square_cnt <= 0;
			end if;
        else
            MPAS_square_range_cnt <= 0;
            MPAS_square_cnt <= 0;
		end if;
	end if;
end process;	
-------------------square range-----------------------------
------------------------------------------------------------
-------------------squarelight------------------------------
process(rst_system,clk_video)
begin
	if rst_system = '0' then
		MPAS_squarelight_cnt_0 <= 0;
		MPAS_squarelight_cnt_1 <= 0;
		MPAS_squarelight_cnt_2 <= 0;
		MPAS_squarelight_cnt_3 <= 0;
		MPAS_squarelight_cnt_4 <= 0;
		MPAS_squarelight_cnt_5 <= 0;
		MPAS_squarelight_cnt_6 <= 0;
		MPAS_squarelight_cnt_7 <= 0;
		MPAS_squarelight_cnt_8 <= 0;
		MPAS_squarelight_cnt_9 <= 0;
		MPAS_squarelight_cnt_10 <= 0;
		MPAS_squarelight_cnt_11 <= 0;
		MPAS_squarelight_cnt_12 <= 0;
		MPAS_squarelight_cnt_13 <= 0;
		MPAS_squarelight_cnt_14 <= 0;
		MPAS_squarelight_cnt_15 <= 0;
		MPAS_squarelight_cnt_16 <= 0;
		MPAS_squarelight_cnt_17 <= 0;
		MPAS_squarelight_cnt_18 <= 0;
		MPAS_squarelight_cnt_19 <= 0;
		MPAS_squarelight_cnt_20 <= 0;
		MPAS_squarelight_cnt_21 <= 0;
		MPAS_squarelight_cnt_22 <= 0;
		MPAS_squarelight_cnt_23 <= 0;
		MPAS_squarelight_cnt_24 <= 0;
		MPAS_squarelight_cnt_25 <= 0;
		MPAS_squarelight_cnt_26 <= 0;
		MPAS_squarelight_cnt_27 <= 0;
		MPAS_squarelight_cnt_28 <= 0;
		MPAS_squarelight_cnt_29 <= 0;
		MPAS_squarelight_cnt_30 <= 0;
		MPAS_squarelight_cnt_31 <= 0;
--
		MPAS_squarelight_0 <= '0';
		MPAS_squarelight_1 <= '0';
		MPAS_squarelight_2 <= '0';
		MPAS_squarelight_3 <= '0';
		MPAS_squarelight_4 <= '0';
		MPAS_squarelight_5 <= '0';
		MPAS_squarelight_6 <= '0';
		MPAS_squarelight_7 <= '0';
		MPAS_squarelight_8 <= '0';
		MPAS_squarelight_9 <= '0';
		MPAS_squarelight_10 <= '0';
		MPAS_squarelight_11 <= '0';
		MPAS_squarelight_12 <= '0';
		MPAS_squarelight_13 <= '0';
		MPAS_squarelight_14 <= '0';
		MPAS_squarelight_15 <= '0';
		MPAS_squarelight_16 <= '0';
		MPAS_squarelight_17 <= '0';
		MPAS_squarelight_18 <= '0';
		MPAS_squarelight_19 <= '0';
		MPAS_squarelight_20 <= '0';
		MPAS_squarelight_21 <= '0';
		MPAS_squarelight_22 <= '0';
		MPAS_squarelight_23 <= '0';
		MPAS_squarelight_24 <= '0';
		MPAS_squarelight_25 <= '0';
		MPAS_squarelight_26 <= '0';
		MPAS_squarelight_27 <= '0';
		MPAS_squarelight_28 <= '0';
		MPAS_squarelight_29 <= '0';
		MPAS_squarelight_30 <= '0';
		MPAS_squarelight_31 <= '0';
		
--		code1 <= "00000000000000000000000000000000"; 

--		squarelight_1 <= "00000000";
--		squarelight_2 <= "00000000";
--		squarelight_3 <= "00000000";
--		squarelight_4 <= "00000000";
		
		squarelight_left  <= 0;
		squarelight_right <= 0;
	elsif rising_edge(clk_video) then
		if (f_video_en = '0' and black_vga_en = '0') then
			if ( cnt_h_sync_vga > 0 and cnt_h_sync_vga < 640 and cnt_v_sync_vga > 0 and cnt_v_sync_vga < 480) then
				if  ( CRB_vga_buf_data_2 ='1') then-- or CRB_Skin_buf_data_2 ='1' ) or (MT_YS_data >= "00001010" or CRB_MDF_buf_data ='1')  then

					if  cnt_v_sync_vga > 0 and cnt_v_sync_vga < 80 then
						case MPAS_square_cnt is
							when 0 =>
								if MPAS_squarelight_cnt_0 < 800 then
									MPAS_squarelight_cnt_0 <= MPAS_squarelight_cnt_0 + 1;
									if MPAS_squarelight_cnt_0 > 640 then 
										MPAS_squarelight_0 <= '1';
										code1(0) <= '1';
										squarelight_left <= squarelight_left + 1;
									else
										MPAS_squarelight_0 <= '0';
										code1(0) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_0 <= MPAS_squarelight_cnt_0;
								end if;							
							when 1 =>
								if MPAS_squarelight_cnt_1 < 800 then
									MPAS_squarelight_cnt_1 <= MPAS_squarelight_cnt_1 + 1;
									if MPAS_squarelight_cnt_1 > 640 then 
										MPAS_squarelight_1 <= '1';
										code1(1) <= '1';
										squarelight_left <= squarelight_left + 1;
									else
										MPAS_squarelight_1 <= '0';
										code1(1) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_1 <= MPAS_squarelight_cnt_1;
								end if;							
							when 2 =>
								if MPAS_squarelight_cnt_2 < 800 then
									MPAS_squarelight_cnt_2 <= MPAS_squarelight_cnt_2 + 1;
									if MPAS_squarelight_cnt_2 > 640 then 
										MPAS_squarelight_2 <= '1';
--										code1(2) <= '1';
										squarelight_left <= squarelight_left + 1;
									else
										MPAS_squarelight_2 <= '0';
--										code1(2) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_2 <= MPAS_squarelight_cnt_2;
								end if;							
							when 3 =>
								if MPAS_squarelight_cnt_3 < 800 then
									MPAS_squarelight_cnt_3 <= MPAS_squarelight_cnt_3 + 1;
									if MPAS_squarelight_cnt_3 > 640 then 
										MPAS_squarelight_3 <= '1';
										code1(3) <= '1';
										squarelight_left <= squarelight_left + 1;
									else
										MPAS_squarelight_3 <= '0';
										code1(3) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_3 <= MPAS_squarelight_cnt_3;
								end if;							
							when 4 =>
								if MPAS_squarelight_cnt_4 < 800 then
									MPAS_squarelight_cnt_4 <= MPAS_squarelight_cnt_4 + 1;
									if MPAS_squarelight_cnt_4 > 640 then 
										MPAS_squarelight_4 <= '1';
										code1(4) <= '1';
										squarelight_right <= squarelight_right + 1;
									else
										MPAS_squarelight_4 <= '0';
										code1(4) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_4 <= MPAS_squarelight_cnt_4;
								end if;							
							when 5 =>
								if MPAS_squarelight_cnt_5 < 800 then
									MPAS_squarelight_cnt_5 <= MPAS_squarelight_cnt_5 + 1;
									if MPAS_squarelight_cnt_5 > 640 then 
										MPAS_squarelight_5 <= '1';
										code1(5) <= '1';
										squarelight_right <= squarelight_right + 1;
									else
										MPAS_squarelight_5 <= '0';
										code1(5) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_5 <= MPAS_squarelight_cnt_5;
								end if;							
							when 6 =>
								if MPAS_squarelight_cnt_6 < 800 then
									MPAS_squarelight_cnt_6 <= MPAS_squarelight_cnt_6 + 1;
									if MPAS_squarelight_cnt_6 > 640 then 
										MPAS_squarelight_6 <= '1';
										code1(6) <= '1';
										squarelight_right <= squarelight_right + 1;
									else
										MPAS_squarelight_6 <= '0';
										code1(6) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_6 <= MPAS_squarelight_cnt_6;
								end if;							
							when 7 =>
								if MPAS_squarelight_cnt_7 < 800 then
									MPAS_squarelight_cnt_7 <= MPAS_squarelight_cnt_7 + 1;
									if MPAS_squarelight_cnt_7 > 640 then 
										MPAS_squarelight_7 <= '1';
										code1(7) <= '1';
										squarelight_right <= squarelight_right + 1;
									else
										MPAS_squarelight_7 <= '0';
										code1(7) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_7 <= MPAS_squarelight_cnt_7;
								end if;							
							when others => null;
						end case;	
			
					elsif  cnt_v_sync_vga > 80 and cnt_v_sync_vga < 160 then
						case MPAS_square_cnt is
							when 0 =>
								if MPAS_squarelight_cnt_8 < 800 then
									MPAS_squarelight_cnt_8 <= MPAS_squarelight_cnt_8 + 1;
									if MPAS_squarelight_cnt_8 > 640 then 
										MPAS_squarelight_8 <= '1';
										code1(8) <= '1';
										squarelight_left <= squarelight_left + 1;
									else
										MPAS_squarelight_8 <= '0';
										code1(8) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_8 <= MPAS_squarelight_cnt_8;
								end if;							
							when 1 =>
								if MPAS_squarelight_cnt_9 < 800 then
									MPAS_squarelight_cnt_9 <= MPAS_squarelight_cnt_9 + 1;
									if MPAS_squarelight_cnt_9 > 640 then 
										MPAS_squarelight_9 <= '1';
										code1(9) <= '1';
										squarelight_left <= squarelight_left + 1;
									else
										MPAS_squarelight_9 <= '0';
										code1(9) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_9 <= MPAS_squarelight_cnt_9;
								end if;							
							when 2 =>
								if MPAS_squarelight_cnt_10 < 800 then
									MPAS_squarelight_cnt_10 <= MPAS_squarelight_cnt_10 + 1;
									if MPAS_squarelight_cnt_10 > 640 then 
										MPAS_squarelight_10 <= '1';
										code1(10) <= '1';
										squarelight_left <= squarelight_left + 1;
									else
										MPAS_squarelight_10 <= '0';
										code1(10) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_10 <= MPAS_squarelight_cnt_10;
								end if;							
							when 3 =>
								if MPAS_squarelight_cnt_11 < 800 then
									MPAS_squarelight_cnt_11 <= MPAS_squarelight_cnt_11 + 1;
									if MPAS_squarelight_cnt_11 > 640 then 
										MPAS_squarelight_11 <= '1';
										code1(11) <= '1';
										squarelight_left <= squarelight_left + 1;
									else
										MPAS_squarelight_11 <= '0';
										code1(11) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_11 <= MPAS_squarelight_cnt_11;
								end if;							
							when 4 =>
								if MPAS_squarelight_cnt_12 < 800 then
									MPAS_squarelight_cnt_12 <= MPAS_squarelight_cnt_12 + 1;
									if MPAS_squarelight_cnt_12 > 640 then 
										MPAS_squarelight_12 <= '1';
										code1(12) <= '1';
										squarelight_right <= squarelight_right + 1;
									else
										MPAS_squarelight_12 <= '0';
										code1(12) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_12 <= MPAS_squarelight_cnt_12;
								end if;							
							when 5 =>
								if MPAS_squarelight_cnt_13 < 800 then
									MPAS_squarelight_cnt_13 <= MPAS_squarelight_cnt_13 + 1;
									if MPAS_squarelight_cnt_13 > 640 then 
										MPAS_squarelight_13 <= '1';
										code1(13) <= '1';
										squarelight_right <= squarelight_right + 1;
									else
										MPAS_squarelight_13 <= '0';
										code1(13) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_13 <= MPAS_squarelight_cnt_13;
								end if;							
							when 6 =>
								if MPAS_squarelight_cnt_14 < 800 then
									MPAS_squarelight_cnt_14 <= MPAS_squarelight_cnt_14 + 1;
									if MPAS_squarelight_cnt_14 > 640 then 
										MPAS_squarelight_14 <= '1';
										code1(14) <= '1';
										squarelight_right <= squarelight_right + 1;
									else
										MPAS_squarelight_14 <= '0';
										code1(14) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_14 <= MPAS_squarelight_cnt_14;
								end if;							
							when 7 =>
								if MPAS_squarelight_cnt_15 < 800 then
									MPAS_squarelight_cnt_15 <= MPAS_squarelight_cnt_15 + 1;
									if MPAS_squarelight_cnt_15 > 640 then 
										MPAS_squarelight_15 <= '1';
										code1(15) <= '1';
										squarelight_right <= squarelight_right + 1;
									else
										MPAS_squarelight_15 <= '0';
										code1(15) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_15 <= MPAS_squarelight_cnt_15;
								end if;							
							when others => null;
						end case;	
			
					elsif cnt_v_sync_vga > 160 and cnt_v_sync_vga < 240 then
						case MPAS_square_cnt is
							when 0 =>
								if MPAS_squarelight_cnt_16 < 800 then
									MPAS_squarelight_cnt_16 <= MPAS_squarelight_cnt_16 + 1;
									if MPAS_squarelight_cnt_16 > 640 then 
										MPAS_squarelight_16 <= '1';
										code1(16) <= '1';
										squarelight_left <= squarelight_left + 1;
									else
										MPAS_squarelight_16 <= '0';
										code1(16) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_16 <= MPAS_squarelight_cnt_16;
								end if;							
							when 1 =>
								if MPAS_squarelight_cnt_17 < 800 then
									MPAS_squarelight_cnt_17 <= MPAS_squarelight_cnt_17 + 1;
									if MPAS_squarelight_cnt_17 > 640 then 
										MPAS_squarelight_17 <= '1';
										code1(17) <= '1';
										squarelight_left <= squarelight_left + 1;
									else
										MPAS_squarelight_17 <= '0';
										code1(17) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_17 <= MPAS_squarelight_cnt_17;
								end if;							
							when 2 =>
								if MPAS_squarelight_cnt_18 < 800 then
									MPAS_squarelight_cnt_18 <= MPAS_squarelight_cnt_18 + 1;
									if MPAS_squarelight_cnt_18 > 640 then 
										MPAS_squarelight_18 <= '1';
										code1(18) <= '1';
										squarelight_left <= squarelight_left + 1;
									else
										MPAS_squarelight_18 <= '0';
										code1(18) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_18 <= MPAS_squarelight_cnt_18;
								end if;							
							when 3 =>
								if MPAS_squarelight_cnt_19 < 800 then
									MPAS_squarelight_cnt_19 <= MPAS_squarelight_cnt_19 + 1;
									if MPAS_squarelight_cnt_19 > 640 then 
										MPAS_squarelight_19 <= '1';
										code1(19) <= '1';
										squarelight_left <= squarelight_left + 1;
									else
										MPAS_squarelight_19 <= '0';
										code1(19) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_19 <= MPAS_squarelight_cnt_19;
								end if;							
							when 4 =>
								if MPAS_squarelight_cnt_20 < 800 then
									MPAS_squarelight_cnt_20 <= MPAS_squarelight_cnt_20 + 1;
									if MPAS_squarelight_cnt_20 > 640 then 
										MPAS_squarelight_20 <= '1';
										code1(20) <= '1';
										squarelight_right <= squarelight_right + 1;
									else
										MPAS_squarelight_20 <= '0';
										code1(20) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_20 <= MPAS_squarelight_cnt_20;
								end if;							
							when 5 =>
								if MPAS_squarelight_cnt_21 < 800 then
									MPAS_squarelight_cnt_21 <= MPAS_squarelight_cnt_21 + 1;
									if MPAS_squarelight_cnt_21 > 640 then 
										MPAS_squarelight_21 <= '1';
										code1(21) <= '1';
										squarelight_right <= squarelight_right + 1;
									else
										MPAS_squarelight_21 <= '0';
										code1(21) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_21 <= MPAS_squarelight_cnt_21;
								end if;							
							when 6 =>
								if MPAS_squarelight_cnt_22 < 800 then
									MPAS_squarelight_cnt_22 <= MPAS_squarelight_cnt_22 + 1;
									if MPAS_squarelight_cnt_22 > 640 then 
										MPAS_squarelight_22 <= '1';
										code1(22) <= '1';
										squarelight_right <= squarelight_right + 1;
									else
										MPAS_squarelight_22 <= '0';
										code1(22) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_22 <= MPAS_squarelight_cnt_22;
								end if;							
							when 7 =>
								if MPAS_squarelight_cnt_23 < 800 then
									MPAS_squarelight_cnt_23 <= MPAS_squarelight_cnt_23 + 1;
									if MPAS_squarelight_cnt_23 > 640 then 
										MPAS_squarelight_23 <= '1';
										code1(23) <= '1';
										squarelight_right <= squarelight_right + 1;
									else
										MPAS_squarelight_23 <= '0';
										code1(23) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_23 <= MPAS_squarelight_cnt_23;
								end if;								
							when others => null;
						end case;	
					
					elsif cnt_v_sync_vga > 240 and cnt_v_sync_vga < 320 then
						case MPAS_square_cnt is
							when 0 =>
								if MPAS_squarelight_cnt_24 < 800 then
									MPAS_squarelight_cnt_24 <= MPAS_squarelight_cnt_24 + 1;
									if MPAS_squarelight_cnt_24 > 640 then 
										MPAS_squarelight_24 <= '1';
										code1(24) <= '1';
										squarelight_left <= squarelight_left + 1;
									else
										MPAS_squarelight_24 <= '0';
										code1(24) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_24 <= MPAS_squarelight_cnt_24;
								end if;							
							when 1 =>
								if MPAS_squarelight_cnt_25 < 800 then
									MPAS_squarelight_cnt_25 <= MPAS_squarelight_cnt_25 + 1;
									if MPAS_squarelight_cnt_25 > 640 then 
										MPAS_squarelight_25 <= '1';
										code1(25) <= '1';
										squarelight_left <= squarelight_left + 1;
									else
										MPAS_squarelight_25 <= '0';
										code1(25) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_25 <= MPAS_squarelight_cnt_25;
								end if;							
							when 2 =>
								if MPAS_squarelight_cnt_26 < 800 then
									MPAS_squarelight_cnt_26 <= MPAS_squarelight_cnt_26 + 1;
									if MPAS_squarelight_cnt_26 > 640 then 
										MPAS_squarelight_26 <= '1';
										code1(26) <= '1';
										squarelight_left <= squarelight_left + 1;
									else
										MPAS_squarelight_26 <= '0';
										code1(26) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_26 <= MPAS_squarelight_cnt_26;
								end if;							
							when 3 =>
								if MPAS_squarelight_cnt_27 < 800 then
									MPAS_squarelight_cnt_27 <= MPAS_squarelight_cnt_27 + 1;
									if MPAS_squarelight_cnt_27 > 640 then 
										MPAS_squarelight_27 <= '1';
										code1(27) <= '1';
										squarelight_left <= squarelight_left + 1;
									else
										MPAS_squarelight_27 <= '0';
										code1(27) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_27 <= MPAS_squarelight_cnt_27;
								end if;							
							when 4 =>
								if MPAS_squarelight_cnt_28 < 800 then
									MPAS_squarelight_cnt_28 <= MPAS_squarelight_cnt_28 + 1;
									if MPAS_squarelight_cnt_28 > 640 then 
										MPAS_squarelight_28 <= '1';
										code1(28) <= '1';
										squarelight_right <= squarelight_right + 1;
									else
										MPAS_squarelight_28 <= '0';
										code1(28) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_28 <= MPAS_squarelight_cnt_28;
								end if;							
							when 5 =>
								if MPAS_squarelight_cnt_29 < 800 then
									MPAS_squarelight_cnt_29 <= MPAS_squarelight_cnt_29 + 1;
									if MPAS_squarelight_cnt_29 > 640 then 
										MPAS_squarelight_29 <= '1';
										code1(29) <= '1';
										squarelight_right <= squarelight_right + 1;
									else
										MPAS_squarelight_29 <= '0';
										code1(29) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_29 <= MPAS_squarelight_cnt_29;
								end if;							
							when 6 =>
								if MPAS_squarelight_cnt_30 < 800 then
									MPAS_squarelight_cnt_30 <= MPAS_squarelight_cnt_30 + 1;
									if MPAS_squarelight_cnt_30 > 640 then 
										MPAS_squarelight_30 <= '1';
										code1(30) <= '1';
										squarelight_right <= squarelight_right + 1;
									else
										MPAS_squarelight_30 <= '0';
										code1(30) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_30 <= MPAS_squarelight_cnt_30;
								end if;							
							when 7 =>
								if MPAS_squarelight_cnt_31 < 800 then
									MPAS_squarelight_cnt_31 <= MPAS_squarelight_cnt_31 + 1;
									if MPAS_squarelight_cnt_31 > 640 then 
										MPAS_squarelight_31 <= '1';
										code1(31) <= '1';
										squarelight_right <= squarelight_right + 1;
									else
										MPAS_squarelight_31 <= '0';
										code1(31) <= '0';
									end if;	
								else
									MPAS_squarelight_cnt_31 <= MPAS_squarelight_cnt_31;
								end if;							
							when others => null;
						end case;
								
					end if;

				end if;
					
					
--					if ( cnt_h_sync_vga > 0 and cnt_h_sync_vga < 80 and cnt_v_sync_vga > 0 and cnt_v_sync_vga < 80) then
--						if MPAS_squarelight_cnt_0 < 800 then
--							MPAS_squarelight_cnt_0 <= MPAS_squarelight_cnt_0 + 1;
--							if MPAS_squarelight_cnt_0 > 640 then 
--								MPAS_squarelight_0 <= '1';
--							else
--								MPAS_squarelight_0 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_0 <= MPAS_squarelight_cnt_0;
--						end if;
--
--					elsif ( cnt_h_sync_vga > 80 and cnt_h_sync_vga < 160 and cnt_v_sync_vga > 0 and cnt_v_sync_vga < 80) then
--						if MPAS_squarelight_cnt_1 < 800 then
--							MPAS_squarelight_cnt_1 <= MPAS_squarelight_cnt_1 + 1;
--							if MPAS_squarelight_cnt_1 > 640 then 
--								MPAS_squarelight_1 <= '1';
--							else
--								MPAS_squarelight_1 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_1 <= MPAS_squarelight_cnt_1;
--						end if;
--						
--					elsif ( cnt_h_sync_vga > 160 and cnt_h_sync_vga < 240 and cnt_v_sync_vga > 0 and cnt_v_sync_vga < 80) then
--						if MPAS_squarelight_cnt_2 < 800 then
--							MPAS_squarelight_cnt_2 <= MPAS_squarelight_cnt_2 + 1;
--							if MPAS_squarelight_cnt_2 > 640 then 
--								MPAS_squarelight_2 <= '1';
--							else
--								MPAS_squarelight_2 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_2 <= MPAS_squarelight_cnt_2;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 240 and cnt_h_sync_vga < 320 and cnt_v_sync_vga > 0 and cnt_v_sync_vga < 80) then
--						if MPAS_squarelight_cnt_3 < 800 then
--							MPAS_squarelight_cnt_3 <= MPAS_squarelight_cnt_3 + 1;
--							if MPAS_squarelight_cnt_3 > 640 then 
--								MPAS_squarelight_3 <= '1';
--							else
--								MPAS_squarelight_3 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_3 <= MPAS_squarelight_cnt_3;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 320 and cnt_h_sync_vga < 400 and cnt_v_sync_vga > 0 and cnt_v_sync_vga < 80) then
--						if MPAS_squarelight_cnt_4 < 800 then
--							MPAS_squarelight_cnt_4 <= MPAS_squarelight_cnt_4 + 1;
--							if MPAS_squarelight_cnt_4 > 640 then 
--								MPAS_squarelight_4 <= '1';
--							else
--								MPAS_squarelight_4 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_4 <= MPAS_squarelight_cnt_4;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 400 and cnt_h_sync_vga < 480 and cnt_v_sync_vga > 0 and cnt_v_sync_vga < 80) then
--						if MPAS_squarelight_cnt_5 < 800 then
--							MPAS_squarelight_cnt_5 <= MPAS_squarelight_cnt_5 + 1;
--							if MPAS_squarelight_cnt_5 > 640 then 
--								MPAS_squarelight_5 <= '1';
--							else
--								MPAS_squarelight_5 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_5 <= MPAS_squarelight_cnt_5;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 480 and cnt_h_sync_vga < 560 and cnt_v_sync_vga > 0 and cnt_v_sync_vga < 80) then
--						if MPAS_squarelight_cnt_6 < 800 then
--							MPAS_squarelight_cnt_6 <= MPAS_squarelight_cnt_6 + 1;
--							if MPAS_squarelight_cnt_6 > 640 then 
--								MPAS_squarelight_6 <= '1';
--							else
--								MPAS_squarelight_6 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_6 <= MPAS_squarelight_cnt_6;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 560 and cnt_h_sync_vga < 640 and cnt_v_sync_vga > 0 and cnt_v_sync_vga < 80) then
--						if MPAS_squarelight_cnt_7 < 800 then
--							MPAS_squarelight_cnt_7 <= MPAS_squarelight_cnt_7 + 1;
--							if MPAS_squarelight_cnt_7 > 640 then 
--								MPAS_squarelight_7 <= '1';
--							else
--								MPAS_squarelight_7 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_7 <= MPAS_squarelight_cnt_7;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 0 and cnt_h_sync_vga < 80 and cnt_v_sync_vga > 80 and cnt_v_sync_vga < 160) then
--						if MPAS_squarelight_cnt_8 < 800 then
--							MPAS_squarelight_cnt_8 <= MPAS_squarelight_cnt_8 + 1;
--							if MPAS_squarelight_cnt_8 > 640 then 
--								MPAS_squarelight_8 <= '1';
--							else
--								MPAS_squarelight_8 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_8 <= MPAS_squarelight_cnt_8;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 80 and cnt_h_sync_vga < 160 and cnt_v_sync_vga > 80 and cnt_v_sync_vga < 160) then
--						if MPAS_squarelight_cnt_9 < 800 then
--							MPAS_squarelight_cnt_9 <= MPAS_squarelight_cnt_9 + 1;
--							if MPAS_squarelight_cnt_9 > 640 then 
--								MPAS_squarelight_9 <= '1';
--							else
--								MPAS_squarelight_9 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_9 <= MPAS_squarelight_cnt_9;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 160 and cnt_h_sync_vga < 240 and cnt_v_sync_vga > 80 and cnt_v_sync_vga < 160) then
--						if MPAS_squarelight_cnt_10 < 800 then
--							MPAS_squarelight_cnt_10 <= MPAS_squarelight_cnt_10 + 1;
--							if MPAS_squarelight_cnt_10 > 640 then 
--								MPAS_squarelight_10 <= '1';
--							else
--								MPAS_squarelight_10 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_10 <= MPAS_squarelight_cnt_10;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 240 and cnt_h_sync_vga < 320 and cnt_v_sync_vga > 80 and cnt_v_sync_vga < 160) then
--						if MPAS_squarelight_cnt_11 < 800 then
--							MPAS_squarelight_cnt_11 <= MPAS_squarelight_cnt_11 + 1;
--							if MPAS_squarelight_cnt_11 > 640 then 
--								MPAS_squarelight_11 <= '1';
--							else
--								MPAS_squarelight_11 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_11 <= MPAS_squarelight_cnt_11;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 320 and cnt_h_sync_vga < 400 and cnt_v_sync_vga > 80 and cnt_v_sync_vga < 160) then
--						if MPAS_squarelight_cnt_12 < 800 then
--							MPAS_squarelight_cnt_12 <= MPAS_squarelight_cnt_12 + 1;
--							if MPAS_squarelight_cnt_12 > 640 then 
--								MPAS_squarelight_12 <= '1';
--							else
--								MPAS_squarelight_12 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_12 <= MPAS_squarelight_cnt_12;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 400 and cnt_h_sync_vga < 480 and cnt_v_sync_vga > 80 and cnt_v_sync_vga < 160) then
--						if MPAS_squarelight_cnt_13 < 800 then
--							MPAS_squarelight_cnt_13 <= MPAS_squarelight_cnt_13 + 1;
--							if MPAS_squarelight_cnt_13 > 640 then 
--								MPAS_squarelight_13 <= '1';
--							else
--								MPAS_squarelight_13 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_13 <= MPAS_squarelight_cnt_13;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 480 and cnt_h_sync_vga < 560 and cnt_v_sync_vga > 80 and cnt_v_sync_vga < 160) then
--						if MPAS_squarelight_cnt_14 < 800 then
--							MPAS_squarelight_cnt_14 <= MPAS_squarelight_cnt_14 + 1;
--							if MPAS_squarelight_cnt_14 > 640 then 
--								MPAS_squarelight_14 <= '1';
--							else
--								MPAS_squarelight_14 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_14 <= MPAS_squarelight_cnt_14;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 560 and cnt_h_sync_vga < 640 and cnt_v_sync_vga > 80 and cnt_v_sync_vga < 160) then
--						if MPAS_squarelight_cnt_15 < 800 then
--							MPAS_squarelight_cnt_15 <= MPAS_squarelight_cnt_15 + 1;
--							if MPAS_squarelight_cnt_15 > 640 then 
--								MPAS_squarelight_15 <= '1';
--							else
--								MPAS_squarelight_15 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_15 <= MPAS_squarelight_cnt_15;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 0 and cnt_h_sync_vga < 80 and cnt_v_sync_vga > 160 and cnt_v_sync_vga < 240) then
--						if MPAS_squarelight_cnt_16 < 800 then
--							MPAS_squarelight_cnt_16 <= MPAS_squarelight_cnt_16 + 1;
--							if MPAS_squarelight_cnt_16 > 640 then 
--								MPAS_squarelight_16 <= '1';
--							else
--								MPAS_squarelight_16 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_16 <= MPAS_squarelight_cnt_16;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 80 and cnt_h_sync_vga < 160 and cnt_v_sync_vga > 160 and cnt_v_sync_vga < 240) then
--						if MPAS_squarelight_cnt_17 < 800 then
--							MPAS_squarelight_cnt_17 <= MPAS_squarelight_cnt_17 + 1;
--							if MPAS_squarelight_cnt_17 > 640 then 
--								MPAS_squarelight_17 <= '1';
--							else
--								MPAS_squarelight_17 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_17 <= MPAS_squarelight_cnt_17;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 160 and cnt_h_sync_vga < 240 and cnt_v_sync_vga > 160 and cnt_v_sync_vga < 240) then
--						if MPAS_squarelight_cnt_18 < 800 then
--							MPAS_squarelight_cnt_18 <= MPAS_squarelight_cnt_18 + 1;
--							if MPAS_squarelight_cnt_18 > 640 then 
--								MPAS_squarelight_18 <= '1';
--							else
--								MPAS_squarelight_18 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_18 <= MPAS_squarelight_cnt_18;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 240 and cnt_h_sync_vga < 320 and cnt_v_sync_vga > 160 and cnt_v_sync_vga < 240) then
--						if MPAS_squarelight_cnt_19 < 800 then
--							MPAS_squarelight_cnt_19 <= MPAS_squarelight_cnt_19 + 1;
--							if MPAS_squarelight_cnt_19 > 640 then 
--								MPAS_squarelight_19 <= '1';
--							else
--								MPAS_squarelight_19 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_19 <= MPAS_squarelight_cnt_19;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 320 and cnt_h_sync_vga < 400 and cnt_v_sync_vga > 160 and cnt_v_sync_vga < 240) then
--						if MPAS_squarelight_cnt_20 < 800 then
--							MPAS_squarelight_cnt_20 <= MPAS_squarelight_cnt_20 + 1;
--							if MPAS_squarelight_cnt_20 > 640 then 
--								MPAS_squarelight_20 <= '1';
--							else
--								MPAS_squarelight_20 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_20 <= MPAS_squarelight_cnt_20;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 400 and cnt_h_sync_vga < 480 and cnt_v_sync_vga > 160 and cnt_v_sync_vga < 240) then
--						if MPAS_squarelight_cnt_21 < 800 then
--							MPAS_squarelight_cnt_21 <= MPAS_squarelight_cnt_21 + 1;
--							if MPAS_squarelight_cnt_21 > 640 then 
--								MPAS_squarelight_21 <= '1';
--							else
--								MPAS_squarelight_21 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_21 <= MPAS_squarelight_cnt_21;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 480 and cnt_h_sync_vga < 560 and cnt_v_sync_vga > 160 and cnt_v_sync_vga < 240) then
--						if MPAS_squarelight_cnt_22 < 800 then
--							MPAS_squarelight_cnt_22 <= MPAS_squarelight_cnt_22 + 1;
--							if MPAS_squarelight_cnt_22 > 640 then 
--								MPAS_squarelight_22 <= '1';
--							else
--								MPAS_squarelight_22 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_22 <= MPAS_squarelight_cnt_22;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 560 and cnt_h_sync_vga < 640 and cnt_v_sync_vga > 160 and cnt_v_sync_vga < 240) then
--						if MPAS_squarelight_cnt_23 < 800 then
--							MPAS_squarelight_cnt_23 <= MPAS_squarelight_cnt_23 + 1;
--							if MPAS_squarelight_cnt_23 > 640 then 
--								MPAS_squarelight_23 <= '1';
--							else
--								MPAS_squarelight_23 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_23 <= MPAS_squarelight_cnt_23;
--						end if;
--					
--					elsif ( cnt_h_sync_vga > 0 and cnt_h_sync_vga < 80 and cnt_v_sync_vga > 240 and cnt_v_sync_vga < 320) then
--						if MPAS_squarelight_cnt_24 < 800 then
--							MPAS_squarelight_cnt_24 <= MPAS_squarelight_cnt_24 + 1;
--							if MPAS_squarelight_cnt_24 > 640 then 
--								MPAS_squarelight_24 <= '1';
--							else
--								MPAS_squarelight_24 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_24 <= MPAS_squarelight_cnt_24;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 80 and cnt_h_sync_vga < 160 and cnt_v_sync_vga > 240 and cnt_v_sync_vga < 320) then
--						if MPAS_squarelight_cnt_25 < 800 then
--							MPAS_squarelight_cnt_25 <= MPAS_squarelight_cnt_25 + 1;
--							if MPAS_squarelight_cnt_25 > 640 then 
--								MPAS_squarelight_25 <= '1';
--							else
--								MPAS_squarelight_25 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_25 <= MPAS_squarelight_cnt_25;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 160 and cnt_h_sync_vga < 240 and cnt_v_sync_vga > 240 and cnt_v_sync_vga < 320) then
--						if MPAS_squarelight_cnt_26 < 800 then
--							MPAS_squarelight_cnt_26 <= MPAS_squarelight_cnt_26 + 1;
--							if MPAS_squarelight_cnt_26 > 640 then 
--								MPAS_squarelight_26 <= '1';
--							else
--								MPAS_squarelight_26 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_26 <= MPAS_squarelight_cnt_26;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 240 and cnt_h_sync_vga < 320 and cnt_v_sync_vga > 240 and cnt_v_sync_vga < 320) then
--						if MPAS_squarelight_cnt_27 < 800 then
--							MPAS_squarelight_cnt_27 <= MPAS_squarelight_cnt_27 + 1;
--							if MPAS_squarelight_cnt_27 > 640 then 
--								MPAS_squarelight_27 <= '1';
--							else
--								MPAS_squarelight_27 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_27 <= MPAS_squarelight_cnt_27;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 320 and cnt_h_sync_vga < 400 and cnt_v_sync_vga > 240 and cnt_v_sync_vga < 320) then
--						if MPAS_squarelight_cnt_28 < 800 then
--							MPAS_squarelight_cnt_28 <= MPAS_squarelight_cnt_28 + 1;
--							if MPAS_squarelight_cnt_28 > 640 then 
--								MPAS_squarelight_28 <= '1';
--							else
--								MPAS_squarelight_28 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_28 <= MPAS_squarelight_cnt_28;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 400 and cnt_h_sync_vga < 480 and cnt_v_sync_vga > 240 and cnt_v_sync_vga < 320) then
--						if MPAS_squarelight_cnt_29 < 800 then
--							MPAS_squarelight_cnt_29 <= MPAS_squarelight_cnt_29 + 1;
--							if MPAS_squarelight_cnt_29 > 640 then 
--								MPAS_squarelight_29 <= '1';
--							else
--								MPAS_squarelight_29 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_29 <= MPAS_squarelight_cnt_29;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 480 and cnt_h_sync_vga < 560 and cnt_v_sync_vga > 240 and cnt_v_sync_vga < 320) then
--						if MPAS_squarelight_cnt_30 < 800 then
--							MPAS_squarelight_cnt_30 <= MPAS_squarelight_cnt_30 + 1;
--							if MPAS_squarelight_cnt_30 > 640 then 
--								MPAS_squarelight_30 <= '1';
--							else
--								MPAS_squarelight_30 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_30 <= MPAS_squarelight_cnt_30;
--						end if;
--			
--					elsif ( cnt_h_sync_vga > 560 and cnt_h_sync_vga < 640 and cnt_v_sync_vga > 240 and cnt_v_sync_vga < 320) then
--						if MPAS_squarelight_cnt_31 < 800 then
--							MPAS_squarelight_cnt_31 <= MPAS_squarelight_cnt_31 + 1;
--							if MPAS_squarelight_cnt_31 > 640 then 
--								MPAS_squarelight_31 <= '1';
--							else
--								MPAS_squarelight_31 <= '0';
--							end if;	
--						else
--							MPAS_squarelight_cnt_31 <= MPAS_squarelight_cnt_31;
--						end if;
--								
--					end if;
--
--				end if;
				
			elsif	( cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480) then
				MPAS_squarelight_cnt_0 <= 0;
				MPAS_squarelight_cnt_1 <= 0;
				MPAS_squarelight_cnt_2 <= 0;
				MPAS_squarelight_cnt_3 <= 0;
				MPAS_squarelight_cnt_4 <= 0;
				MPAS_squarelight_cnt_5 <= 0;
				MPAS_squarelight_cnt_6 <= 0;
				MPAS_squarelight_cnt_7 <= 0;
				MPAS_squarelight_cnt_8 <= 0;
				MPAS_squarelight_cnt_9 <= 0;
				MPAS_squarelight_cnt_10 <= 0;
				MPAS_squarelight_cnt_11 <= 0;
				MPAS_squarelight_cnt_12 <= 0;
				MPAS_squarelight_cnt_13 <= 0;
				MPAS_squarelight_cnt_14 <= 0;
				MPAS_squarelight_cnt_15 <= 0;
				MPAS_squarelight_cnt_16 <= 0;
				MPAS_squarelight_cnt_17 <= 0;
				MPAS_squarelight_cnt_18 <= 0;
				MPAS_squarelight_cnt_19 <= 0;
				MPAS_squarelight_cnt_20 <= 0;
				MPAS_squarelight_cnt_21 <= 0;
				MPAS_squarelight_cnt_22 <= 0;
				MPAS_squarelight_cnt_23 <= 0;
				MPAS_squarelight_cnt_24 <= 0;
				MPAS_squarelight_cnt_25 <= 0;
				MPAS_squarelight_cnt_26 <= 0;
				MPAS_squarelight_cnt_27 <= 0;
				MPAS_squarelight_cnt_28 <= 0;
				MPAS_squarelight_cnt_29 <= 0;
				MPAS_squarelight_cnt_30 <= 0;
				MPAS_squarelight_cnt_31 <= 0;	
				squarelight_left <= 0;
				squarelight_right <= 0;
			end if;	
		end if;
	end if;
end process;
-------------------squarelight------------------------------
------------------------------------------------------------
----------------------------------------------------------------------
----- SAH end --------------------------------------------------------
----------------------------------------------------------------------

--BRAM-------------------------------------------------------------------------------------------------------
Background : BRAM
		port map (
			clka => clk_video, --change here
			dina => dina,
			addra => addra, --change here
			ena => ena,
			wea => wea,
			douta => douta -- change here
			);
--BRAM-------------------------------------------------------------------------------------------------------

--video-start------------------------------------------------------------------------------------------------
process(rst_system, clk_video)--BT.656
begin
if rst_system = '0' then
	EAV_state <= "00";
	EAV_new <= "ZZ";
	SAV_old <= "ZZ";
	f_video_en <= 'Z';
	SAV_en <= '0';
	SAV_state <= "00";
	cnt_video_en <= '0';
	cnt_vga_en <= '0';
	buf_vga_en <= '0';
else
	if rising_edge(clk_video) then
		case EAV_state is
			when "00" => if data_video = x"ff" then
								 EAV_state <= "01";
							 else
								 EAV_state <= "00";
							 end if;
			when "01" => if data_video = x"00" then
								 EAV_state <= "10";
							 else
								 EAV_state <= "00";
							 end if;
			when "10" => if data_video = x"00" then
								 EAV_state <= "11";
							 else
								 EAV_state <= "00";
							 end if;
			when "11" => EAV_new <= data_video(6 downto 5);
							 SAV_old <= EAV_new;
							 EAV_state <= "00";
			when others => null;
		end case;

		if (EAV_new = "00" and SAV_old = "01") then
			f_video_en <= '0';
			SAV_en <= '1';
			buf_vga_en <= '0';
		end if;

		if (EAV_new = "10" and SAV_old = "11") then
			f_video_en <= '1';
			SAV_en <= '1';
			buf_vga_en <= '0';
		end if;
		
		if SAV_en = '1' then
			case SAV_state is
				when "00" => if data_video = x"ff" then
									 SAV_state <= "01";
								 else
									 SAV_state <= "00";
								 end if;
				when "01" => if data_video = x"00" then
									 SAV_state <= "10";
								 else
									 SAV_state <= "00";
								 end if;
				when "10" => if data_video = x"00" then
									 SAV_state <= "11";
								 else
									 SAV_state <= "00";
								 end if;
				when "11" => SAV_en <= '0';
								 cnt_video_en <= '1';
								 cnt_vga_en <= '1';
								 buf_vga_en <= '1';
								 SAV_state <= "00";
				when others => null;
			end case;
		end if;		
	end if;
end if;
end process;
--video-start------------------------------------------------------------------------------------------------

--video-count------------------------------------------------------------------------------------------------
process(rst_system, clk_video)--cnt_video_hsync
begin
if rst_system = '0' then
	cnt_video_hsync <= 0;
	f0_vga_en <= '0';
else
	if rising_edge(clk_video) then
		if cnt_video_en = '1' then
			if cnt_video_hsync = 1715 then
				cnt_video_hsync <= 0;
			else
				cnt_video_hsync <= cnt_video_hsync + 1;
			end if;
			
			if cnt_video_hsync = 857 then
				f0_vga_en <= '1';
			end if;		
		end if;
	end if;
end if;
end process;
--video-count------------------------------------------------------------------------------------------------

--VGA---count------------------------------------------------------------------------------------------------
process(rst_system, clk_video)--cnt_h_sync_vga & cnt_v_sync_vga
begin
if rst_system = '0' then
	black_vga_en <= '0';
	cnt_h_sync_vga <= 0;
	cnt_v_sync_vga <= 0;
	sync_vga_en <= '0';
else
	if rising_edge(clk_video) then
		if cnt_vga_en = '1' then		
			if (f_video_en = '1' or (f_video_en = '0' and f0_vga_en = '1')) then
				sync_vga_en <= '1';
				if cnt_h_sync_vga = 857 then
					cnt_h_sync_vga <= 0;
					if cnt_v_sync_vga = 524 then
						cnt_v_sync_vga <= 0;
						black_vga_en <= '0';
					else
						cnt_v_sync_vga <= cnt_v_sync_vga + 1;
						black_vga_en <= not black_vga_en;
					end if;
				else
					cnt_h_sync_vga <= cnt_h_sync_vga + 1;
				end if;
			end if;
		end if;
	end if;
end if;
end process;
--VGA---count------------------------------------------------------------------------------------------------


process(rst_system, clk_video)--buf_vga_Y
begin
if rst_system = '0' then
	buf_vga_state <= "00";
	buf_vga_Y_in_cnt <= 0;
	buf_vga_Y_color_in_cnt <= 0;

	
--	YCR <= x"00000"; --YUV convert R
--	YCG <= x"00000"; --YUV convert G
--	YCB <= x"00000"; --YUV convert B
	
	--Cr_register <= x"00";
	--Cb_register <= x"00";
else
	if rising_edge(clk_video) then
		if (cnt_vga_en = '1' and cnt_video_hsync < 1280) and buf_vga_en <= '1' then
			case buf_vga_state is
				when "00" =>	 buf_vga_state <= "01"; --the data_video is Cb
				
--									if YCR > x"00000" or YCG > x"00000" or YCB > x"00000" then	--The first data has not yet completed calculate
----										buf_vga_R(buf_vga_Y_in_cnt) <= YCR(17 downto 10);
----										buf_vga_G(buf_vga_Y_in_cnt) <= YCG(17 downto 10);
----										buf_vga_B(buf_vga_Y_in_cnt) <= YCB(17 downto 10);
--										if buf_vga_Y_in_cnt = 639 then
--											buf_vga_Y_in_cnt <= 0;
--										else
--											buf_vga_Y_in_cnt <= buf_vga_Y_in_cnt + 1;
--										end if;
--									end if;
--									YCR <= Cr_register * YCR_C1;
--									YCG <= data_video * YCG_C1 + Cr_register * YCG_C2;
--									YCB <= data_video * YCB_C1;
--Cb_register <= data_video;
									
				when "01" => 	buf_vga_state <= "10"; --the data_video is Y
									buf_vga_Y(buf_vga_Y_in_cnt) <= data_video(7 downto 5);
									buf_vga_Y_2(buf_vga_Y_in_cnt) <= data_video(7 downto 4);
                                    buf_vga_Y_3(buf_vga_Y_in_cnt) <= data_video;
									if buf_vga_Y_in_cnt = 639 then
											buf_vga_Y_in_cnt <= 0;
										else
											buf_vga_Y_in_cnt <= buf_vga_Y_in_cnt + 1;
									end if;
									--x"400"   = 1024(d)
									--x"2d0a3" = 1024(d) * 128(d) * 1.4075(d)
									--x"b0e5"  = 1024(d) * 128(d) * 0.3455(d)
									--x"16f0d" = 1024(d) * 128(d) * 0.7169(d)
									--x"38ed9" = 1024(d) * 128(d) * 1.7790(d)
--									YCR <= YCR + data_video * x"400" - x"2d0a3";
--									YCG <= (YCG xor x"fffff") + data_video * x"400" + x"b0e5" + x"16f0d";
--									YCB <= YCB + data_video * x"400" - x"38ed9";
								 buf_vga_Y_color(buf_vga_Y_color_in_cnt) <= data_video;
								 if buf_vga_Y_color_in_cnt = 639 then
									 buf_vga_Y_color_in_cnt <= 0;
								 else
									 buf_vga_Y_color_in_cnt <= buf_vga_Y_color_in_cnt + 1;
								 end if;	
									
				when "10" => 	buf_vga_state <= "11"; --the data_video is Cr
									
--									buf_vga_R(buf_vga_Y_in_cnt) <= YCR(17 downto 10);
--									buf_vga_G(buf_vga_Y_in_cnt) <= YCG(17 downto 10);
--									buf_vga_B(buf_vga_Y_in_cnt) <= YCB(17 downto 10);
--									if buf_vga_Y_in_cnt = 639 then
--										buf_vga_Y_in_cnt <= 0;
--									else
--										buf_vga_Y_in_cnt <= buf_vga_Y_in_cnt + 1;
--									end if;
--									YCR <= data_video * YCR_C1;
--									YCG <= Cb_register * YCG_C1 + data_video * YCG_C2;
--									YCB <= Cb_register * YCB_C1;
--Cr_register <= data_video;
									
				when "11" =>	 buf_vga_state <= "00"; --the data_video is Y
									buf_vga_Y(buf_vga_Y_in_cnt) <= data_video(7 downto 5);
                                    buf_vga_Y_3(buf_vga_Y_in_cnt) <= data_video;
									buf_vga_Y_2(buf_vga_Y_in_cnt) <= data_video(7 downto 4);
									if buf_vga_Y_in_cnt = 639 then
											buf_vga_Y_in_cnt <= 0;
										else
											buf_vga_Y_in_cnt <= buf_vga_Y_in_cnt + 1;
									end if;
									--x"400"   = 1024(d)
									--x"2d0a3" = 1024(d) * 128(d) * 1.4075(d)
									--x"b0e5"  = 1024(d) * 128(d) * 0.3455(d)
									--x"16f0d" = 1024(d) * 128(d) * 0.7169(d)
									--x"38ed9" = 1024(d) * 128(d) * 1.7790(d)
--									YCR <= YCR + data_video * x"400" - x"2d0a3";
--									YCG <= (YCG xor x"fffff") + data_video * x"400" + x"b0e5" + x"16f0d";
--									YCB <= YCB + data_video * x"400" - x"38ed9";
								 buf_vga_Y_color(buf_vga_Y_color_in_cnt) <= data_video;
								 if buf_vga_Y_color_in_cnt = 639 then
									 buf_vga_Y_color_in_cnt <= 0;
								 else
									 buf_vga_Y_color_in_cnt <= buf_vga_Y_color_in_cnt + 1;
								 end if;

				when others => null;
			end case;
		else
			buf_vga_state <= "00";
			buf_vga_Y_in_cnt <= 0;
			--YCR <= x"00000";
			--YCG <= x"00000";
			--YCB <= x"00000";
			buf_vga_Y_color_in_cnt <= 0;
		end if;
	end if;
end if;
end process;
--VGA-buffer-8bit------------------------------------------------------------------------------------------------

--Buf-state---------------------------------------------------------------------------------------------------
process(rst_system, clk_video)--buf_sobel_cc_en
begin
if rst_system = '0' then
	range_total_cnt <= 0;
	range_total_cnt_en <= '0';
	buf_Y_temp_en <= '0';
	DF_buf_012_en <= '0';
	buf_sobel_cc_en <= '0';
	buf_sobel_cc_delay <= 0;
	DFB_buf_en <= '0';
	buf_data_state <= "00";
else
	if rising_edge(clk_video) then
		if (f_video_en = '0' and cnt_video_hsync < 1290) then
			if buf_data_state = "11" then
				buf_data_state <= "00";
			else
				buf_data_state <= buf_data_state + '1';
			end if;
			
			if (cnt_video_hsync >= 0 and cnt_video_hsync < 1290 and cnt_v_sync_vga >= 0 and cnt_v_sync_vga < 480) then
				if range_total_cnt_en = '0' then
					if buf_data_state = "11" then
						range_total_cnt_en <= '1';
						DFB_buf_en <= '1';
						DF_buf_012_en <= '1';
						buf_sobel_cc_en <= '1';
					end if;
				else
					if range_total_cnt < 1280 then
						DFB_buf_en <= '1';
						DF_buf_012_en <= '1';
						buf_sobel_cc_en <= '1';
					else
						DFB_buf_en <= '0';
						DF_buf_012_en <= '0';
						buf_sobel_cc_en <= '0';
					end if;
					
					if range_total_cnt = 1289 then
						range_total_cnt <= 1289;
					else
						range_total_cnt <= range_total_cnt + 1;
					end if;
				end if;
			else
				if cnt_v_sync_vga > 480 then
					buf_sobel_cc_delay <= 0;
				end if;
				range_total_cnt <= 0;
				range_total_cnt_en <= '0';
				DF_buf_012_en <= '0';
				buf_sobel_cc_en <= '0';
				DFB_buf_en <= '0';
			end if;
		else
			range_total_cnt <= 0;
			range_total_cnt_en <= '0';
			DF_buf_012_en <= '0';
			buf_sobel_cc_en <= '0';
			DFB_buf_en <= '0';
			buf_data_state <= "00";
		end if;
	end if;
end if;
end process;
--Buf-state---------------------------------------------------------------------------------------------------

--Sobel-Buffer------------------------------------------------------------------------------------------------
process(rst_system, clk_video)--SB_buf_0_data
begin
if rst_system = '0' then
	SB_buf_0_data_1 <= "0000000000";
	SB_buf_0_data_2 <= "0000000000";
	SB_buf_0_data_3 <= "0000000000";
	SB_buf_1_data_1 <= "0000000000";
	SB_buf_1_data_2 <= "0000000000";
	SB_buf_1_data_3 <= "0000000000";
	SB_buf_2_data_1 <= "0000000000";
	SB_buf_2_data_2 <= "0000000000";
	SB_buf_2_data_3 <= "0000000000";
	SB_buf_cnt <= 0;
else
	if rising_edge(clk_video) then
--		if ((f_video_en = '0' and black_vga_en = '0') and cnt_h_sync_vga >= 0 and cnt_h_sync_vga < 640 and cnt_v_sync_vga >= 0 and cnt_v_sync_vga < 480) then
			if DF_buf_012_en = '1' then
				if buf_data_state(0) = '0' then
					SB_buf_0_data_3 <= "00" & SB_buf_0(SB_buf_cnt);
					SB_buf_0_data_2 <= SB_buf_0_data_3;
					SB_buf_0_data_1 <= SB_buf_0_data_2;
					SB_buf_1_data_3 <= "00" & SB_buf_1(SB_buf_cnt);
					SB_buf_1_data_2 <= SB_buf_1_data_3;
					SB_buf_1_data_1 <= SB_buf_1_data_2;
					SB_buf_2_data_3 <= "00" & SB_buf_2(SB_buf_cnt);
					SB_buf_2_data_2 <= SB_buf_2_data_3;
					SB_buf_2_data_1 <= SB_buf_2_data_2;
				else	
					SB_buf_0(SB_buf_cnt) <= SB_buf_1(SB_buf_cnt);
					SB_buf_1(SB_buf_cnt) <= SB_buf_2(SB_buf_cnt);
					SB_buf_2(SB_buf_cnt) <= data_video;
					
					if SB_buf_cnt = SB_buf_cnt_max then
						SB_buf_cnt <= SB_buf_cnt_max;
					else
						SB_buf_cnt <= SB_buf_cnt + 1;
					end if;	
				end if;
			else
				SB_buf_0_data_1 <= "0000000000";
				SB_buf_0_data_2 <= "0000000000";
				SB_buf_0_data_3 <= "0000000000";
				SB_buf_1_data_1 <= "0000000000";
				SB_buf_1_data_2 <= "0000000000";
				SB_buf_1_data_3 <= "0000000000";
				SB_buf_2_data_1 <= "0000000000";
				SB_buf_2_data_2 <= "0000000000";
				SB_buf_2_data_3 <= "0000000000";
				SB_buf_cnt <= 0;
			end if;
--		end if;
	end if;
end if;
end process;
--Sobel-Buffer------------------------------------------------------------------------------------------------

--Sobel------------------------------------------------------------------------------------------------
process(rst_system, clk_video)--SB_CRB_data
variable bsobel_x_cc_1 : std_logic_vector(9 downto 0);
variable bsobel_x_cc_2 : std_logic_vector(9 downto 0);
variable bsobel_y_cc_1 : std_logic_vector(9 downto 0);
variable bsobel_y_cc_2 : std_logic_vector(9 downto 0);
begin
if rst_system = '0' then
	SB_XSCR <= "0000000000";
	SB_YSCR <= "0000000000";
	SB_CRB_data <= '0';
	SB_F33_total <= x"000";
else
	if rising_edge(clk_video) then
--		if ((f_video_en = '0' and black_vga_en = '0') and cnt_h_sync_vga >= 0 and cnt_h_sync_vga < 640 and cnt_v_sync_vga >= 0 and cnt_v_sync_vga < 480) then
			if buf_sobel_cc_en = '1' then
				if buf_data_state(0) = '1' then
					bsobel_x_cc_1 := SB_buf_0_data_1 + SB_buf_0_data_2 + SB_buf_0_data_2 + SB_buf_0_data_3;
					bsobel_x_cc_2 := SB_buf_2_data_1 + SB_buf_2_data_2 + SB_buf_2_data_2 + SB_buf_2_data_3;
					bsobel_y_cc_1 := SB_buf_0_data_1 + SB_buf_1_data_1 + SB_buf_1_data_1 + SB_buf_2_data_1;
					bsobel_y_cc_2 := SB_buf_0_data_3 + SB_buf_1_data_3 + SB_buf_1_data_3 + SB_buf_2_data_3;
					if bsobel_x_cc_1 >= bsobel_x_cc_2 then
						SB_XSCR <= bsobel_x_cc_1 - bsobel_x_cc_2;
					else
						SB_XSCR <= bsobel_x_cc_2 - bsobel_x_cc_1;
					end if;
					
					if bsobel_y_cc_1 >= bsobel_y_cc_2 then
						SB_YSCR <= bsobel_y_cc_1 - bsobel_y_cc_2;
					else
						SB_YSCR <= bsobel_y_cc_2 - bsobel_y_cc_1;
					end if;
--					F33_total <= SB_buf_0_data_1 + SB_buf_0_data_2 + SB_buf_0_data_3 + SB_buf_2_data_1 + SB_buf_2_data_2 + SB_buf_2_data_3 + SB_buf_1_data_1 + SB_buf_1_data_2 + SB_buf_1_data_3;
--					SB_F33_total <= SB_buf_0_data_1 + SB_buf_0_data_2 + SB_buf_0_data_3 + SB_buf_2_data_1 + SB_buf_2_data_2 + SB_buf_2_data_3 + SB_buf_1_data_1 + SB_buf_1_data_2 + SB_buf_1_data_3;
					
				else
--					if ((SB_XSCR > "0001100000" and SB_XSCR < "0011100000") or (SB_YSCR > "0001100000" and SB_YSCR < "0011100000")) then
					if (SB_XSCR > "0001010000" or SB_YSCR > "0001010000") then
--					if ((SB_XSCR > "0001010111" and SB_XSCR < "0001100100") or (SB_YSCR > "0001010111" and SB_YSCR < "0001100100")) then
						SB_CRB_data <= '1';
					else
						SB_CRB_data <= '0';
					end if;

					SB_F33_total <= "00"&SB_XSCR + SB_YSCR;

				end if;
			else
				SB_XSCR <= "0000000000";
				SB_YSCR <= "0000000000";
				SB_CRB_data <= '0';
				SB_F33_total <= x"000";
			end if;
--		end if;
	end if;
end if;
end process;
--Sobel------------------------------------------------------------------------------------------------

--DFB-Buffer--------------------------------------------------------------------------------------------------
addra <= CONV_STD_LOGIC_VECTOR(DFB_buf_cnt, 16);
process(rst_system, clk_video)--DFB_buf_out_data & wea & ena & addra
begin
if rst_system = '0' then
	DFB_buf_cnt <= 0;
	DFB_buf_out_data <= "00000000";
	DFB_data_delay_1 <= "00000000";
	YAB_XA_cnt <= 1;
	wea <= "0";
	ena <= '0';
else
   if rising_edge(clk_video) then
      if (DFB_buf_en = '1' and DFB_buf_cnt < DFB_buf_cnt_max) then
			if buf_data_state(0) = '0' then
				if YAB_XA_cnt = 3 then
--					SBB_buf_out_data <= douta(7 downto 1) & ER_CRB_data;
					DFB_buf_out_data <= douta(7 downto 1) & '0';
					DFB_data_delay_1 <= dina(7 downto 1) & '0';
--					SBB_data_delay_1 <= dina(7 downto 1) & ER_CRB_data;
				end if;
				wea <= "0";
				ena <= '0';
			else
				if YAB_XA_cnt = 4 then
					YAB_XA_cnt <= 1;
					if DFB_buf_cnt = DFB_buf_cnt_max then
						DFB_buf_cnt <= DFB_buf_cnt_max;
					else
						DFB_buf_cnt <= DFB_buf_cnt + 1;
					end if;
				else
					YAB_XA_cnt <= YAB_XA_cnt + 1;
				end if;
				
				if YAB_XA_cnt = 1 then
					dina <= data_video(7 downto 1) & ER_CRB_data;
					
					wea <= "1";
					ena <= '1';
				else
					wea <= "0";
					ena <= '0';
				end if;
			end if;
		elsif (cnt_h_sync_vga = 857 and cnt_v_sync_vga = 520) then
			DFB_buf_cnt <= 0;
--			DFB_buf_out_data <= "00000000";
--			DFB_data_delay_1 <= "00000000";
			YAB_XA_cnt <= 1;
			wea <= "0";
			ena <= '0';
		else
--			DFB_buf_out_data <= "00000000";
--			DFB_data_delay_1 <= "00000000";
			YAB_XA_cnt <= 1;
			wea <= "0";
			ena <= '0';
      end if;
   end if;
end if;
end process;
--DFB-Buffer--------------------------------------------------------------------------------------------------
--
--
--DFB-Buffer------------------------------------------------------------------------------------------------
process(rst_system, clk_video)--DF_buf_0_data
begin
if rst_system = '0' then
	
	DF_buf_0_data_1 <= '0';
	DF_buf_0_data_2 <= '0';
	DF_buf_0_data_3 <= '0';
	DF_buf_1_data_1 <= '0';
	DF_buf_1_data_2 <= '0';
	DF_buf_1_data_3 <= '0';
	DF_buf_2_data_1 <= '0';
	DF_buf_2_data_2 <= '0';
	DF_buf_2_data_3 <= '0';
	DF_buf_cnt <= 0;
else
	if rising_edge(clk_video) then
--		if ((f_video_en = '0' and black_vga_en = '0') and cnt_h_sync_vga >= 0 and cnt_h_sync_vga < 640 and cnt_v_sync_vga >= 0 and cnt_v_sync_vga < 480) then
			if DF_buf_012_en = '1' then
				if buf_data_state(0) = '0' then
					DF_buf_0_data_3 <= DF_buf_0(DF_buf_cnt);
					DF_buf_0_data_2 <= DF_buf_0_data_3;
					DF_buf_0_data_1 <= DF_buf_0_data_2;
					DF_buf_1_data_3 <= DF_buf_1(DF_buf_cnt);
					DF_buf_1_data_2 <= DF_buf_1_data_3;
					DF_buf_1_data_1 <= DF_buf_1_data_2;
					DF_buf_2_data_3 <= DF_buf_2(DF_buf_cnt);
					DF_buf_2_data_2 <= DF_buf_2_data_3;
					DF_buf_2_data_1 <= DF_buf_2_data_2;
					
--					DF_buf_0_data_3(0) <= DF_buf_0(DF_buf_cnt)(0);
--					DF_buf_0_data_2(0) <= DF_buf_0_data_3(0);
--					DF_buf_0_data_1(0) <= DF_buf_0_data_2(0);
--					DF_buf_1_data_3(0) <= DF_buf_1(DF_buf_cnt)(0);
--					DF_buf_1_data_2(0) <= DF_buf_1_data_3(0);
--					DF_buf_1_data_1(0) <= DF_buf_1_data_2(0);
--					DF_buf_2_data_3(0) <= DF_buf_2(DF_buf_cnt)(0);
--					DF_buf_2_data_2(0) <= DF_buf_2_data_3(0);
--					DF_buf_2_data_1(0) <= DF_buf_2_data_2(0);
				else	
--					DF_buf_0(DF_buf_cnt) <= DF_buf_1_data_3(7 downto 0);
--					DF_buf_1(DF_buf_cnt) <= DF_buf_2_data_3(7 downto 0);
					DF_buf_0(DF_buf_cnt) <= DF_buf_1_data_3;
					DF_buf_1(DF_buf_cnt) <= DF_buf_2_data_3;
--					DF_buf_2(DF_buf_cnt) <= data_video;
--					DF_buf_2(DF_buf_cnt) <= MT_YS_data;

--					if DFB_buf_out_data > DFB_data_delay_1 then 
--						DF_buf_2(DF_buf_cnt) <= DFB_buf_out_data - DFB_data_delay_1;
--					else
--						DF_buf_2(DF_buf_cnt) <= DFB_data_delay_1 - DFB_buf_out_data;
--					end if;
					
--					if MT_YS_data >= "00110010" or CRB_MDF_buf_data ='1' then--50	
					if DFB_buf_out_data > DFB_data_delay_1 then 
						if DFB_buf_out_data - DFB_data_delay_1 >= "00110010" then
							DF_buf_2(DF_buf_cnt) <= '1';
						else
							DF_buf_2(DF_buf_cnt) <= '0';
						end if;
					else
						if DFB_data_delay_1 - DFB_buf_out_data >= "00110010" then
							DF_buf_2(DF_buf_cnt) <= '1';
						else
							DF_buf_2(DF_buf_cnt) <= '0';
						end if;
					end if;
					
					if DF_buf_cnt = DF_buf_cnt_max then
						DF_buf_cnt <= DF_buf_cnt_max;
					else
						DF_buf_cnt <= DF_buf_cnt + 1;
					end if;	
				end if;
			else

				
					DF_buf_0_data_1 <= '0';
					DF_buf_0_data_2 <= '0';
					DF_buf_0_data_3 <= '0';
					DF_buf_1_data_1 <= '0';
					DF_buf_1_data_2 <= '0';
					DF_buf_1_data_3 <= '0';
					DF_buf_2_data_1 <= '0';
					DF_buf_2_data_2 <= '0';
					DF_buf_2_data_3 <= '0';
				DF_buf_cnt <= 0;
			end if;
--		end if;
	end if;
end if;
end process;
--DFB-Buffer------------------------------------------------------------------------------------------------

--Differential------------------------------------------------------------------------------------------------------
process(rst_system, clk_video)--DF_CRB_data
--variable sobel_x_cc_1 : std_logic_vector(9 downto 0);
--variable sobel_x_cc_2 : std_logic_vector(9 downto 0);
--variable sobel_y_cc_1 : std_logic_vector(9 downto 0);
--variable sobel_y_cc_2 : std_logic_vector(9 downto 0);
begin
if rst_system = '0' then
	DF_XSCR <= "0000000000";
	DF_YSCR <= "0000000000";
	DF_CRB_data <= '0';
--	F33_total <= "00000000000";
	F33_total <= '0';
else
	if rising_edge(clk_video) then
--		if ((f_video_en = '0' and black_vga_en = '0') and cnt_h_sync_vga >= 0 and cnt_h_sync_vga < 640 and cnt_v_sync_vga >= 0 and cnt_v_sync_vga < 480) then
			if buf_sobel_cc_en = '1' then
				if buf_data_state(0) = '1' then
--					sobel_x_cc_1 := DF_buf_0_data_1 + DF_buf_0_data_2 + DF_buf_0_data_2 + DF_buf_0_data_3;
--					sobel_x_cc_2 := DF_buf_2_data_1 + DF_buf_2_data_2 + DF_buf_2_data_2 + DF_buf_2_data_3;
--					sobel_y_cc_1 := DF_buf_0_data_1 + DF_buf_1_data_1 + DF_buf_1_data_1 + DF_buf_2_data_1;
--					sobel_y_cc_2 := DF_buf_0_data_3 + DF_buf_1_data_3 + DF_buf_1_data_3 + DF_buf_2_data_3;
--					if sobel_x_cc_1 >= sobel_x_cc_2 then
--						DF_XSCR <= sobel_x_cc_1 - sobel_x_cc_2;
--					else
--						DF_XSCR <= sobel_x_cc_2 - sobel_x_cc_1;
--					end if;
--					
--					if sobel_y_cc_1 >= sobel_y_cc_2 then
--						DF_YSCR <= sobel_y_cc_1 - sobel_y_cc_2;
--					else
--						DF_YSCR <= sobel_y_cc_2 - sobel_y_cc_1;
--					end if;
--					F33_total <= DF_buf_0_data_1 + DF_buf_0_data_2 + DF_buf_0_data_3 + DF_buf_2_data_1 + DF_buf_2_data_2 + DF_buf_2_data_3 + DF_buf_1_data_1 + DF_buf_1_data_2 + DF_buf_1_data_3;
					F33_total <= DF_buf_0_data_1 or DF_buf_0_data_2 or DF_buf_0_data_3 or DF_buf_2_data_1 or DF_buf_2_data_2 or 
									DF_buf_2_data_3 or DF_buf_1_data_1 or DF_buf_1_data_2 or DF_buf_1_data_3;
					
				else
					--if ((DF_XSCR > "0001100000" and DF_XSCR < "0011100000") or (DF_YSCR > "0001100000" and DF_YSCR < "0011100000")) then
--					if (DF_XSCR > "0010000000" or DF_YSCR > "0010000000") then
--						DF_CRB_data <= '1';
--					else
--						DF_CRB_data <= '0';
--					end if;
--					if abt_en ='0' then
--						if F33_total > "00110000000" then
--							DF_CRB_data <= '1';
--						else
--							DF_CRB_data <= '0';
--						end if;
--					else
--						if F33_total > x"00" then --400
						if F33_total = '1' then --400
--						if F33_total > "00111110100" then --500
							DF_CRB_data <= '1';
						else
							DF_CRB_data <= '0';
						end if;
--					end if;	
						
				end if;
			else
				DF_XSCR <= "0000000000";
				DF_YSCR <= "0000000000";
				DF_CRB_data <= '0';
			end if;
--		end if;
	end if;
end if;
end process;
--Differential------------------------------------------------------------------------------------------------------

--Skin-Buffer------------------------------------------------------------------------------------------------
process(rst_system, clk_video)--Skin_buf_2
begin
if rst_system = '0' then
	
	Skin_buf_2_data_3 <= '0';
--	Skin_buf_2_data_3_2 <= '0';
else
	if rising_edge(clk_video) then
--		if ((f_video_en = '0' and black_vga_en = '0') and cnt_h_sync_vga >= 0 and cnt_h_sync_vga < 640 and cnt_v_sync_vga >= 0 and cnt_v_sync_vga < 480) then
			if DF_buf_012_en = '1' then
				if buf_data_state(0) = '1' then
					Skin_buf_2_data_3 <= Skin_buf_2(DF_buf_cnt);
--					Skin_buf_2_data_3_2 <= Skin_buf_2_2(DF_buf_cnt);
				else	

					if (Cb_register >= "01100100" and Cb_register < "10000010") and (Cr_register >= "10010110" and Cr_register < "11001000") then
						Skin_buf_2(DF_buf_cnt) <= '1';
--					if (Cb_register >= "01100100" and Cb_register < "10000010") and (Cr_register >= "10000010" and Cr_register < "10010101") then
--						Skin_buf_2(DF_buf_cnt) <= '1';	
--						Skin_buf_2_2(DF_buf_cnt) <= '1';

					else
						Skin_buf_2(DF_buf_cnt) <= '0';
	--					Skin_buf_2_2(DF_buf_cnt) <= '0';
					end if;
						
				end if;
			else

					Skin_buf_2_data_3 <= '0';
--					Skin_buf_2_data_3_2 <= '0';
			end if;
--		end if;
	end if;
end if;
end process;
--Skin-Buffer------------------------------------------------------------------------------------------------


--Skin-Buffer_2------------------------------------------------------------------------------------------------
process(rst_system, clk_video)--Skin_buf_2_2
begin
if rst_system = '0' then
	
	Skin_buf_2_data_3_2 <= '0';
else
	if rising_edge(clk_video) then
--		if ((f_video_en = '0' and black_vga_en = '0') and cnt_h_sync_vga >= 0 and cnt_h_sync_vga < 640 and cnt_v_sync_vga >= 0 and cnt_v_sync_vga < 480) then
			if DF_buf_012_en = '1' then
				if buf_data_state(0) = '1' then
					Skin_buf_2_data_3_2 <= Skin_buf_2_2(DF_buf_cnt);
				else	

--					if (Cb_register >= "01011010" and Cb_register < "10000010") and (Cr_register >= "10010110" and Cr_register < "11001000") then
					if (Cb_register >= "01100100" and Cb_register < "10000010") and (Cr_register >= "10000010" and Cr_register < "10010101") then
						Skin_buf_2_2(DF_buf_cnt) <= '1';
					else
						Skin_buf_2_2(DF_buf_cnt) <= '0';
					end if;
						
				end if;
			else

					Skin_buf_2_data_3_2 <= '0';
			end if;
--		end if;
	end if;
end if;
end process;
--Skin-Buffer_2------------------------------------------------------------------------------------------------

--Skin_2------------------------------------------------------------------------------------------------------
process(rst_system, clk_video)--Skin_CRB_data_2

begin
if rst_system = '0' then

	Skin_CRB_data_2 <= '0';
else
	if rising_edge(clk_video) then
			if buf_sobel_cc_en = '1' then
				if buf_data_state(0) = '0' then
					
				else
						if Skin_buf_2_data_3_2 = '1' then
							Skin_CRB_data_2 <= '1';
						else
							Skin_CRB_data_2 <= '0';
						end if;
						
				end if;
			else
				Skin_CRB_data_2 <= '0';
			end if;
	end if;
end if;
end process;


--Skin-Buffer_2------------------------------------------------------------------------------------------------

--Skin------------------------------------------------------------------------------------------------------
process(rst_system, clk_video)--Skin_CRB_data

begin
if rst_system = '0' then

	Skin_CRB_data <= '0';
else
	if rising_edge(clk_video) then
			if buf_sobel_cc_en = '1' then
				if buf_data_state(0) = '0' then
					
				else
						if Skin_buf_2_data_3 = '1' then
							Skin_CRB_data <= '1';
						else
							Skin_CRB_data <= '0';
						end if;
						
				end if;
			else
				Skin_CRB_data <= '0';
			end if;
	end if;
end if;
end process;
--skin-Buffer------------------------------------------------------------------------------------------------


---brightness-Buffer----------------------------------------------------------------------------------------------------
process(rst_system, clk_video)--buf_vga_Y_data
begin
if rst_system = '0' then
	
	buf_vga_Y_data_1 <= '0';
else
	if rising_edge(clk_video) then
--		if ((f_video_en = '0' and black_vga_en = '0') and cnt_h_sync_vga >= 0 and cnt_h_sync_vga < 640 and cnt_v_sync_vga >= 0 and cnt_v_sync_vga < 480) then
			if DF_buf_012_en = '1' then
				if buf_data_state(0) = '1' then
					buf_vga_Y_data_1 <= buf_vga_Y_data(DF_buf_cnt);
				else	
					if buf_vga_Y(buf_vga_Y_in_cnt) > "011" then
						buf_vga_Y_data(DF_buf_cnt) <= '1';
					else
						buf_vga_Y_data(DF_buf_cnt) <= '0';
					end if;
				end if;
			else

					buf_vga_Y_data_1 <= '0';
			end if;     
--		end if;
	end if;
end if;
end process;

---------------------brightness-------------------------------------------------------------------------------------------
process(rst_system, clk_video)--vga_CRB_data

begin
if rst_system = '0' then

	vga_CRB_data <= '0';
else
	if rising_edge(clk_video) then
			if buf_sobel_cc_en = '1' then
				if buf_data_state(0) = '0' then
					
				else
						if buf_vga_Y_data_1 = '1' then
							vga_CRB_data <= '1';
						else
							vga_CRB_data <= '0';
						end if;
						
				end if;
			else
				vga_CRB_data <= '0';
			end if;
	end if;
end if;
end process;


---brightness-Buffer-----------------------------------------------------------------------------------------------------

---brightness-Buffer_2--------------------------------------------------------------

process(rst_system, clk_video)--buf_vga_Y_data_2    SAH Y threshold
begin
if rst_system = '0' then
	
	buf_vga_Y_data_2B <= '0';
else
	if rising_edge(clk_video) then
--		if ((f_video_en = '0' and black_vga_en = '0') and cnt_h_sync_vga >= 0 and cnt_h_sync_vga < 640 and cnt_v_sync_vga >= 0 and cnt_v_sync_vga < 480) then
			if DF_buf_012_en = '1' then
				if buf_data_state(0) = '1' then
					buf_vga_Y_data_2B <= buf_vga_Y_data_2(DF_buf_cnt);
				else	
					if buf_vga_Y_2(buf_vga_Y_in_cnt) >= SAH_Y_threshold_4bit then --SAH_Y_threshold_8bit then-- buf_vga_Y_3 8bit buf_vga_Y_2 3bit    (7 downto 5)
						buf_vga_Y_data_2(DF_buf_cnt) <= '1';
					else
						buf_vga_Y_data_2(DF_buf_cnt) <= '0';
					end if;
				end if;
			else

					buf_vga_Y_data_2B <= '0';
			end if;
--		end if;
	end if;
end if;
end process;

---------------------brightness-------------------------------------------------------------------------------------------
process(rst_system, clk_video)--vga_CRB_data_2

begin
if rst_system = '0' then

	vga_CRB_data_2 <= '0';
else
	if rising_edge(clk_video) then
			if buf_sobel_cc_en = '1' then
				if buf_data_state(0) = '0' then
					
				else
						if buf_vga_Y_data_2B = '1' then
							vga_CRB_data_2 <= '1';
						else
							vga_CRB_data_2 <= '0';
						end if;
						
				end if;
			else
				vga_CRB_data_2 <= '0';
			end if;
	end if;
end if;
end process;

---brightness-Buffer_2--------------------------------------------------------------

---------------------white-----------------------------------------------------------



process(rst_system, clk_video)--white_buf_2_data_3
begin
if rst_system = '0' then
	white_buf_2_data_3 <= '0';
else
	if rising_edge(clk_video) then
		if DF_buf_012_en = '1' then
			if buf_data_state(0) = '1' then
				white_buf_2_data_3 <= white_buf_2(DF_buf_cnt);
			else
				if (buf_vga_Y(buf_vga_Y_in_cnt) >= "111" )and(Cb_register >= "01111111" and Cb_register < "10000001") and (Cr_register >= "01111110" and Cr_register < "01111111") then
					white_buf_2(DF_buf_cnt) <= '1';
				else
					white_buf_2(DF_buf_cnt) <= '0';
				end if;		
			end if;
		else
					white_buf_2_data_3 <= '0';
		end if;
	end if;
end if;
end process;


process(rst_system, clk_video)--white_CRB_data
begin
if rst_system = '0' then
	white_CRB_data <= '0';
else
	if rising_edge(clk_video) then
			if buf_sobel_cc_en = '1' then
				if buf_data_state(0) = '0' then				
				else
					if white_buf_2_data_3 = '1' then
						white_CRB_data <= '1';
					else
						white_CRB_data <= '0';
					end if;						
				end if;
			else
				white_CRB_data <= '0';
			end if;
	end if;
end if;
end process;
---------------------white-----------------------------------------------------------

--Erosion-Buffer------------------------------------------------------------------------------------------------
process(rst_system, clk_video)--ER_buf_0_data
begin
if rst_system = '0' then
	ER_buf_0_data_1 <= x"0";
	ER_buf_0_data_2 <= x"0";
	ER_buf_0_data_3 <= x"0";
	ER_buf_1_data_1 <= x"0";
	ER_buf_1_data_2 <= x"0";
	ER_buf_1_data_3 <= x"0";
	ER_buf_2_data_1 <= x"0";
	ER_buf_2_data_2 <= x"0";
	ER_buf_2_data_3 <= x"0";
	
else
	if rising_edge(clk_video) then
--		if ((f_video_en = '0' and black_vga_en = '0') and cnt_h_sync_vga >= 0 and cnt_h_sync_vga < 640 and cnt_v_sync_vga >= 0 and cnt_v_sync_vga < 480) then
			if DF_buf_012_en = '1' then
				if buf_data_state(0) = '0' then
					ER_buf_0_data_3 <= "000" & ER_buf_0(DF_buf_cnt);
					ER_buf_0_data_2 <= ER_buf_0_data_3;
					ER_buf_0_data_1 <= ER_buf_0_data_2;
					ER_buf_1_data_3 <= "000" & ER_buf_1(DF_buf_cnt);
					ER_buf_1_data_2 <= ER_buf_1_data_3;
					ER_buf_1_data_1 <= ER_buf_1_data_2;
					ER_buf_2_data_3 <= "000" & ER_buf_2(DF_buf_cnt);
					ER_buf_2_data_2 <= ER_buf_2_data_3;
					ER_buf_2_data_1 <= ER_buf_2_data_2;
					
				else	
					ER_buf_0(DF_buf_cnt) <= ER_buf_1(DF_buf_cnt);
					ER_buf_1(DF_buf_cnt) <= ER_buf_2(DF_buf_cnt);
					
					if Skin_CRB_data = '1' then
						ER_buf_2(DF_buf_cnt) <= '1';
					else
						ER_buf_2(DF_buf_cnt) <= '0';
					end if;
					

				end if;
			else
				ER_buf_0_data_1 <= x"0";
				ER_buf_0_data_2 <= x"0";
				ER_buf_0_data_3 <= x"0";
				ER_buf_1_data_1 <= x"0";
				ER_buf_1_data_2 <= x"0";
				ER_buf_1_data_3 <= x"0";
				ER_buf_2_data_1 <= x"0";
				ER_buf_2_data_2 <= x"0";
				ER_buf_2_data_3 <= x"0";
				
			end if;
--		end if;
	end if;
end if;
end process;
--Erosion-Buffer------------------------------------------------------------------------------------------------

--Erosion------------------------------------------------------------------------------------------------------
process(rst_system, clk_video)--ER_CRB_data

begin
if rst_system = '0' then
	ER_XSCR <= x"0";
	ER_CRB_data <= '0';
--	F33_total <= "00000000000";
else
	if rising_edge(clk_video) then
--		if ((f_video_en = '0' and black_vga_en = '0') and cnt_h_sync_vga >= 0 and cnt_h_sync_vga < 640 and cnt_v_sync_vga >= 0 and cnt_v_sync_vga < 480) then
			if buf_sobel_cc_en = '1' then
				if buf_data_state(0) = '1' then
					ER_XSCR <= ER_buf_0_data_1 + ER_buf_0_data_2 + ER_buf_0_data_3
								+ ER_buf_1_data_1 + ER_buf_1_data_2 + ER_buf_1_data_3
								+ ER_buf_2_data_1 + ER_buf_2_data_2 + ER_buf_2_data_3;

					
				else
					--if ((ER_XSCR > "0001100000" and ER_XSCR < "0011100000") or (ER_YSCR > "0001100000" and ER_YSCR < "0011100000")) then
--					if (ER_XSCR > "0010000000" or ER_YSCR > "0010000000") then
					if ER_XSCR > x"8" then
						ER_CRB_data <= '1';
					else
						ER_CRB_data <= '0';
					end if;
						
				end if;
			else
				ER_XSCR <= x"0";
				ER_CRB_data <= '0';
			end if;
--		end if;
	end if;
end if;
end process;
--Erosion------------------------------------------------------------------------------------------------------
--


--CRB-------------------------------------------------------------------------------------------------------
process(rst_system, clk_video)--MT_YS_data & CRB_vga_buf_data & CRB_skin_buf_data & CRB_Sobel_buf_data & CRB_Erosion_buf
begin
if rst_system = '0' then
	CRB_buf_in_cnt <= 159;
	CRB_buf_out_cnt <= 0;
	CRB_Cb_en <= '0';
	CRB_Cr_en  <= '0';
	
else
	
	if rising_edge(clk_video) then
		if ((f_video_en = '0' and black_vga_en = '0') and cnt_h_sync_vga >= 0 and cnt_h_sync_vga < 640 and cnt_v_sync_vga >= 0 and cnt_v_sync_vga < 480)then
			if CRB_buf_out_cnt = CRB_buf_cnt_max then
				CRB_buf_out_cnt <= CRB_buf_cnt_max;
			else
				CRB_buf_out_cnt <= CRB_buf_out_cnt + 1;
			end if;
		
			CRB_MDF_buf_data <= CRB_MDF_buf(cnt_h_sync_vga);
		
			CRB_Sobel_buf_data <= CRB_Sobel_buf(CRB_buf_out_cnt);
			CRB_FV_buf_data <= CRB_FV_buf(CRB_buf_out_cnt); --FV = Focus Value
			CRB_Erosion_buf_data <= CRB_Erosion_buf(CRB_buf_out_cnt);
--			CRB_Dilation_buf_data <= CRB_Dilation_buf(CRB_buf_out_cnt);
			CRB_SF_buf_data <= CRB_SF_buf(CRB_buf_out_cnt);
--			MT_YS_data <= CRB_YYY_buf(CRB_buf_out_cnt);
			MT_YS_data <= "00" & CRB_YYY_buf(CRB_buf_out_cnt)(7 downto 2) + MT_YS_data(7 downto 2) + MT_YS_data(7 downto 2) + MT_YS_data(7 downto 2);
--			CRB_skin_buf_data <= CRB_Cb_buf(CRB_buf_in_cnt) and CRB_Cr_buf(CRB_buf_in_cnt);
			CRB_skin_buf_data <= CRB_skin_buf(CRB_buf_out_cnt);
			CRB_skin_buf_data_2 <= CRB_skin_buf_2(CRB_buf_out_cnt);
			CRB_vga_buf_data  <= CRB_vga_buf(CRB_buf_out_cnt);
			CRB_vga_buf_data_2  <= CRB_vga_buf_2(CRB_buf_out_cnt);
			CRB_white_buf_data <= CRB_white_buf(CRB_buf_out_cnt);
			
			
		else
			CRB_MDF_buf_data <= '0';
			CRB_Sobel_buf_data <= '0';
			CRB_FV_buf_data <= x"000";
			CRB_Erosion_buf_data <= '0';
--			CRB_Dilation_buf_data <= '0';
			CRB_SF_buf_data <= '0';
			CRB_buf_out_cnt <= 0;
			MT_YS_data <= "00000000";
			CRB_skin_buf_data <= '0';
			CRB_skin_buf_data_2 <= '0';
			CRB_vga_buf_data <= '0';
			CRB_vga_buf_data_2 <= '0';
			CRB_white_buf_data <= '0';
		end if;
		
		if DFB_buf_en = '1' then
--			case buf_data_state is
--				when "00" =>
--								--if (data_video >= "01111101" and data_video < "10001000") then --cb 125 - 130 Eye
--								if (data_video >= "01101110" and data_video < "10000010") then --cb 110 - 129 Skin
----									CRB_Cb_en <= '1';
--									CRB_Cb_buf(CRB_buf_in_cnt) <= '1';
--								else
----									CRB_Cb_en <= '0';
--									CRB_Cb_buf(CRB_buf_in_cnt) <= '0';
--								end if;
--				when "10" =>
--								--if (data_video >= "01111101" and data_video < "10001000") then --cb 125 - 130 Eye
--								if (data_video >= "10000010" and data_video < "10010101") then --cr 130 - 149 Skin
----									CRB_Cr_en <= '1';
--									CRB_Cr_buf(CRB_buf_in_cnt) <= '1';
--								else
----									CRB_Cr_en <= '0';
--									CRB_Cr_buf(CRB_buf_in_cnt) <= '0';
--								end if;
--				when others => null;
--			end case;
			
--			if buf_data_state(0) = '0' then
--				if skin_CRB_data = '1' then
--					CRB_skin_buf(CRB_buf_in_cnt) <= '1';
--				else
--					CRB_skin_buf(CRB_buf_in_cnt) <= '0';
--				end if;
--			end if;
			
			if buf_data_state(0) = '1' then
				--if (SF_buf_TS > "011000" and DF_CRB_data = '1') then
				--if (DF_CRB_data = '1' and CRB_Cb_en = '1' and CRB_Cr_en = '1') then
				if DF_CRB_data = '1' then
				--if SF_buf_TS > "011000" then
					CRB_MDF_buf(CRB_buf_in_cnt) <= '1';
				else
					CRB_MDF_buf(CRB_buf_in_cnt) <= '0';
				end if;
				
				if SB_CRB_data = '1' then
					CRB_Sobel_buf(CRB_buf_in_cnt) <= '1';
				else
					CRB_Sobel_buf(CRB_buf_in_cnt) <= '0';
				end if;
				
				if DFB_buf_out_data > DFB_data_delay_1 then
					CRB_YYY_buf(CRB_buf_in_cnt) <= DFB_buf_out_data - DFB_data_delay_1;
				else
					CRB_YYY_buf(CRB_buf_in_cnt) <= DFB_data_delay_1 - DFB_buf_out_data;
				end if;
				
				if skin_CRB_data = '1' then
					CRB_skin_buf(CRB_buf_in_cnt) <= '1';
				else
					CRB_skin_buf(CRB_buf_in_cnt) <= '0';
				end if;
				
				if skin_CRB_data_2 = '1' then
					CRB_skin_buf_2(CRB_buf_in_cnt) <= '1';
				else
					CRB_skin_buf_2(CRB_buf_in_cnt) <= '0';
				end if;				
				
				if vga_CRB_data = '1' then
					CRB_vga_buf(CRB_buf_in_cnt) <= '1';
				else
					CRB_vga_buf(CRB_buf_in_cnt) <= '0';
				end if;				
				
				if vga_CRB_data_2 = '1' then
					CRB_vga_buf_2(CRB_buf_in_cnt) <= '1';
				else
					CRB_vga_buf_2(CRB_buf_in_cnt) <= '0';
				end if;				
				
				if white_CRB_data = '1' then
					CRB_white_buf(CRB_buf_in_cnt) <= '1';
				else
					CRB_white_buf(CRB_buf_in_cnt) <= '0';
				end if;
				
				if ER_CRB_data = '1' then
					CRB_Erosion_buf(CRB_buf_in_cnt) <= '1';
				else
					CRB_Erosion_buf(CRB_buf_in_cnt) <= '0';
				end if;
				
--				CRB_FV_buf(CRB_buf_in_cnt) <= SB_XSCR + SB_YSCR;
				CRB_FV_buf(CRB_buf_in_cnt) <= SB_F33_total;
--				
--				if DI_CRB_data = '1' then
--					CRB_Dilation_buf(CRB_buf_in_cnt) <= '1';
--				else
--					CRB_Dilation_buf(CRB_buf_in_cnt) <= '0';
--				end if;
				
--				if SF_buf_TS > "011000" then
--					CRB_SF_buf(CRB_buf_in_cnt) <= '1';
--				else
--					CRB_SF_buf(CRB_buf_in_cnt) <= '0';
--				end if;
				
				if CRB_buf_in_cnt = 0  then
					CRB_buf_in_cnt <= 0;
				else
					CRB_buf_in_cnt <= CRB_buf_in_cnt - 1;
				end if;
			end if;					
		else
			CRB_buf_in_cnt <= CRB_buf_cnt_max;
			CRB_Cb_en <= '0';
			CRB_Cr_en <= '0';
		end if;
	end if;
end if;
end process;
--CRB-------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------  cnt_v_sync_vga = 280+30    begin   -----------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
--------------------------------------lane line---------------------------------------------
--process(rst_system,clk_video)--h_line_0_out_1
--begin
--	if rst_system = '0' then
--		h_line_0_1 <= 0;
--		h_line_0_out_1 <= 0;
--		h_line_0_cnt_1 <= 0;
--		h_line_0_en_1 <= '0';
--		road_cnt0_1 <= 0;
--		state_laneline_0_1 <= start_0;
--	elsif rising_edge(clk_video) then
--		if (cnt_h_sync_vga > laneline_pointrange_L_1 and cnt_h_sync_vga < 320 and cnt_v_sync_vga = ldw_level_three_base 
--			and h_line_0_en_1 = '0' and laneline_point_en_1 = '0')then
--			case state_laneline_0_1 is
--				when start_0 =>
--					if CRB_Sobel_buf_data = '1' then state_laneline_0_1 <= edge1_0; end if;
--				when edge1_0 =>
--					h_line_0_cnt_1 <= h_line_0_cnt_1 + 1;
--					if CRB_Sobel_buf_data = '0' then state_laneline_0_1 <= width_0; end if;
--				when width_0 =>
--					h_line_0_cnt_1 <= h_line_0_cnt_1 + 1;
--					if CRB_Sobel_buf_data = '1' then state_laneline_0_1 <= edge2_0; end if;		
--				when edge2_0 =>
--					h_line_0_cnt_1 <= h_line_0_cnt_1 + 1;
--					if CRB_Sobel_buf_data = '0' then state_laneline_0_1 <= edgeend_0; end if;
--				when edgeend_0 =>
--					if CRB_Sobel_buf_data = '0' then 	
--						if road_cnt0_1 < 30 then 
--							road_cnt0_1 <= road_cnt0_1 + 1;
--						else 
--							state_laneline_0_1 <= road0;
--						end if;	
--					else	
--						state_laneline_0_1 <= start_0; 
--						h_line_0_cnt_1 <= 0;
--						road_cnt0_1 <= 0;
--					end if;	
--				when road0 =>	
--					if h_line_0_cnt_1 > 10 and h_line_0_cnt_1 < 35  then
--						h_line_0_1 <= cnt_h_sync_vga - 30;
--						h_line_0_en_1 <= '1';
--					else
--						state_laneline_0_1 <= start_0;
--						h_line_0_cnt_1 <= 0;
--						h_line_0_en_1 <= '0';
--					end if;					
--				when others => null;
--			end case;				
------			if  (CRB_vga_buf_data_1 ='1' or CRB_Skin_buf_data_1 ='1') or (MT_YS_data >= "00010100" or CRB_MDF_buf_data ='1') then--and (MT_YS_data >= "00110010" or CRB_MDF_buf_data ='1' or car_true = '1') then	
----			if CRB_Sobel_buf_data = '0' then
----				h_line_0_cnt <= h_line_0_cnt + 1;
----			else
----				if h_line_0_cnt > 5 and h_line_0_cnt < 20 then
----					h_line_0 <= cnt_h_sync_vga;
----					h_line_0_en <= '1';
----				else
------					h_line_0 <= 0;
----					h_line_0_cnt <= 0;
----				end if;	
----			end if;
--		elsif cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then 
--			if h_line_0_en_1 = '1' and laneline_point_en_1 = '0' then 
--				h_line_0_out_1 <= h_line_0_1 ;
--			else	
--				h_line_0_out_1 <= h_line_0_out_1 ;
--			end if;	
--			h_line_0_en_1 <= '0';
--			h_line_0_cnt_1 <= 0;
--			road_cnt0_1 <= 0;
--			state_laneline_0_1 <= start_0;
--		end if;
--	end if;
--end process;
--
--
--process(rst_system,clk_video)--h_line_1_out_1
--begin
--	if rst_system = '0' then
--		h_line_1_1 <= 0;
--		h_line_1_out_1 <= 0;
--		h_line_1_cnt_1 <= 0;
--		h_line_1_en_1 <= '0';
--		road_cnt1_1 <= 0;
--		state_laneline_1_1 <= start_1;
--	elsif rising_edge(clk_video) then
--		if (cnt_h_sync_vga > 320 and cnt_h_sync_vga < laneline_pointrange_R_1 and cnt_v_sync_vga = ldw_level_three_base
--			and h_line_1_en_1 = '0' and laneline_point_en_1 = '0')then 
--			case state_laneline_1_1 is
--				when start_1 =>
--					if CRB_Sobel_buf_data = '1' then state_laneline_1_1 <= edge1_1; end if;
--				when edge1_1 =>
--					h_line_1_cnt_1 <= h_line_1_cnt_1 + 1;
--					if CRB_Sobel_buf_data = '0' then state_laneline_1_1 <= width_1; end if;
--				when width_1 =>
--					h_line_1_cnt_1 <= h_line_1_cnt_1 + 1;
--					if CRB_Sobel_buf_data = '1' then state_laneline_1_1 <= edge2_1; end if;	
--				when edge2_1 =>
--					h_line_1_cnt_1 <= h_line_1_cnt_1 + 1;
--					if CRB_Sobel_buf_data = '0' then state_laneline_1_1 <= edgeend_1; end if;	
--				when edgeend_1 =>
--					if CRB_Sobel_buf_data = '0' then 	
--						if road_cnt1_1 < 30 then 
--							road_cnt1_1 <= road_cnt1_1 + 1;
--						else 
--							state_laneline_1_1 <= road1;
--						end if;	
--					else	
--						state_laneline_1_1 <= start_1; 
--						h_line_1_cnt_1 <= 0;
--						road_cnt1_1 <= 0;
--					end if;
--				when road1 =>
--					if h_line_1_cnt_1 > 10 and h_line_1_cnt_1 < 35 and cnt_h_sync_vga > h_line_0_1 + 200 then
--						h_line_1_1 <= cnt_h_sync_vga - 30;
--						h_line_1_en_1 <= '1';
--					else
--						state_laneline_1_1 <= start_1;
--						h_line_1_cnt_1 <= 0;
--						h_line_1_en_1 <= '0';
--					end if;	
--				when others => null;
--			end case;		
------			if  (CRB_vga_buf_data_1 ='1' or CRB_Skin_buf_data_1 ='1') or (MT_YS_data >= "00010100" or CRB_MDF_buf_data ='1') then--and (MT_YS_data >= "00110010" or CRB_MDF_buf_data ='1' or car_true = '1') then	
----			if CRB_Sobel_buf_data = '0' then
----				h_line_1_cnt <= h_line_1_cnt + 1;
----			else
----				if h_line_1_cnt > 5 and h_line_1_cnt < 20 and cnt_h_sync_vga > h_line_0 + 100 then
----					h_line_1 <= cnt_h_sync_vga;
----					h_line_1_en <= '1';
----				else
------					h_line_1 <= 0;
----					h_line_1_cnt <= 0;
----				end if;	
----			end if;
--		elsif cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then 
--			if h_line_1_en_1 = '1' and laneline_point_en_1 = '0' then 
--				h_line_1_out_1 <= h_line_1_1 ;
--			else	
--				h_line_1_out_1 <= h_line_1_out_1 ;
--			end if;	
--			h_line_1_en_1 <= '0';
--			h_line_1_cnt_1 <= 0;
--			road_cnt1_1 <= 0;
--			state_laneline_1_1 <= start_1;
--		end if;
--	end if;
--end process;
--
--process(rst_system,clk_video)--h_line_2_out_1
--begin
--	if rst_system = '0' then
--		h_line_2_1 <= 0;
--		h_line_2_out_1 <= 0;
--		h_line_2_cnt_1 <= 0;
--		h_line_2_en_1 <= '0';
--		road_cnt2_1 <= 0;
--		state_laneline_2_1 <= start_2;
--	elsif rising_edge(clk_video) then
--		if (cnt_h_sync_vga > laneline_pointrange_L_1 and cnt_h_sync_vga < 320 and cnt_v_sync_vga = (ldw_level_three_base - ldw_level_range) 
--			and h_line_2_en_1 = '0' and laneline_point_en_1 = '0')then
--			case state_laneline_2_1 is
--				when start_2 =>
--					if CRB_Sobel_buf_data = '1' then state_laneline_2_1 <= edge1_2; end if;
--				when edge1_2 =>
--					h_line_2_cnt_1 <= h_line_2_cnt_1 + 1;
--					if CRB_Sobel_buf_data = '0' then state_laneline_2_1 <= width_2; end if;
--				when width_2 =>
--					h_line_2_cnt_1 <= h_line_2_cnt_1 + 1;
--					if CRB_Sobel_buf_data = '1' then state_laneline_2_1 <= edge2_2; end if;	
--				when edge2_2 =>
--					h_line_2_cnt_1 <= h_line_2_cnt_1 + 1;
--					if CRB_Sobel_buf_data = '0' then state_laneline_2_1 <= edgeend_2; end if;		
--				when edgeend_2 =>
--					if CRB_Sobel_buf_data = '0' then 	
--						if road_cnt2_1 < 30 then 
--							road_cnt2_1 <= road_cnt2_1 + 1;
--						else 
--							state_laneline_2_1 <= road2;
--						end if;	
--					else	
--						state_laneline_2_1 <= start_2; 
--						h_line_2_cnt_1 <= 0;
--						road_cnt2_1 <= 0;
--					end if;				
--				when road2 =>
--					if h_line_2_cnt_1 > 10 and h_line_2_cnt_1 < 35 then
--						h_line_2_1 <= cnt_h_sync_vga - 30;
--						h_line_2_en_1 <= '1';
--					else
--						state_laneline_2_1 <= start_2;
--						h_line_2_cnt_1 <= 0;
--						h_line_2_en_1 <= '0';
--					end if;				
--				when others => null;
--			end case;
------			if  (CRB_vga_buf_data_1 ='1' or CRB_Skin_buf_data_1 ='1') or (MT_YS_data >= "00010100" or CRB_MDF_buf_data ='1') then--and (MT_YS_data >= "00110010" or CRB_MDF_buf_data ='1' or car_true = '1') then	
----			if CRB_Sobel_buf_data = '0' then
----				h_line_2_cnt <= h_line_2_cnt + 1;
----			else
----				if h_line_2_cnt > 5 and h_line_2_cnt < 20  then
----					h_line_1 <= cnt_h_sync_vga;
----					h_line_2_en <= '1';
----				else
------					h_line_1 <= 0;
----					h_line_2_cnt <= 0;
----				end if;	
----			end if;
--		elsif cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then 
--			if h_line_2_en_1 = '1' and laneline_point_en_1 = '0' then 
--				h_line_2_out_1 <= h_line_2_1 ;
--			else	
--				h_line_2_out_1 <= h_line_2_out_1 ;
--			end if;	
--			h_line_2_en_1 <= '0';
--			h_line_2_cnt_1 <= 0;
--			road_cnt2_1 <= 0;
--			state_laneline_2_1 <= start_2 ;
--		end if;
--	end if;
--end process;
--
--process(rst_system,clk_video)--h_line_3_out_1
--begin
--	if rst_system = '0' then
--		h_line_3_1 <= 0;
--		h_line_3_out_1 <= 0;
--		h_line_3_cnt_1 <= 0;
--		h_line_3_en_1 <= '0';
--		road_cnt3_1 <= 0;
--		state_laneline_3_1 <= start_3;
--	elsif rising_edge(clk_video) then
--		if (cnt_h_sync_vga > 320 and cnt_h_sync_vga < laneline_pointrange_R_1 and cnt_v_sync_vga = (ldw_level_three_base - ldw_level_range)
--			and h_line_3_en_1 = '0' and laneline_point_en_1 = '0')then 
--			case state_laneline_3_1 is
--				when start_3 =>
--					if CRB_Sobel_buf_data = '1' then state_laneline_3_1 <= edge1_3; end if;
--				when edge1_3 =>
--					h_line_3_cnt_1 <= h_line_3_cnt_1 + 1;
--					if CRB_Sobel_buf_data = '0' then state_laneline_3_1 <= width_3; end if;
--				when width_3 =>
--					h_line_3_cnt_1 <= h_line_3_cnt_1 + 1;
--					if CRB_Sobel_buf_data = '1' then state_laneline_3_1 <= edge2_3; end if;	
--				when edge2_3 =>
--					h_line_3_cnt_1 <= h_line_3_cnt_1 + 1;
--					if CRB_Sobel_buf_data = '0' then state_laneline_3_1 <= edgeend_3; end if;	
--				when edgeend_3 => 
--					if CRB_Sobel_buf_data = '0' then 	
--						if road_cnt3_1 < 30 then 
--							road_cnt3_1 <= road_cnt3_1 + 1;
--						else 
--							state_laneline_3_1 <= road3;
--						end if;	
--					else	
--						state_laneline_3_1 <= start_3; 
--						h_line_3_cnt_1 <= 0;
--						road_cnt3_1 <= 0;
--					end if;	
--				when road3 =>
--					if h_line_3_cnt_1 > 10 and h_line_3_cnt_1 < 35 and cnt_h_sync_vga > h_line_2_1 + 200 then
--						h_line_3_1 <= cnt_h_sync_vga - 30;
--						h_line_3_en_1 <= '1';
--					else
--						state_laneline_3_1 <= start_3;
--						h_line_3_cnt_1 <= 0;
--						h_line_3_en_1 <= '0';
--					end if;					
--				when others => null;
--			end case;
------			if  (CRB_vga_buf_data_1 ='1' or CRB_Skin_buf_data_1 ='1') or (MT_YS_data >= "00010100" or CRB_MDF_buf_data ='1') then--and (MT_YS_data >= "00110010" or CRB_MDF_buf_data ='1' or car_true = '1') then	
----			if CRB_Sobel_buf_data = '0' then
----				h_line_3_cnt <= h_line_3_cnt + 1;
----			else
----				if h_line_3_cnt > 5 and h_line_3_cnt < 20 and cnt_h_sync_vga > h_line_1 + 100 then
----					h_line_3 <= cnt_h_sync_vga;
----					h_line_3_en <= '1';
----				else
------					h_line_3 <= 0;
----					h_line_3_cnt <= 0;
----				end if;	
----			end if;
--		elsif cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then 
--			if h_line_3_en_1 = '1' and laneline_point_en_1 = '0' then 
--				h_line_3_out_1 <= h_line_3_1 ;
--			else	
--				h_line_3_out_1 <= h_line_3_out_1 ;
--			end if;				
--			h_line_3_en_1 <= '0';
--			h_line_3_cnt_1 <= 0;
--			road_cnt3_1 <= 0;
--			state_laneline_3_1 <= start_3;
--		end if;
--	end if;
--end process;
--
--process(rst_system,clk_video)--debug point too much (laneline_point_en_1)
--begin
--	if rst_system = '0' then
--		laneline_point_cnt_1 <= 0;
--		laneline_point_en_1 <= '0';
--	elsif rising_edge(clk_video) then
--		if cnt_h_sync_vga > 100 and cnt_h_sync_vga < 500 and (cnt_v_sync_vga > (ldw_level_three_base - ldw_preview_range) and cnt_v_sync_vga < ldw_level_three_base) and CRB_Sobel_buf_data = '1'then	
--			if laneline_point_cnt_1 < 2000 then
--				laneline_point_cnt_1 <= laneline_point_cnt_1 + 1;
--			else
--				laneline_point_cnt_1 <= laneline_point_cnt_1 ;
--			end if;	
--		elsif cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then
--			laneline_point_cnt_1 <= 0;
--			if laneline_point_cnt_1 > 450 then
--				laneline_point_en_1 <= '1';
--			else
--				laneline_point_en_1 <= '0';
--			end if;	
--		end if;
--	end if;
--end process;
--
--process(rst_system,clk_video)--laneline_sure_L_1
--begin
--	if rst_system = '0' then
--		laneline_sure_L_1 <= '1';
--		laneline_cnt_1 <= 0;
--	elsif rising_edge(clk_video) then
--		if cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then	
--			if h_line_0_out_1 < h_line_2_out_1 and h_line_0_out_1 + 20 > h_line_2_out_1 and h_line_0_en_1 = '1' and h_line_2_en_1 = '1' then 
--				laneline_sure_L_1 <= '1';
--				laneline_cnt_1 <= 0;
--			else
--				if laneline_cnt_1 < 60 then
--					laneline_cnt_1 <= laneline_cnt_1 + 1;
--					laneline_sure_L_1 <= '1';
--				else
--					laneline_sure_L_1 <= '0';
--					laneline_cnt_1 <= 0;
--				end if;
--			end if;
--		else
--			laneline_cnt_1 <= laneline_cnt_1 ;
--		end if;
--	end if;
--end process;
--
--process(rst_system,clk_video)--laneline_sure_R_1
--begin
--	if rst_system = '0' then
--		laneline_sure_R_1 <= '1';
--		laneline_cnt_1_1 <= 0;
--	elsif rising_edge(clk_video) then
--		if cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then	
--			if h_line_1_out_1 > h_line_3_out_1 and h_line_1_out_1 - 20 < h_line_3_out_1 and h_line_1_en_1 = '1' and h_line_3_en_1 = '1' then 
--				laneline_sure_R_1 <= '1';
--				laneline_cnt_1_1 <= 0;
--			else
--				if laneline_cnt_1_1 < 60 then
--					laneline_cnt_1_1 <= laneline_cnt_1_1 + 1;
--					laneline_sure_R_1 <= '1';
--				else
--					laneline_sure_R_1 <= '0';
--					laneline_cnt_1_1 <= 0;
--				end if;
--			end if;
--		else
--			laneline_cnt_1_1 <= laneline_cnt_1_1 ;
--		end if;
--	end if;
--end process;
--
--process(rst_system,clk_video)--store buffer (laneline_R_out_1 & laneline_L_out_1)
--begin
--	if rst_system = '0' then
--		laneline_R_out_1 <= 0;
--		laneline_L_out_1 <= 0;
--		lanelinefilter_1 <= 0;
--		laneline_R_out_four_1 <= 0;
--		laneline_L_out_four_1 <= 0;
--		laneline_R_out_logic_1 <= "000000000000";
--		laneline_L_out_logic_1 <= "000000000000";
--		laneline_R_out_0_1 <= 0;
--		laneline_R_out_1_1 <= 0;
--		laneline_R_out_2_1 <= 0;
--		laneline_R_out_3_1 <= 0; 
--		laneline_R_out_4_1 <= 0; 
--		laneline_R_out_5_1 <= 0; 
--		laneline_R_out_6_1 <= 0; 
--		laneline_R_out_7_1 <= 0; 
--		laneline_L_out_0_1 <= 0;
--		laneline_L_out_1_1 <= 0;
--		laneline_L_out_2_1 <= 0;
--		laneline_L_out_3_1 <= 0;
--		laneline_L_out_4_1 <= 0;
--		laneline_L_out_5_1 <= 0;
--		laneline_L_out_6_1 <= 0;
--		laneline_L_out_7_1 <= 0;
--	elsif rising_edge(clk_video) then
--		if cnt_h_sync_vga < 640 and cnt_v_sync_vga > 360 and cnt_v_sync_vga < 480 and (laneline_sure_L_1 = '1' or laneline_sure_R_1 = '1')then	
--			case lanelinefilter_1 is
--				when 0 =>
--					laneline_R_out_four_1  <= h_line_2_out_1 + laneline_R_out_0_1 + laneline_R_out_1_1 + laneline_R_out_2_1 ;
--					laneline_L_out_four_1 <= h_line_3_out_1 + laneline_L_out_0_1 + laneline_L_out_1_1 + laneline_L_out_2_1 ;
--					lanelinefilter_1 <= 1;
--				when 1 =>
--					laneline_R_out_0_1 <= h_line_2_out_1 ;
--					laneline_R_out_1_1 <= laneline_R_out_0_1 ;
--					laneline_R_out_2_1 <= laneline_R_out_1_1 ;
--					laneline_R_out_3_1 <= laneline_R_out_2_1 ;
--					laneline_R_out_4_1 <= laneline_R_out_3_1 ;
--					laneline_R_out_5_1 <= laneline_R_out_4_1 ;
--					laneline_R_out_6_1 <= laneline_R_out_5_1 ;
--					laneline_R_out_7_1 <= laneline_R_out_6_1 ;
--					laneline_L_out_0_1 <= h_line_3_out_1 ;
--					laneline_L_out_1_1 <= laneline_L_out_0_1 ;
--					laneline_L_out_2_1 <= laneline_L_out_1_1 ;	
--					laneline_L_out_3_1 <= laneline_L_out_2_1 ;
--					laneline_L_out_4_1 <= laneline_L_out_3_1 ;
--					laneline_L_out_5_1 <= laneline_L_out_4_1 ;
--					laneline_L_out_6_1 <= laneline_L_out_5_1 ;
--					laneline_L_out_7_1 <= laneline_L_out_6_1 ;
--					lanelinefilter_1 <= 2;					
--				when 2 =>
--					laneline_R_out_logic_1 <= CONV_STD_LOGIC_VECTOR(laneline_R_out_four_1, 12);
--					laneline_L_out_logic_1 <= CONV_STD_LOGIC_VECTOR(laneline_L_out_four_1, 12);
--					lanelinefilter_1 <= 3;
--				when 3 =>
--					laneline_R_out_1 <= CONV_INTEGER(laneline_R_out_logic_1(11 downto 2));
--					laneline_L_out_1 <= CONV_INTEGER(laneline_L_out_logic_1(11 downto 2));	
--					
--				when others => null;
--			end case;
--		elsif cnt_h_sync_vga > 640 and cnt_v_sync_vga > 480 then 
--			lanelinefilter_1 <= 0;
--		end if;
--	end if;
--end process;
--
--process(rst_system,clk_video)--laneline_width_en_1
--begin
--	if rst_system = '0' then
--		laneline_width_x_1 <= 240;
--		laneline_width_en_1 <= '1';
--	elsif rising_edge(clk_video) then
--		if shift_state_1 = 1 or shift_state_1 = 2 then
--			if laneline_width_x_1 + 20 > laneline_width_1 and laneline_width_x_1 - 20 < laneline_width_1 then
--				laneline_width_en_1 <= '1';
--			else
--				laneline_width_x_1 <= laneline_L_out_1 - laneline_R_out_1 ;
--				laneline_width_en_1 <= '0';
--			end if;
--		else
--			laneline_width_en_1 <= '1';
--		end if;	
--	end if;
--end process;	
--
--process(rst_system,clk_video)--laneline_half_state_1
--begin
--	if rst_system = '0' then
--		laneline_half_state_1 <= 0;
--		laneline_half_1 <= 320;
--		laneline_quarter_1 <= 80;
--		laneline_half_two_1 <= 0;
--		laneline_half_logic_1 <= "00000000000";
--		laneline_half_en_1 <= 0;
--		laneline_halfsure_en_1 <= '1';
--		
--		laneline_width_1 <= 240;
--		laneline_width_sure_1 <= '1';
--		laneline_width_logic_1 <= "000000000";
--		
--		laneline_pointrange_L_1 <= 0;
--		laneline_pointrange_R_1 <= 640;
--	elsif rising_edge(clk_video) then
--		if cnt_h_sync_vga < 640 and cnt_v_sync_vga < 360 and laneline_half_en_1 = 1 and shift_state_1 = 0 and delay_1s_cnt_1 = 0 then
--			
--			case laneline_half_state_1 is
--				when 0 =>
--					laneline_half_two_1 <= laneline_R_out_1 + laneline_L_out_1 ;
----					if laneline_width > laneline_L_out - laneline_R_out - 30 and laneline_width < laneline_L_out - laneline_R_out + 30 then
--						laneline_width_1 <= laneline_L_out_1 - laneline_R_out_1 ;
--						laneline_half_state_1 <= 1;
--						laneline_width_sure_1 <= '1';
----					else
----						laneline_half_state <= 0;
----						laneline_width_sure <= '0';
----					end if;	
--				when 1 =>
--					laneline_half_logic_1 <= CONV_STD_LOGIC_VECTOR(laneline_half_two_1, 11);
--					laneline_width_logic_1 <= CONV_STD_LOGIC_VECTOR(laneline_width_1, 9);
--					laneline_half_state_1 <= 2;
--				when 2 =>
--					laneline_half_1 <= CONV_INTEGER(laneline_half_logic_1(10 downto 1));
--					laneline_quarter_1 <= CONV_INTEGER(laneline_width_logic_1(8 downto 2));
--					laneline_half_state_1 <= 3;
--				when 3 =>	
----					laneline_pointrange_L <= laneline_R_out - laneline_quarter;
----					laneline_pointrange_R <= laneline_L_out + laneline_quarter;
--					laneline_pointrange_L_1 <= 0;
--					laneline_pointrange_R_1 <= 640;
--					laneline_half_en_1 <= 2;
--					laneline_halfsure_en_1 <= '1';								
--				when others => null;	
--			end case;	
--		elsif shift_state_1 = 1 or shift_state_1 = 2 or shift_state_1 = 5 then
--			laneline_half_en_1 <= 1;
--			laneline_half_state_1 <= 0;
--			laneline_halfsure_en_1 <= '0';
--		end if;
--	end if;
--end process;	
--process(rst_system,clk_video)--delay_1s_cnt_1
--begin
--	if rst_system = '0' then
--		delay_1s_cnt_1 <= 0;
--	elsif rising_edge(clk_video) then
--		if shift_state_1 = 1 or shift_state_1 = 2 then 
--			if delay_1s_cnt_1 < 13500000 then 
--				delay_1s_cnt_1 <= delay_1s_cnt_1 + 1;
--			else
--				delay_1s_cnt_1 <= 0;
--			end if;	
--		else
--			delay_1s_cnt_1 <= 0;
--		end if;	
--	end if;
--end process;	
--
--process(rst_system,clk_video)--shift_state_1 => 0:middle 1:big left shift 2:big right shift 3:little left shift 4:little right shift 5:unusual
--begin
--	if rst_system = '0' then
--		shift_state_1 <= 0;
--	elsif rising_edge(clk_video) then
--        case system_state is -- system_state => 0 : disable , 1 : setup mode , 2 : system working
--
--            when 0 => shift_state_1 <= 5;
--            when 1 => shift_state_1 <= 5;
--            when 2 =>
--                if cnt_h_sync_vga < 640 and cnt_v_sync_vga < 480 and lanelinefilter_1 = 0 and delay_1s_cnt_1 = 0 and laneline_width_en_1 = '1' then	
--        --			if ((h_line_2_out > laneline_R_out_0)  and (laneline_R_out_0 > laneline_R_out_1)  and (laneline_R_out_1 > laneline_R_out_2)) or 		
--        --				((h_line_3_out > laneline_L_out_0)  and (laneline_L_out_0 > laneline_L_out_1)  and (laneline_L_out_1 > laneline_L_out_2)) then	
--        --			if ((h_line_2_out > laneline_R_out_0 + 10) and (h_line_2_out > laneline_R_out_1 + 20) and (h_line_2_out > laneline_R_out_1 + 30)) or 
--        --				((h_line_3_out > laneline_L_out_0 + 10) and (h_line_3_out > laneline_L_out_1 + 20) and (h_line_3_out > laneline_L_out_1 + 30)) then
--        --			if	((h_line_2_out > laneline_R_out_7 + 60) and (h_line_2_out > laneline_R_out_3 + 30) and h_line_2_out < laneline_R_out_3 + 100 and laneline_sure = '1') and 
--        --				((h_line_3_out > laneline_L_out_7 + 60) and (h_line_3_out > laneline_L_out_3 + 30) and h_line_3_out < laneline_L_out_3 + 100 and laneline_sure_L_1 = '1')  then
--        --				shift_state <= 1;
--                        
--        --			elsif ((h_line_2_out < laneline_R_out_0)  and (laneline_R_out_0 < laneline_R_out_1)  and (laneline_R_out_1 < laneline_R_out_1 )) or  
--        --					((h_line_3_out < laneline_L_out_0)  and (laneline_L_out_0 < laneline_L_out_1)  and (laneline_L_out_1 < laneline_L_out_2))then
--        --			elsif ((h_line_2_out < laneline_R_out_0 - 10)  and (h_line_2_out < laneline_R_out_1 - 20) and (h_line_2_out < laneline_R_out_1 - 30)) or 
--        --					((h_line_3_out < laneline_L_out_0 - 10) and (h_line_3_out < laneline_L_out_1 - 20) and (h_line_3_out < laneline_L_out_2- 30))then
--        --			elsif ((h_line_2_out < laneline_R_out_7 - 60) and (h_line_2_out < laneline_R_out_3 - 30 ) and h_line_2_out > laneline_R_out_3 - 100 and laneline_sure = '1') and 
--        --					((h_line_3_out < laneline_L_out_7 - 60) and (h_line_3_out < laneline_L_out_3 - 30) and h_line_3_out > laneline_L_out_3 - 100 and laneline_sure_L_1 = '1')  then
--        --				shift_state <= 2;
--                        
--                    if laneline_R_out_1 >= laneline_half_1 - laneline_quarter_1 - 20 and laneline_R_out_1 <= laneline_half_1 and laneline_halfsure_en_1 = '1' then 
--                        shift_state_1 <= 1;
--        --			elsif laneline_R_out > 260 and laneline_R_out < 320 and h_line_2_out < laneline_R_out_3 - 30 then 
--        --				shift_state <= 2;	
--        --			elsif laneline_L_out > 320 and laneline_L_out < 380 and h_line_3_out > laneline_L_out_3 + 30 then 
--        --				shift_state <= 1;	
--                    elsif laneline_L_out_1 >= laneline_half_1 and laneline_L_out_1 <= laneline_half_1 + laneline_quarter_1 + 20 and laneline_halfsure_en_1 = '1' then 
--                        shift_state_1 <= 2;
--                    elsif laneline_R_out_1 >= laneline_half_1 - laneline_quarter_1 - 70 and laneline_R_out_1 <= laneline_half_1 and laneline_halfsure_en_1 = '1' then
--                        shift_state_1 <= 3;
--                    elsif laneline_L_out_1 >= laneline_half_1 and laneline_L_out_1 <= laneline_half_1 + laneline_quarter_1 + 70 and laneline_halfsure_en_1 = '1' then 
--                        shift_state_1 <= 4;		
--                    elsif laneline_point_en_1 = '1' then 
--                        shift_state_1 <= 5;
--                    elsif laneline_R_out_1 > 320 or laneline_L_out_1 < 320 then 
--                        shift_state_1 <= 5;
--        --			elsif laneline_width > 500 then 
--        --				shift_state <= 5;
--                    elsif laneline_width_sure_1 = '0' then
--                        shift_state_1 <= 5;
--                    else
--                        shift_state_1 <= 0;	
--                    end if;
--                elsif laneline_point_en_1 = '1' then
--                    shift_state_1 <= 0;
--                else
--                    shift_state_1 <= shift_state_1 ;
--                end if;
--            when others =>shift_state_1 <= 5;
--        end case;
--	end if;
--end process;
----------------------------------------lane line---------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------  cnt_v_sync_vga = 280+30    end     -----------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------  cnt_v_sync_vga = 320+10    begin   -----------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
----------------------------------------lane line---------------------------------------------
--process(rst_system,clk_video)--h_line_0_out_2
--begin
--	if rst_system = '0' then
--		h_line_0_2 <= 0;
--		h_line_0_out_2 <= 0;
--		h_line_0_cnt_2 <= 0;
--		h_line_0_en_2 <= '0';
--		road_cnt0_2 <= 0;
--		state_laneline_0_2 <= start_0;
--	elsif rising_edge(clk_video) then
--		if (cnt_h_sync_vga > laneline_pointrange_L_2 and cnt_h_sync_vga < 320 and cnt_v_sync_vga = ldw_level_two_base 
--			and h_line_0_en_2 = '0' and laneline_point_en_2 = '0')then
--			case state_laneline_0_2 is
--				when start_0 =>
--					if CRB_Sobel_buf_data = '1' then state_laneline_0_2 <= edge1_0; end if;
--				when edge1_0 =>
--					h_line_0_cnt_2 <= h_line_0_cnt_2 + 1;
--					if CRB_Sobel_buf_data = '0' then state_laneline_0_2 <= width_0; end if;
--				when width_0 =>
--					h_line_0_cnt_2 <= h_line_0_cnt_2 + 1;
--					if CRB_Sobel_buf_data = '1' then state_laneline_0_2 <= edge2_0; end if;		
--				when edge2_0 =>
--					h_line_0_cnt_2 <= h_line_0_cnt_2 + 1;
--					if CRB_Sobel_buf_data = '0' then state_laneline_0_2 <= edgeend_0; end if;
--				when edgeend_0 =>
--					if CRB_Sobel_buf_data = '0' then 	
--						if road_cnt0_2 < 30 then 
--							road_cnt0_2 <= road_cnt0_2 + 1;
--						else 
--							state_laneline_0_2 <= road0;
--						end if;	
--					else	
--						state_laneline_0_2 <= start_0; 
--						h_line_0_cnt_2 <= 0;
--						road_cnt0_2 <= 0;
--					end if;	
--				when road0 =>	
--					if h_line_0_cnt_2 > 10 and h_line_0_cnt_2 < 35  then
--						h_line_0_2 <= cnt_h_sync_vga - 30;
--						h_line_0_en_2 <= '1';
--					else
--						state_laneline_0_2 <= start_0;
--						h_line_0_cnt_2 <= 0;
--						h_line_0_en_2 <= '0';
--					end if;					
--				when others => null;
--			end case;				
------			if  (CRB_vga_buf_data_2 ='1' or CRB_Skin_buf_data_2 ='1') or (MT_YS_data >= "00010100" or CRB_MDF_buf_data ='1') then--and (MT_YS_data >= "00110010" or CRB_MDF_buf_data ='1' or car_true = '1') then	
----			if CRB_Sobel_buf_data = '0' then
----				h_line_0_cnt <= h_line_0_cnt + 1;
----			else
----				if h_line_0_cnt > 5 and h_line_0_cnt < 20 then
----					h_line_0 <= cnt_h_sync_vga;
----					h_line_0_en <= '1';
----				else
------					h_line_0 <= 0;
----					h_line_0_cnt <= 0;
----				end if;	
----			end if;
--		elsif cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then 
--			if h_line_0_en_2 = '1' and laneline_point_en_2 = '0' then 
--				h_line_0_out_2 <= h_line_0_2;
--			else	
--				h_line_0_out_2 <= h_line_0_out_2;
--			end if;	
--			h_line_0_en_2 <= '0';
--			h_line_0_cnt_2 <= 0;
--			road_cnt0_2 <= 0;
--			state_laneline_0_2 <= start_0;
--		end if;
--	end if;
--end process;
--
--
--process(rst_system,clk_video)--h_line_1_out_2
--begin
--	if rst_system = '0' then
--		h_line_1_2 <= 0;
--		h_line_1_out_2 <= 0;
--		h_line_1_cnt_2 <= 0;
--		h_line_1_en_2 <= '0';
--		road_cnt1_2 <= 0;
--		state_laneline_1_2 <= start_1;
--	elsif rising_edge(clk_video) then
--		if (cnt_h_sync_vga > 320 and cnt_h_sync_vga < laneline_pointrange_R_2 and cnt_v_sync_vga = ldw_level_two_base 
--			and h_line_1_en_2 = '0' and laneline_point_en_2 = '0')then 
--			case state_laneline_1_2 is
--				when start_1 =>
--					if CRB_Sobel_buf_data = '1' then state_laneline_1_2 <= edge1_1; end if;
--				when edge1_1 =>
--					h_line_1_cnt_2 <= h_line_1_cnt_2 + 1;
--					if CRB_Sobel_buf_data = '0' then state_laneline_1_2 <= width_1; end if;
--				when width_1 =>
--					h_line_1_cnt_2 <= h_line_1_cnt_2 + 1;
--					if CRB_Sobel_buf_data = '1' then state_laneline_1_2 <= edge2_1; end if;	
--				when edge2_1 =>
--					h_line_1_cnt_2 <= h_line_1_cnt_2 + 1;
--					if CRB_Sobel_buf_data = '0' then state_laneline_1_2 <= edgeend_1; end if;	
--				when edgeend_1 =>
--					if CRB_Sobel_buf_data = '0' then 	
--						if road_cnt1_2 < 30 then 
--							road_cnt1_2 <= road_cnt1_2 + 1;
--						else 
--							state_laneline_1_2 <= road1;
--						end if;
--					else	
--						state_laneline_1_2 <= start_1; 
--						h_line_1_cnt_2 <= 0;
--						road_cnt1_2 <= 0;
--					end if;
--				when road1 =>
--					if h_line_1_cnt_2 > 10 and h_line_1_cnt_2 < 35 and cnt_h_sync_vga > h_line_0_2 + 200 then
--						h_line_1_2 <= cnt_h_sync_vga - 30;
--						h_line_1_en_2 <= '1';
--					else
--						state_laneline_1_2 <= start_1;
--						h_line_1_cnt_2 <= 0;
--						h_line_1_en_2 <= '0';
--					end if;	
--				when others => null;
--			end case;		
------			if  (CRB_vga_buf_data_2 ='1' or CRB_Skin_buf_data_2 ='1') or (MT_YS_data >= "00010100" or CRB_MDF_buf_data ='1') then--and (MT_YS_data >= "00110010" or CRB_MDF_buf_data ='1' or car_true = '1') then	
----			if CRB_Sobel_buf_data = '0' then
----				h_line_1_cnt <= h_line_1_cnt + 1;
----			else
----				if h_line_1_cnt > 5 and h_line_1_cnt < 20 and cnt_h_sync_vga > h_line_0 + 100 then
----					h_line_1 <= cnt_h_sync_vga;
----					h_line_1_en <= '1';
----				else
------					h_line_1 <= 0;
----					h_line_1_cnt <= 0;
----				end if;	
----			end if;
--		elsif cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then 
--			if h_line_1_en_2 = '1' and laneline_point_en_2 = '0' then 
--				h_line_1_out_2 <= h_line_1_2;
--			else	
--				h_line_1_out_2 <= h_line_1_out_2;
--			end if;	
--			h_line_1_en_2 <= '0';
--			h_line_1_cnt_2 <= 0;
--			road_cnt1_2 <= 0;
--			state_laneline_1_2 <= start_1;
--		end if;
--	end if;
--end process;
--
--process(rst_system,clk_video)--h_line_2_out_2
--begin
--	if rst_system = '0' then
--		h_line_2_2 <= 0;
--		h_line_2_out_2 <= 0;
--		h_line_2_cnt_2 <= 0;
--		h_line_2_en_2 <= '0';
--		road_cnt2_2 <= 0;
--		state_laneline_2_2 <= start_2;
--	elsif rising_edge(clk_video) then
--		if (cnt_h_sync_vga > laneline_pointrange_L_2 and cnt_h_sync_vga < 320 and cnt_v_sync_vga = ldw_level_two_base - ldw_level_range
--			and h_line_2_en_2 = '0' and laneline_point_en_2 = '0')then
--			case state_laneline_2_2 is
--				when start_2 =>
--					if CRB_Sobel_buf_data = '1' then state_laneline_2_2 <= edge1_2; end if;
--				when edge1_2 =>
--					h_line_2_cnt_2 <= h_line_2_cnt_2 + 1;
--					if CRB_Sobel_buf_data = '0' then state_laneline_2_2 <= width_2; end if;
--				when width_2 =>
--					h_line_2_cnt_2 <= h_line_2_cnt_2 + 1;
--					if CRB_Sobel_buf_data = '1' then state_laneline_2_2 <= edge2_2; end if;	
--				when edge2_2 =>
--					h_line_2_cnt_2 <= h_line_2_cnt_2 + 1;
--					if CRB_Sobel_buf_data = '0' then state_laneline_2_2 <= edgeend_2; end if;		
--				when edgeend_2 =>
--					if CRB_Sobel_buf_data = '0' then 	
--						if road_cnt2_2 < 30 then 
--							road_cnt2_2 <= road_cnt2_2 + 1;
--						else 
--							state_laneline_2_2 <= road2;
--						end if;	
--					else	
--						state_laneline_2_2 <= start_2; 
--						h_line_2_cnt_2 <= 0;
--						road_cnt2_2 <= 0;
--					end if;				
--				when road2 =>
--					if h_line_2_cnt_2 > 10 and h_line_2_cnt_2 < 35 then
--						h_line_2_2 <= cnt_h_sync_vga - 30;
--						h_line_2_en_2 <= '1';
--					else
--						state_laneline_2_2 <= start_2;
--						h_line_2_cnt_2 <= 0;
--						h_line_2_en_2 <= '0';
--					end if;				
--				when others => null;
--			end case;
------			if  (CRB_vga_buf_data_2 ='1' or CRB_Skin_buf_data_2 ='1') or (MT_YS_data >= "00010100" or CRB_MDF_buf_data ='1') then--and (MT_YS_data >= "00110010" or CRB_MDF_buf_data ='1' or car_true = '1') then	
----			if CRB_Sobel_buf_data = '0' then
----				h_line_2_cnt <= h_line_2_cnt + 1;
----			else
----				if h_line_2_cnt > 5 and h_line_2_cnt < 20  then
----					h_line_2 <= cnt_h_sync_vga;
----					h_line_2_en <= '1';
----				else
------					h_line_2 <= 0;
----					h_line_2_cnt <= 0;
----				end if;	
----			end if;
--		elsif cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then 
--			if h_line_2_en_2 = '1' and laneline_point_en_2 = '0' then 
--				h_line_2_out_2 <= h_line_2_2;
--			else	
--				h_line_2_out_2 <= h_line_2_out_2;
--			end if;	
--			h_line_2_en_2 <= '0';
--			h_line_2_cnt_2 <= 0;
--			road_cnt2_2 <= 0;
--			state_laneline_2_2 <= start_2;
--		end if;
--	end if;
--end process;
--
--process(rst_system,clk_video)--h_line_3_out_2
--begin
--	if rst_system = '0' then
--		h_line_3_2 <= 0;
--		h_line_3_out_2 <= 0;
--		h_line_3_cnt_2 <= 0;
--		h_line_3_en_2 <= '0';
--		road_cnt3_2 <= 0;
--		state_laneline_3_2 <= start_3;
--	elsif rising_edge(clk_video) then
--		if (cnt_h_sync_vga > 320 and cnt_h_sync_vga < laneline_pointrange_R_2 and cnt_v_sync_vga = ldw_level_two_base - ldw_level_range
--			and h_line_3_en_2 = '0' and laneline_point_en_2 = '0')then 
--			case state_laneline_3_2 is
--				when start_3 =>
--					if CRB_Sobel_buf_data = '1' then state_laneline_3_2 <= edge1_3; end if;
--				when edge1_3 =>
--					h_line_3_cnt_2 <= h_line_3_cnt_2 + 1;
--					if CRB_Sobel_buf_data = '0' then state_laneline_3_2 <= width_3; end if;
--				when width_3 =>
--					h_line_3_cnt_2 <= h_line_3_cnt_2 + 1;
--					if CRB_Sobel_buf_data = '1' then state_laneline_3_2 <= edge2_3; end if;	
--				when edge2_3 =>
--					h_line_3_cnt_2 <= h_line_3_cnt_2 + 1;
--					if CRB_Sobel_buf_data = '0' then state_laneline_3_2 <= edgeend_3; end if;	
--				when edgeend_3 => 
--					if CRB_Sobel_buf_data = '0' then 	
--						if road_cnt3_2 < 30 then 
--							road_cnt3_2 <= road_cnt3_2 + 1;
--						else 
--							state_laneline_3_2 <= road3;
--						end if;	
--					else	
--						state_laneline_3_2 <= start_3; 
--						h_line_3_cnt_2 <= 0;
--						road_cnt3_2 <= 0;
--					end if;	
--				when road3 =>
--					if h_line_3_cnt_2 > 10 and h_line_3_cnt_2 < 35 and cnt_h_sync_vga > h_line_2_2 + 200 then
--						h_line_3_2 <= cnt_h_sync_vga - 30;
--						h_line_3_en_2 <= '1';
--					else
--						state_laneline_3_2 <= start_3;
--						h_line_3_cnt_2 <= 0;
--						h_line_3_en_2 <= '0';
--					end if;					
--				when others => null;
--			end case;
------			if  (CRB_vga_buf_data_2 ='1' or CRB_Skin_buf_data_2 ='1') or (MT_YS_data >= "00010100" or CRB_MDF_buf_data ='1') then--and (MT_YS_data >= "00110010" or CRB_MDF_buf_data ='1' or car_true = '1') then	
----			if CRB_Sobel_buf_data = '0' then
----				h_line_3_cnt <= h_line_3_cnt + 1;
----			else
----				if h_line_3_cnt > 5 and h_line_3_cnt < 20 and cnt_h_sync_vga > h_line_2 + 100 then
----					h_line_3 <= cnt_h_sync_vga;
----					h_line_3_en <= '1';
----				else
------					h_line_3 <= 0;
----					h_line_3_cnt <= 0;
----				end if;	
----			end if;
--		elsif cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then 
--			if h_line_3_en_2 = '1' and laneline_point_en_2 = '0' then 
--				h_line_3_out_2 <= h_line_3_2;
--			else	
--				h_line_3_out_2 <= h_line_3_out_2;
--			end if;				
--			h_line_3_en_2 <= '0';
--			h_line_3_cnt_2 <= 0;
--			road_cnt3_2 <= 0;
--			state_laneline_3_2 <= start_3;
--		end if;
--	end if;
--end process;
--
--process(rst_system,clk_video)--debug point too much (laneline_point_en_2)
--begin
--	if rst_system = '0' then
--		laneline_point_cnt_2 <= 0;
--		laneline_point_en_2 <= '0';
--	elsif rising_edge(clk_video) then
--		if cnt_h_sync_vga > 100 and cnt_h_sync_vga < 500 and (cnt_v_sync_vga > (ldw_level_two_base - ldw_preview_range) and cnt_v_sync_vga < ldw_level_two_base) and CRB_Sobel_buf_data = '1'then	
--			if laneline_point_cnt_2 < 2000 then
--				laneline_point_cnt_2 <= laneline_point_cnt_2 + 1;
--			else
--				laneline_point_cnt_2 <= laneline_point_cnt_2;
--			end if;	
--		elsif cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then
--			laneline_point_cnt_2 <= 0;
--			if laneline_point_cnt_2 > 450 then
--				laneline_point_en_2 <= '1';
--			else
--				laneline_point_en_2 <= '0';
--			end if;	
--		end if;
--	end if;
--end process;
--
--process(rst_system,clk_video)--laneline_sure_L_2
--begin
--	if rst_system = '0' then
--		laneline_sure_L_2 <= '1';
--		laneline_cnt_2 <= 0;
--	elsif rising_edge(clk_video) then
--		if cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then	
--			if h_line_0_out_2 < h_line_2_out_2 and h_line_0_out_2 + 20 > h_line_2_out_2 and h_line_0_en_2 = '1' and h_line_2_en_2 = '1' then 
--				laneline_sure_L_2 <= '1';
--				laneline_cnt_2 <= 0;
--			else
--				if laneline_cnt_2 < 60 then
--					laneline_cnt_2 <= laneline_cnt_2 + 1;
--					laneline_sure_L_2 <= '1';
--				else
--					laneline_sure_L_2 <= '0';
--					laneline_cnt_2 <= 0;
--				end if;
--			end if;
--		else
--			laneline_cnt_2 <= laneline_cnt_2;
--		end if;
--	end if;
--end process;
--
--process(rst_system,clk_video)--laneline_sure_R_2
--begin
--	if rst_system = '0' then
--		laneline_sure_R_2 <= '1';
--		laneline_cnt_1_2 <= 0;
--	elsif rising_edge(clk_video) then
--		if cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then	
--			if h_line_1_out_2 > h_line_3_out_2 and h_line_1_out_2 - 20 < h_line_3_out_2 and h_line_1_en_2 = '1' and h_line_3_en_2 = '1' then 
--				laneline_sure_R_2 <= '1';
--				laneline_cnt_1_2 <= 0;
--			else
--				if laneline_cnt_1_2 < 60 then
--					laneline_cnt_1_2 <= laneline_cnt_1_2 + 1;
--					laneline_sure_R_2 <= '1';
--				else
--					laneline_sure_R_2 <= '0';
--					laneline_cnt_1_2 <= 0;
--				end if;
--			end if;
--		else
--			laneline_cnt_1_2 <= laneline_cnt_1_2;
--		end if;
--	end if;
--end process;
--
--process(rst_system,clk_video)--store buffer (laneline_R_out_2 & laneline_L_out_2)
--begin
--	if rst_system = '0' then
--		laneline_R_out_2 <= 0;
--		laneline_L_out_2 <= 0;
--		lanelinefilter_2 <= 0;
--		laneline_R_out_four_2 <= 0;
--		laneline_L_out_four_2 <= 0;
--		laneline_R_out_logic_2 <= "000000000000";
--		laneline_L_out_logic_2 <= "000000000000";
--		laneline_R_out_0_2 <= 0;
--		laneline_R_out_1_2 <= 0;
--		laneline_R_out_2_2 <= 0;
--		laneline_R_out_3_2 <= 0; 
--		laneline_R_out_4_2 <= 0; 
--		laneline_R_out_5_2 <= 0; 
--		laneline_R_out_6_2 <= 0; 
--		laneline_R_out_7_2 <= 0; 
--		laneline_L_out_0_2 <= 0;
--		laneline_L_out_1_2 <= 0;
--		laneline_L_out_2_2 <= 0;
--		laneline_L_out_3_2 <= 0;
--		laneline_L_out_4_2 <= 0;
--		laneline_L_out_5_2 <= 0;
--		laneline_L_out_6_2 <= 0;
--		laneline_L_out_7_2 <= 0;
--	elsif rising_edge(clk_video) then
--		if cnt_h_sync_vga < 640 and cnt_v_sync_vga > 360 and cnt_v_sync_vga < 480 and (laneline_sure_L_2 = '1' or laneline_sure_R_2 = '1')then	
--			case lanelinefilter_2 is
--				when 0 =>
--					laneline_R_out_four_2  <= h_line_2_out_2 + laneline_R_out_0_2 + laneline_R_out_1_2 + laneline_R_out_2_2;
--					laneline_L_out_four_2 <= h_line_3_out_2 + laneline_L_out_0_2 + laneline_L_out_1_2 + laneline_L_out_2_2;
--					lanelinefilter_2 <= 1;
--				when 1 =>
--					laneline_R_out_0_2 <= h_line_2_out_2;
--					laneline_R_out_1_2 <= laneline_R_out_0_2;
--					laneline_R_out_2_2 <= laneline_R_out_1_2;
--					laneline_R_out_3_2 <= laneline_R_out_2_2;
--					laneline_R_out_4_2 <= laneline_R_out_3_2;
--					laneline_R_out_5_2 <= laneline_R_out_4_2;
--					laneline_R_out_6_2 <= laneline_R_out_5_2;
--					laneline_R_out_7_2 <= laneline_R_out_6_2;
--					laneline_L_out_0_2 <= h_line_3_out_2;
--					laneline_L_out_1_2 <= laneline_L_out_0_2;
--					laneline_L_out_2_2 <= laneline_L_out_1_2;	
--					laneline_L_out_3_2 <= laneline_L_out_2_2;
--					laneline_L_out_4_2 <= laneline_L_out_3_2;
--					laneline_L_out_5_2 <= laneline_L_out_4_2;
--					laneline_L_out_6_2 <= laneline_L_out_5_2;
--					laneline_L_out_7_2 <= laneline_L_out_6_2;
--					lanelinefilter_2 <= 2;					
--				when 2 =>
--					laneline_R_out_logic_2 <= CONV_STD_LOGIC_VECTOR(laneline_R_out_four_2, 12);
--					laneline_L_out_logic_2 <= CONV_STD_LOGIC_VECTOR(laneline_L_out_four_2, 12);
--					lanelinefilter_2 <= 3;
--				when 3 =>
--					laneline_R_out_2 <= CONV_INTEGER(laneline_R_out_logic_2(11 downto 2));
--					laneline_L_out_2 <= CONV_INTEGER(laneline_L_out_logic_2(11 downto 2));	
--					
--				when others => null;
--			end case;
--		elsif cnt_h_sync_vga > 640 and cnt_v_sync_vga > 480 then 
--			lanelinefilter_2 <= 0;
--		end if;
--	end if;
--end process;
--
--process(rst_system,clk_video)--laneline_width_en_2
--begin
--	if rst_system = '0' then
--		laneline_width_x_2 <= 240;
--		laneline_width_en_2 <= '1';
--	elsif rising_edge(clk_video) then
--		if shift_state_2 = 1 or shift_state_2 = 2 then
--			if laneline_width_x_2 + 20 > laneline_width_2 and laneline_width_x_2 - 20 < laneline_width_2 then
--				laneline_width_en_2 <= '1';
--			else
--				laneline_width_x_2 <= laneline_L_out_2 - laneline_R_out_2;
--				laneline_width_en_2 <= '0';
--			end if;
--		else
--			laneline_width_en_2 <= '1';
--		end if;	
--	end if;
--end process;	
--
--process(rst_system,clk_video)--laneline_half_state_2
--begin
--	if rst_system = '0' then
--		laneline_half_state_2 <= 0;
--		laneline_half_2 <= 320;
--		laneline_quarter_2 <= 80;
--		laneline_half_two_2 <= 0;
--		laneline_half_logic_2 <= "00000000000";
--		laneline_half_en_2 <= 0;
--		laneline_halfsure_en_2 <= '1';
--		
--		laneline_width_2 <= 240;
--		laneline_width_sure_2 <= '1';
--		laneline_width_logic_2 <= "000000000";
--		
--		laneline_pointrange_L_2 <= 0;
--		laneline_pointrange_R_2 <= 640;
--	elsif rising_edge(clk_video) then
--		if cnt_h_sync_vga < 640 and cnt_v_sync_vga < 360 and laneline_half_en_2 = 1 and shift_state_2 = 0 and delay_1s_cnt_2 = 0 then
--			
--			case laneline_half_state_2 is 
--				when 0 =>
--					laneline_half_two_2 <= laneline_R_out_2 + laneline_L_out_2;
----					if laneline_width > laneline_L_out - laneline_R_out - 30 and laneline_width < laneline_L_out - laneline_R_out + 30 then
--						laneline_width_2 <= laneline_L_out_2 - laneline_R_out_2;
--						laneline_half_state_2 <= 1;
--						laneline_width_sure_2 <= '1';
----					else
----						laneline_half_state <= 0;
----						laneline_width_sure <= '0';
----					end if;	
--				when 1 =>
--					laneline_half_logic_2 <= CONV_STD_LOGIC_VECTOR(laneline_half_two_2, 11);
--					laneline_width_logic_2 <= CONV_STD_LOGIC_VECTOR(laneline_width_2, 9);
--					laneline_half_state_2 <= 2;
--				when 2 =>
--					laneline_half_2 <= CONV_INTEGER(laneline_half_logic_2(10 downto 1));
--					laneline_quarter_2 <= CONV_INTEGER(laneline_width_logic_2(8 downto 2));
--					laneline_half_state_2 <= 3;
--				when 3 =>	
----					laneline_pointrange_L <= laneline_R_out - laneline_quarter;
----					laneline_pointrange_R <= laneline_L_out + laneline_quarter;
--					laneline_pointrange_L_2 <= 0;
--					laneline_pointrange_R_2 <= 640;
--					laneline_half_en_2 <= 2;
--					laneline_halfsure_en_2 <= '1';								
--				when others => null;	
--			end case;	
--		elsif shift_state_2 = 1 or shift_state_2 = 2 or shift_state_2 = 5 then
--			laneline_half_en_2 <= 1;
--			laneline_half_state_2 <= 0;
--			laneline_halfsure_en_2 <= '0';
--		end if;
--	end if;
--end process;	
--process(rst_system,clk_video)--delay_1s_cnt_2
--begin
--	if rst_system = '0' then
--		delay_1s_cnt_2 <= 0;
--	elsif rising_edge(clk_video) then
--		if shift_state_2 = 1 or shift_state_2 = 2 then 
--			if delay_1s_cnt_2 < 13500000 then 
--				delay_1s_cnt_2 <= delay_1s_cnt_2 + 1;
--			else
--				delay_1s_cnt_2 <= 0;
--			end if;	
--		else
--			delay_1s_cnt_2 <= 0;
--		end if;	
--	end if;
--end process;	
--
--process(rst_system,clk_video)--shift_state_2 => 0:middle 1:big left shift 2:big right shift 3:little left shift 4:little right shift 5:unusual
--begin
--	if rst_system = '0' then
--		shift_state_2 <= 0;
--	elsif rising_edge(clk_video) then
--        case system_state is -- system_state => 0 : disable , 1 : setup mode , 2 : system working
--
--            when 0 => shift_state_2 <= 5;
--            when 1 => shift_state_2 <= 5;
--            when 2 =>
--                if cnt_h_sync_vga < 640 and cnt_v_sync_vga < 480 and lanelinefilter_2 = 0 and delay_1s_cnt_2 = 0 and laneline_width_en_2 = '1' then	
--        --			if ((h_line_2_out > laneline_R_out_0)  and (laneline_R_out_0 > laneline_R_out_1)  and (laneline_R_out_1 > laneline_R_out_2)) or 		
--        --				((h_line_3_out > laneline_L_out_0)  and (laneline_L_out_0 > laneline_L_out_1)  and (laneline_L_out_1 > laneline_L_out_2)) then	
--        --			if ((h_line_2_out > laneline_R_out_0 + 10) and (h_line_2_out > laneline_R_out_1 + 20) and (h_line_2_out > laneline_R_out_2 + 30)) or 
--        --				((h_line_3_out > laneline_L_out_0 + 10) and (h_line_3_out > laneline_L_out_1 + 20) and (h_line_3_out > laneline_L_out_1 + 30)) then
--        --			if	((h_line_2_out > laneline_R_out_7 + 60) and (h_line_2_out > laneline_R_out_3 + 30) and h_line_2_out < laneline_R_out_3 + 100 and laneline_sure = '1') and 
--        --				((h_line_3_out > laneline_L_out_7 + 60) and (h_line_3_out > laneline_L_out_3 + 30) and h_line_3_out < laneline_L_out_3 + 100 and laneline_sure_L_1 = '1')  then
--        --				shift_state <= 1;
--                        
--        --			elsif ((h_line_2_out < laneline_R_out_0)  and (laneline_R_out_0 < laneline_R_out_1)  and (laneline_R_out_1 < laneline_R_out_2 )) or  
--        --					((h_line_3_out < laneline_L_out_0)  and (laneline_L_out_0 < laneline_L_out_1)  and (laneline_L_out_1 < laneline_L_out_2))then
--        --			elsif ((h_line_2_out < laneline_R_out_0 - 10)  and (h_line_2_out < laneline_R_out_1 - 20) and (h_line_2_out < laneline_R_out_2 - 30)) or 
--        --					((h_line_3_out < laneline_L_out_0 - 10) and (h_line_3_out < laneline_L_out_1 - 20) and (h_line_3_out < laneline_L_out_2- 30))then
--        --			elsif ((h_line_2_out < laneline_R_out_7 - 60) and (h_line_2_out < laneline_R_out_3 - 30 ) and h_line_2_out > laneline_R_out_3 - 100 and laneline_sure = '1') and 
--        --					((h_line_3_out < laneline_L_out_7 - 60) and (h_line_3_out < laneline_L_out_3 - 30) and h_line_3_out > laneline_L_out_3 - 100 and laneline_sure_L_1 = '1')  then
--        --				shift_state <= 2;
--                        
--                    if laneline_R_out_2 >= laneline_half_2 - laneline_quarter_2 - 20 and laneline_R_out_2 <= laneline_half_2 and laneline_halfsure_en_2 = '1' then 
--                        shift_state_2 <= 1;
--        --			elsif laneline_R_out > 260 and laneline_R_out < 320 and h_line_2_out < laneline_R_out_3 - 30 then 
--        --				shift_state <= 2;	
--        --			elsif laneline_L_out > 320 and laneline_L_out < 380 and h_line_3_out > laneline_L_out_3 + 30 then 
--        --				shift_state <= 1;	
--                    elsif laneline_L_out_2 >= laneline_half_2 and laneline_L_out_2 <= laneline_half_2 + laneline_quarter_2 + 20 and laneline_halfsure_en_2 = '1' then 
--                        shift_state_2 <= 2;
--                    elsif laneline_R_out_2 >= laneline_half_2 - laneline_quarter_2 - 70 and laneline_R_out_2 <= laneline_half_2 and laneline_halfsure_en_2 = '1' then 
--                        shift_state_2 <= 3;
--                    elsif laneline_L_out_2 >= laneline_half_2 and laneline_L_out_2 <= laneline_half_2 + laneline_quarter_2 + 70 and laneline_halfsure_en_2 = '1' then 
--                        shift_state_2 <= 4;		
--                    elsif laneline_point_en_2 = '1' then 
--                        shift_state_2 <= 5;
--                    elsif laneline_R_out_2 > 320 or laneline_L_out_2 < 320 then 
--                        shift_state_2 <= 5;
--        --			elsif laneline_width > 500 then 
--        --				shift_state <= 5;
--                    elsif laneline_width_sure_2 = '0' then
--                        shift_state_2 <= 5;
--                    else
--                        shift_state_2 <= 0;	
--                    end if;
--                elsif laneline_point_en_2 = '1' then
--                    shift_state_2 <= 0;
--                else
--                    shift_state_2 <= shift_state_2;
--                end if;
--            when others =>shift_state_2 <= 5;
--        end case;
--	end if;
--end process;
----------------------------------------lane line---------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------  cnt_v_sync_vga = 320+10    end     -----------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------  cnt_v_sync_vga = 360    begin   -----------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
----------------------------------------lane line---------------------------------------------
--process(rst_system,clk_video)--h_line_0_out_0
--begin
--	if rst_system = '0' then
--		h_line_0_0 <= 0;
--		h_line_0_out_0 <= 0;
--		h_line_0_cnt_0 <= 0;
--		h_line_0_en_0 <= '0';
--		road_cnt0_0 <= 0;
--		state_laneline_0_0 <= start_0;
--	elsif rising_edge(clk_video) then
--		if (cnt_h_sync_vga > laneline_pointrange_L_0 and cnt_h_sync_vga < 320 and cnt_v_sync_vga = ldw_level_one_base 
--			and h_line_0_en_0 = '0' and laneline_point_en_0 = '0')then
--			case state_laneline_0_0 is
--				when start_0 =>
--					if CRB_Sobel_buf_data = '1' then state_laneline_0_0 <= edge1_0; end if;
--				when edge1_0 =>
--					h_line_0_cnt_0 <= h_line_0_cnt_0 + 1;
--					if CRB_Sobel_buf_data = '0' then state_laneline_0_0 <= width_0; end if;
--				when width_0 =>
--					h_line_0_cnt_0 <= h_line_0_cnt_0 + 1;
--					if CRB_Sobel_buf_data = '1' then state_laneline_0_0 <= edge2_0; end if;		
--				when edge2_0 =>
--					h_line_0_cnt_0 <= h_line_0_cnt_0 + 1;
--					if CRB_Sobel_buf_data = '0' then state_laneline_0_0 <= edgeend_0; end if;
--				when edgeend_0 =>
--					if CRB_Sobel_buf_data = '0' then 	
--						if road_cnt0_0 < 30 then 
--							road_cnt0_0 <= road_cnt0_0 + 1;
--						else 
--							state_laneline_0_0 <= road0;
--						end if;	
--					else	
--						state_laneline_0_0 <= start_0; 
--						h_line_0_cnt_0 <= 0;
--						road_cnt0_0 <= 0;
--					end if;	
--				when road0 =>	
--					if h_line_0_cnt_0 > 10 and h_line_0_cnt_0 < 35  then
--						h_line_0_0 <= cnt_h_sync_vga - 30;
--						h_line_0_en_0 <= '1';
--					else
--						state_laneline_0_0 <= start_0;
--						h_line_0_cnt_0 <= 0;
--						h_line_0_en_0 <= '0';
--					end if;					
--				when others => null;
--			end case;				
------			if  (CRB_vga_buf_data_0 ='1' or CRB_Skin_buf_data_0 ='1') or (MT_YS_data >= "00010100" or CRB_MDF_buf_data ='1') then--and (MT_YS_data >= "00110010" or CRB_MDF_buf_data ='1' or car_true = '1') then	
----			if CRB_Sobel_buf_data = '0' then
----				h_line_0_cnt <= h_line_0_cnt + 1;
----			else
----				if h_line_0_cnt > 5 and h_line_0_cnt < 20 then
----					h_line_0 <= cnt_h_sync_vga;
----					h_line_0_en <= '1';
----				else
------					h_line_0 <= 0;
----					h_line_0_cnt <= 0;
----				end if;	
----			end if;
--		elsif cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then 
--			if h_line_0_en_0 = '1' and laneline_point_en_0 = '0' then 
--				h_line_0_out_0 <= h_line_0_0;
--			else	
--				h_line_0_out_0 <= h_line_0_out_0;
--			end if;	
--			h_line_0_en_0 <= '0';
--			h_line_0_cnt_0 <= 0;
--			road_cnt0_0 <= 0;
--			state_laneline_0_0 <= start_0;
--		end if;
--	end if;
--end process;
--
--
--process(rst_system,clk_video)--h_line_1_out_0
--begin
--	if rst_system = '0' then
--		h_line_1_0 <= 0;
--		h_line_1_out_0 <= 0;
--		h_line_1_cnt_0 <= 0;
--		h_line_1_en_0 <= '0';
--		road_cnt1_0 <= 0;
--		state_laneline_1_0 <= start_1;
--	elsif rising_edge(clk_video) then
--		if (cnt_h_sync_vga > 320 and cnt_h_sync_vga < laneline_pointrange_R_0 and cnt_v_sync_vga = ldw_level_one_base 
--			and h_line_1_en_0 = '0' and laneline_point_en_0 = '0')then 
--			case state_laneline_1_0 is
--				when start_1 =>
--					if CRB_Sobel_buf_data = '1' then state_laneline_1_0 <= edge1_1; end if;
--				when edge1_1 =>
--					h_line_1_cnt_0 <= h_line_1_cnt_0 + 1;
--					if CRB_Sobel_buf_data = '0' then state_laneline_1_0 <= width_1; end if;
--				when width_1 =>
--					h_line_1_cnt_0 <= h_line_1_cnt_0 + 1;
--					if CRB_Sobel_buf_data = '1' then state_laneline_1_0 <= edge2_1; end if;	
--				when edge2_1 =>
--					h_line_1_cnt_0 <= h_line_1_cnt_0 + 1;
--					if CRB_Sobel_buf_data = '0' then state_laneline_1_0 <= edgeend_1; end if;	
--				when edgeend_1 =>
--					if CRB_Sobel_buf_data = '0' then 	
--						if road_cnt1_0 < 30 then 
--							road_cnt1_0 <= road_cnt1_0 + 1;
--						else 
--							state_laneline_1_0 <= road1;
--						end if;	
--					else	
--						state_laneline_1_0 <= start_1; 
--						h_line_1_cnt_0 <= 0;
--						road_cnt1_0 <= 0;
--					end if;
--				when road1 =>
--					if h_line_1_cnt_0 > 10 and h_line_1_cnt_0 < 35 and cnt_h_sync_vga > h_line_0_0 + 200 then
--						h_line_1_0 <= cnt_h_sync_vga - 30;
--						h_line_1_en_0 <= '1';
--					else
--						state_laneline_1_0 <= start_1;
--						h_line_1_cnt_0 <= 0;
--						h_line_1_en_0 <= '0';
--					end if;	
--				when others => null;
--			end case;		
------			if  (CRB_vga_buf_data_0 ='1' or CRB_Skin_buf_data_0 ='1') or (MT_YS_data >= "00010100" or CRB_MDF_buf_data ='1') then--and (MT_YS_data >= "00110010" or CRB_MDF_buf_data ='1' or car_true = '1') then	
----			if CRB_Sobel_buf_data = '0' then
----				h_line_1_cnt <= h_line_1_cnt + 1;
----			else
----				if h_line_1_cnt > 5 and h_line_1_cnt < 20 and cnt_h_sync_vga > h_line_0 + 100 then
----					h_line_1 <= cnt_h_sync_vga;
----					h_line_1_en <= '1';
----				else
------					h_line_1 <= 0;
----					h_line_1_cnt <= 0;
----				end if;	
----			end if;
--		elsif cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then 
--			if h_line_1_en_0 = '1' and laneline_point_en_0 = '0' then 
--				h_line_1_out_0 <= h_line_1_0;
--			else	
--				h_line_1_out_0 <= h_line_1_out_0;
--			end if;	
--			h_line_1_en_0 <= '0';
--			h_line_1_cnt_0 <= 0;
--			road_cnt1_0 <= 0;
--			state_laneline_1_0 <= start_1;
--		end if;
--	end if;
--end process;
--
--process(rst_system,clk_video)--h_line_2_out_0
--begin
--	if rst_system = '0' then
--		h_line_2_0 <= 0;
--		h_line_2_out_0 <= 0;
--		h_line_2_cnt_0 <= 0;
--		h_line_2_en_0 <= '0';
--		road_cnt2_0 <= 0;
--		state_laneline_2_0 <= start_2;
--	elsif rising_edge(clk_video) then
--		if (cnt_h_sync_vga > laneline_pointrange_L_0 and cnt_h_sync_vga < 320 and cnt_v_sync_vga = (ldw_level_one_base - ldw_level_range)
--			and h_line_2_en_0 = '0' and laneline_point_en_0 = '0')then
--			case state_laneline_2_0 is
--				when start_2 =>
--					if CRB_Sobel_buf_data = '1' then state_laneline_2_0 <= edge1_2; end if;
--				when edge1_2 =>
--					h_line_2_cnt_0 <= h_line_2_cnt_0 + 1;
--					if CRB_Sobel_buf_data = '0' then state_laneline_2_0 <= width_2; end if;
--				when width_2 =>
--					h_line_2_cnt_0 <= h_line_2_cnt_0 + 1;
--					if CRB_Sobel_buf_data = '1' then state_laneline_2_0 <= edge2_2; end if;	
--				when edge2_2 =>
--					h_line_2_cnt_0 <= h_line_2_cnt_0 + 1;
--					if CRB_Sobel_buf_data = '0' then state_laneline_2_0 <= edgeend_2; end if;		
--				when edgeend_2 =>
--					if CRB_Sobel_buf_data = '0' then 	
--						if road_cnt2_0 < 30 then 
--							road_cnt2_0 <= road_cnt2_0 + 1;
--						else 
--							state_laneline_2_0 <= road2;
--						end if;	
--					else	
--						state_laneline_2_0 <= start_2; 
--						h_line_2_cnt_0 <= 0;
--						road_cnt2_0 <= 0;
--					end if;				
--				when road2 =>
--					if h_line_2_cnt_0 > 10 and h_line_2_cnt_0 < 35 then
--						h_line_2_0 <= cnt_h_sync_vga - 30;
--						h_line_2_en_0 <= '1';
--					else
--						state_laneline_2_0 <= start_2;
--						h_line_2_cnt_0 <= 0;
--						h_line_2_en_0 <= '0';
--					end if;				
--				when others => null;
--			end case;
------			if  (CRB_vga_buf_data_0 ='1' or CRB_Skin_buf_data_0 ='1') or (MT_YS_data >= "00010100" or CRB_MDF_buf_data ='1') then--and (MT_YS_data >= "00110010" or CRB_MDF_buf_data ='1' or car_true = '1') then	
----			if CRB_Sobel_buf_data = '0' then
----				h_line_2_cnt <= h_line_2_cnt + 1;
----			else
----				if h_line_2_cnt > 5 and h_line_2_cnt < 20  then
----					h_line_0 <= cnt_h_sync_vga;
----					h_line_2_en <= '1';
----				else
------					h_line_0 <= 0;
----					h_line_2_cnt <= 0;
----				end if;	
----			end if;
--		elsif cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then 
--			if h_line_2_en_0 = '1' and laneline_point_en_0 = '0' then 
--				h_line_2_out_0 <= h_line_2_0;
--			else	
--				h_line_2_out_0 <= h_line_2_out_0;
--			end if;	
--			h_line_2_en_0 <= '0';
--			h_line_2_cnt_0 <= 0;
--			road_cnt2_0 <= 0;
--			state_laneline_2_0 <= start_2;
--		end if;
--	end if;
--end process;
--
--process(rst_system,clk_video)--h_line_3_out_0
--begin
--	if rst_system = '0' then
--		h_line_3_0 <= 0;
--		h_line_3_out_0 <= 0;
--		h_line_3_cnt_0 <= 0;
--		h_line_3_en_0 <= '0';
--		road_cnt3_0 <= 0;
--		state_laneline_3_0 <= start_3;
--	elsif rising_edge(clk_video) then
--		if (cnt_h_sync_vga > 320 and cnt_h_sync_vga < laneline_pointrange_R_0 and cnt_v_sync_vga = (ldw_level_one_base - ldw_level_range) 
--			and h_line_3_en_0 = '0' and laneline_point_en_0 = '0')then 
--			case state_laneline_3_0 is
--				when start_3 =>
--					if CRB_Sobel_buf_data = '1' then state_laneline_3_0 <= edge1_3; end if;
--				when edge1_3 =>
--					h_line_3_cnt_0 <= h_line_3_cnt_0 + 1;
--					if CRB_Sobel_buf_data = '0' then state_laneline_3_0 <= width_3; end if;
--				when width_3 =>
--					h_line_3_cnt_0 <= h_line_3_cnt_0 + 1;
--					if CRB_Sobel_buf_data = '1' then state_laneline_3_0 <= edge2_3; end if;	
--				when edge2_3 =>
--					h_line_3_cnt_0 <= h_line_3_cnt_0 + 1;
--					if CRB_Sobel_buf_data = '0' then state_laneline_3_0 <= edgeend_3; end if;	
--				when edgeend_3 => 
--					if CRB_Sobel_buf_data = '0' then 	
--						if road_cnt3_0 < 30 then 
--							road_cnt3_0 <= road_cnt3_0 + 1;
--						else 
--							state_laneline_3_0 <= road3;
--						end if;	
--					else	
--						state_laneline_3_0 <= start_3; 
--						h_line_3_cnt_0 <= 0;
--						road_cnt3_0 <= 0;
--					end if;	
--				when road3 =>
--					if h_line_3_cnt_0 > 10 and h_line_3_cnt_0 < 35 and cnt_h_sync_vga > h_line_2_0 + 200 then
--						h_line_3_0 <= cnt_h_sync_vga - 30;
--						h_line_3_en_0 <= '1';
--					else
--						state_laneline_3_0 <= start_3;
--						h_line_3_cnt_0 <= 0;
--						h_line_3_en_0 <= '0';
--					end if;					
--				when others => null;
--			end case;
------			if  (CRB_vga_buf_data_0 ='1' or CRB_Skin_buf_data_0 ='1') or (MT_YS_data >= "00010100" or CRB_MDF_buf_data ='1') then--and (MT_YS_data >= "00110010" or CRB_MDF_buf_data ='1' or car_true = '1') then	
----			if CRB_Sobel_buf_data = '0' then
----				h_line_3_cnt <= h_line_3_cnt + 1;
----			else
----				if h_line_3_cnt > 5 and h_line_3_cnt < 20 and cnt_h_sync_vga > h_line_0 + 100 then
----					h_line_3 <= cnt_h_sync_vga;
----					h_line_3_en <= '1';
----				else
------					h_line_3 <= 0;
----					h_line_3_cnt <= 0;
----				end if;	
----			end if;
--		elsif cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then 
--			if h_line_3_en_0 = '1' and laneline_point_en_0 = '0' then 
--				h_line_3_out_0 <= h_line_3_0;
--			else	
--				h_line_3_out_0 <= h_line_3_out_0;
--			end if;				
--			h_line_3_en_0 <= '0';
--			h_line_3_cnt_0 <= 0;
--			road_cnt3_0 <= 0;
--			state_laneline_3_0 <= start_3;
--		end if;
--	end if;
--end process;
--
--process(rst_system,clk_video)--debug point too much (laneline_point_en_0)
--begin
--	if rst_system = '0' then
--		laneline_point_cnt_0 <= 0;
--		laneline_point_en_0 <= '0';
--	elsif rising_edge(clk_video) then
--		if cnt_h_sync_vga > 100 and cnt_h_sync_vga < 500 and (cnt_v_sync_vga > (ldw_level_one_base - ldw_preview_range) and cnt_v_sync_vga < ldw_level_one_base) and CRB_Sobel_buf_data = '1'then	
--			if laneline_point_cnt_0 < 2000 then
--				laneline_point_cnt_0 <= laneline_point_cnt_0 + 1;
--			else
--				laneline_point_cnt_0 <= laneline_point_cnt_0;
--			end if;	
--		elsif cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then
--			laneline_point_cnt_0 <= 0;
--			if laneline_point_cnt_0 > 450 then
--				laneline_point_en_0 <= '1';
--			else
--				laneline_point_en_0 <= '0';
--			end if;	
--		end if;
--	end if;
--end process;
--
--process(rst_system,clk_video)--laneline_sure_L_0
--begin
--	if rst_system = '0' then
--		laneline_sure_L_0 <= '1';
--		laneline_cnt_0 <= 0;
--	elsif rising_edge(clk_video) then
--		if cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then	
--			if h_line_0_out_0 < h_line_2_out_0 and h_line_0_out_0 + 20 > h_line_2_out_0 and h_line_0_en_0 = '1' and h_line_2_en_0 = '1' then 
--				laneline_sure_L_0 <= '1';
--				laneline_cnt_0 <= 0;
--			else
--				if laneline_cnt_0 < 60 then
--					laneline_cnt_0 <= laneline_cnt_0 + 1;
--					laneline_sure_L_0 <= '1';
--				else
--					laneline_sure_L_0 <= '0';
--					laneline_cnt_0 <= 0;
--				end if;
--			end if;
--		else
--			laneline_cnt_0 <= laneline_cnt_0;
--		end if;
--	end if;
--end process;
--
--process(rst_system,clk_video)--laneline_sure_R_0
--begin
--	if rst_system = '0' then
--		laneline_sure_R_0 <= '1';
--		laneline_cnt_1_0 <= 0;
--	elsif rising_edge(clk_video) then
--		if cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then	
--			if h_line_1_out_0 > h_line_3_out_0 and h_line_1_out_0 - 20 < h_line_3_out_0 and h_line_1_en_0 = '1' and h_line_3_en_0 = '1' then 
--				laneline_sure_R_0 <= '1';
--				laneline_cnt_1_0 <= 0;
--			else
--				if laneline_cnt_1_0 < 60 then
--					laneline_cnt_1_0 <= laneline_cnt_1_0 + 1;
--					laneline_sure_R_0 <= '1';
--				else
--					laneline_sure_R_0 <= '0';
--					laneline_cnt_1_0 <= 0;
--				end if;
--			end if;
--		else
--			laneline_cnt_1_0 <= laneline_cnt_1_0;
--		end if;
--	end if;
--end process;
--
--process(rst_system,clk_video)--store buffer (laneline_R_out_0 & laneline_L_out_0)
--begin
--	if rst_system = '0' then
--		laneline_R_out_0 <= 0;
--		laneline_L_out_0 <= 0;
--		lanelinefilter_0 <= 0;
--		laneline_R_out_four_0 <= 0;
--		laneline_L_out_four_0 <= 0;
--		laneline_R_out_logic_0 <= "000000000000";
--		laneline_L_out_logic_0 <= "000000000000";
--		laneline_R_out_0_0 <= 0;
--		laneline_R_out_1_0 <= 0;
--		laneline_R_out_2_0 <= 0;
--		laneline_R_out_3_0 <= 0; 
--		laneline_R_out_4_0 <= 0; 
--		laneline_R_out_5_0 <= 0; 
--		laneline_R_out_6_0 <= 0; 
--		laneline_R_out_7_0 <= 0; 
--		laneline_L_out_0_0 <= 0;
--		laneline_L_out_1_0 <= 0;
--		laneline_L_out_2_0 <= 0;
--		laneline_L_out_3_0 <= 0;
--		laneline_L_out_4_0 <= 0;
--		laneline_L_out_5_0 <= 0;
--		laneline_L_out_6_0 <= 0;
--		laneline_L_out_7_0 <= 0;
--	elsif rising_edge(clk_video) then
--		if cnt_h_sync_vga < 640 and cnt_v_sync_vga > 320 and cnt_v_sync_vga < 480 and (laneline_sure_L_0 = '1' or laneline_sure_R_0 = '1')then	
--			case lanelinefilter_0 is
--				when 0 =>
--					laneline_R_out_four_0  <= h_line_2_out_0 + laneline_R_out_0_0 + laneline_R_out_1_0 + laneline_R_out_2_0;
--					laneline_L_out_four_0 <= h_line_3_out_0 + laneline_L_out_0_0 + laneline_L_out_1_0 + laneline_L_out_2_0;
--					lanelinefilter_0 <= 1;
--				when 1 =>
--					laneline_R_out_0_0 <= h_line_2_out_0;
--					laneline_R_out_1_0 <= laneline_R_out_0_0;
--					laneline_R_out_2_0 <= laneline_R_out_1_0;
--					laneline_R_out_3_0 <= laneline_R_out_2_0;
--					laneline_R_out_4_0 <= laneline_R_out_3_0;
--					laneline_R_out_5_0 <= laneline_R_out_4_0;
--					laneline_R_out_6_0 <= laneline_R_out_5_0;
--					laneline_R_out_7_0 <= laneline_R_out_6_0;
--					laneline_L_out_0_0 <= h_line_3_out_0;
--					laneline_L_out_1_0 <= laneline_L_out_0_0;
--					laneline_L_out_2_0 <= laneline_L_out_1_0;	
--					laneline_L_out_3_0 <= laneline_L_out_2_0;
--					laneline_L_out_4_0 <= laneline_L_out_3_0;
--					laneline_L_out_5_0 <= laneline_L_out_4_0;
--					laneline_L_out_6_0 <= laneline_L_out_5_0;
--					laneline_L_out_7_0 <= laneline_L_out_6_0;
--					lanelinefilter_0 <= 2;					
--				when 2 =>
--					laneline_R_out_logic_0 <= CONV_STD_LOGIC_VECTOR(laneline_R_out_four_0, 12);
--					laneline_L_out_logic_0 <= CONV_STD_LOGIC_VECTOR(laneline_L_out_four_0, 12);
--					lanelinefilter_0 <= 3;
--				when 3 =>
--					laneline_R_out_0 <= CONV_INTEGER(laneline_R_out_logic_0(11 downto 2));
--					laneline_L_out_0 <= CONV_INTEGER(laneline_L_out_logic_0(11 downto 2));	
--				when others => null;
--			end case;
--		elsif cnt_h_sync_vga > 640 and cnt_v_sync_vga > 480 then 
--			lanelinefilter_0 <= 0;
--		end if;
--	end if;
--end process;
--
--process(rst_system,clk_video)--laneline_width_en_0
--begin
--	if rst_system = '0' then
--		laneline_width_x_0 <= 240;
--		laneline_width_en_0 <= '1';
--	elsif rising_edge(clk_video) then
--		if shift_state_0 = 1 or shift_state_0 = 2 then
--			if laneline_width_x_0 + 20 > laneline_width_0 and laneline_width_x_0 - 20 < laneline_width_0 then
--				laneline_width_en_0 <= '1';
--			else
--				laneline_width_x_0 <= laneline_L_out_0 - laneline_R_out_0;
--				laneline_width_en_0 <= '0';
--			end if;
--		else
--			laneline_width_en_0 <= '1';
--		end if;	
--	end if;
--end process;	
--
--process(rst_system,clk_video)--laneline_half_state_0
--begin
--	if rst_system = '0' then
--		laneline_half_state_0 <= 0;
--		laneline_half_0 <= 320;
--		laneline_quarter_0 <= 80;
--		laneline_half_two_0 <= 0;
--		laneline_half_logic_0 <= "00000000000";
--		laneline_half_en_0 <= 0;
--		laneline_halfsure_en_0 <= '1';
--		
--		laneline_width_0 <= 240;
--		laneline_width_sure_0 <= '1';
--		laneline_width_logic_0 <= "000000000";
--		
--		laneline_pointrange_L_0 <= 0;
--		laneline_pointrange_R_0 <= 640;
--	elsif rising_edge(clk_video) then
--		if cnt_h_sync_vga < 640 and cnt_v_sync_vga < 360 and laneline_half_en_0 = 1 and shift_state_0 = 0 and delay_1s_cnt_0 = 0 then
--			
--			case laneline_half_state_0 is 
--				when 0 =>
--					laneline_half_two_0 <= laneline_R_out_0 + laneline_L_out_0;
----					if laneline_width > laneline_L_out - laneline_R_out - 30 and laneline_width < laneline_L_out - laneline_R_out + 30 then
--						laneline_width_0 <= laneline_L_out_0 - laneline_R_out_0;
--						laneline_half_state_0 <= 1;
--						laneline_width_sure_0 <= '1';
----					else
----						laneline_half_state <= 0;
----						laneline_width_sure <= '0';
----					end if;	
--				when 1 =>
--					laneline_half_logic_0 <= CONV_STD_LOGIC_VECTOR(laneline_half_two_0, 11);
--					laneline_width_logic_0 <= CONV_STD_LOGIC_VECTOR(laneline_width_0, 9);
--					laneline_half_state_0 <= 2;
--				when 2 =>
--					laneline_half_0 <= CONV_INTEGER(laneline_half_logic_0(10 downto 1));
--					laneline_quarter_0 <= CONV_INTEGER(laneline_width_logic_0(8 downto 2));
--					laneline_half_state_0 <= 3;
--				when 3 =>	
----					laneline_pointrange_L <= laneline_R_out - laneline_quarter;
----					laneline_pointrange_R <= laneline_L_out + laneline_quarter;
--					laneline_pointrange_L_0 <= 0;
--					laneline_pointrange_R_0 <= 640;
--					laneline_half_en_0 <= 2;
--					laneline_halfsure_en_0 <= '1';								
--				when others => null;	
--			end case;	
--		elsif shift_state_0 = 1 or shift_state_0 = 2 or shift_state_0 = 5 then
--			laneline_half_en_0 <= 1;
--			laneline_half_state_0 <= 0;
--			laneline_halfsure_en_0 <= '0';
--		end if;
--	end if;
--end process;	
--
--process(rst_system,clk_video)--delay_1s_cnt_0
--begin
--	if rst_system = '0' then
--		delay_1s_cnt_0 <= 0;
--	elsif rising_edge(clk_video) then
--		if shift_state_0 = 1 or shift_state_0 = 2 then
--			if delay_1s_cnt_0 < 13500000 then
--				delay_1s_cnt_0 <= delay_1s_cnt_0 + 1;
--			else
--				delay_1s_cnt_0 <= 0;
--			end if;	
--		else
--			delay_1s_cnt_0 <= 0;
--		end if;	
--	end if;
--end process;	
--
--process(rst_system,clk_video)--shift_state_0 => 0:middle 1:big left shift 2:big right shift 3:little left shift 4:little right shift 5:unusual
--begin
--	if rst_system = '0' then
--		shift_state_0 <= 0;
--        warning_limit_cnt <= 0;
--        warning_limit_cnt_en <= '0';
--	elsif rising_edge(clk_video) then
--        case system_state is -- system_state => 0 : disable , 1 : setup mode , 2 : system working
--            when 0 => shift_state_0 <= 5;
--            when 1 => shift_state_0 <= 5;
--            when 2 =>
--                --if warning_limit_cnt > 20 then
--                    --shift_state_0 <= 5;
--                --els
--                if cnt_h_sync_vga < 640 and cnt_v_sync_vga < 480 and lanelinefilter_0 = 0 and delay_1s_cnt_0 = 0 and laneline_width_en_0 = '1' then	
--        --			if ((h_line_2_out > laneline_R_out_0)  and (laneline_R_out_0 > laneline_R_out_1)  and (laneline_R_out_1 > laneline_R_out_2)) or 		
--        --				((h_line_3_out > laneline_L_out_0)  and (laneline_L_out_0 > laneline_L_out_1)  and (laneline_L_out_1 > laneline_L_out_2)) then	
--        --			if ((h_line_2_out > laneline_R_out_0 + 10) and (h_line_2_out > laneline_R_out_1 + 20) and (h_line_2_out > laneline_R_out_0 + 30)) or 
--        --				((h_line_3_out > laneline_L_out_0 + 10) and (h_line_3_out > laneline_L_out_1 + 20) and (h_line_3_out > laneline_L_out_1 + 30)) then
--        --			if	((h_line_2_out > laneline_R_out_7 + 60) and (h_line_2_out > laneline_R_out_3 + 30) and h_line_2_out < laneline_R_out_3 + 100 and laneline_sure = '1') and 
--        --				((h_line_3_out > laneline_L_out_7 + 60) and (h_line_3_out > laneline_L_out_3 + 30) and h_line_3_out < laneline_L_out_3 + 100 and laneline_sure_L_1 = '1')  then
--        --				shift_state <= 1;
--                        
--        --			elsif ((h_line_2_out < laneline_R_out_0)  and (laneline_R_out_0 < laneline_R_out_1)  and (laneline_R_out_1 < laneline_R_out_0 )) or  
--        --					((h_line_3_out < laneline_L_out_0)  and (laneline_L_out_0 < laneline_L_out_1)  and (laneline_L_out_1 < laneline_L_out_2))then
--        --			elsif ((h_line_2_out < laneline_R_out_0 - 10)  and (h_line_2_out < laneline_R_out_1 - 20) and (h_line_2_out < laneline_R_out_0 - 30)) or 
--        --					((h_line_3_out < laneline_L_out_0 - 10) and (h_line_3_out < laneline_L_out_1 - 20) and (h_line_3_out < laneline_L_out_2- 30))then
--        --			elsif ((h_line_2_out < laneline_R_out_7 - 60) and (h_line_2_out < laneline_R_out_3 - 30 ) and h_line_2_out > laneline_R_out_3 - 100 and laneline_sure = '1') and 
--        --					((h_line_3_out < laneline_L_out_7 - 60) and (h_line_3_out < laneline_L_out_3 - 30) and h_line_3_out > laneline_L_out_3 - 100 and laneline_sure_L_1 = '1')  then
--        --				shift_state <= 2;
--                    if laneline_R_out_0 >= laneline_half_0 - laneline_quarter_0 - 20 and laneline_R_out_0 <= laneline_half_0 and laneline_halfsure_en_0 = '1' then 
--                        shift_state_0 <= 1;
--                        if warning_limit_cnt_en = '0' then
--                            warning_limit_cnt <= warning_limit_cnt + 1;
--                            warning_limit_cnt_en <= '1';
--                        end if;
--        --			elsif laneline_R_out > 260 and laneline_R_out < 320 and h_line_2_out < laneline_R_out_3 - 30 then 
--        --				shift_state <= 2;	
--        --			elsif laneline_L_out > 320 and laneline_L_out < 380 and h_line_3_out > laneline_L_out_3 + 30 then 
--        --				shift_state <= 1;	
--                    elsif laneline_L_out_0 >= laneline_half_0 and laneline_L_out_0 <= laneline_half_0 + laneline_quarter_0 + 20 and laneline_halfsure_en_0 = '1' then 
--                        shift_state_0 <= 2;
--                        if warning_limit_cnt_en = '0' then
--                            warning_limit_cnt <= warning_limit_cnt + 1;
--                            warning_limit_cnt_en <= '1';
--                        end if;
--                    elsif laneline_R_out_0 >= laneline_half_0 - laneline_quarter_0 - 70 and laneline_R_out_0 <= laneline_half_0 and laneline_halfsure_en_0 = '1' then 
--                        shift_state_0 <= 3;
--                        
--                    elsif laneline_L_out_0 >= laneline_half_0 and laneline_L_out_0 <= laneline_half_0 + laneline_quarter_0 + 70 and laneline_halfsure_en_0 = '1' then 
--                        shift_state_0 <= 4;		
--                    elsif laneline_point_en_0 = '1' then 
--                        shift_state_0 <= 5;
--                    elsif laneline_R_out_0 > 320 or laneline_L_out_0 < 320 then 
--                        shift_state_0 <= 5;
--        --			elsif laneline_width > 500 then 
--        --				shift_state <= 5;
--                    elsif laneline_width_sure_0 = '0' then
--                        shift_state_0 <= 5;
--                    else
--                        shift_state_0 <= 0;	
--                        warning_limit_cnt_en <= '0';
--                    end if;
--                elsif laneline_point_en_0 = '1' then
--                    shift_state_0 <= 0;
--                else
--                    shift_state_0 <= shift_state_0;
--                end if;
--            when others =>shift_state_0 <= 5;
--        end case;
--	end if;
--end process;
----
--
----process(rst_system,clk_video)--LDW example
----begin
--	--if rst_system = '0' then
--		--h_line_0 <= 0;
--		--h_line_0_out <= 0;
--		--h_line_0_cnt <= 0;
--		--h_line_0_en <= '0';
--		--road_cnt0 <= 0;
--		--state_laneline_0 <= start_0;
--	--elsif rising_edge(clk_video) then
--		--if (cnt_h_sync_vga > laneline_pointrange_L and cnt_h_sync_vga < 320 and cnt_v_sync_vga = 360 
--			--and h_line_0_en = '0' and laneline_point_en = '0')then
--			--case state_laneline_0 is
--				--when start_0 =>
--					--if CRB_Sobel_buf_data = '1' then state_laneline_0 <= edge1_0; end if;
--				--when edge1_0 =>
--					--h_line_0_cnt <= h_line_0_cnt + 1;
--					--if CRB_Sobel_buf_data = '0' then state_laneline_0 <= width_0; end if;
--				--when width_0 =>
--					--h_line_0_cnt <= h_line_0_cnt + 1;
--					--if CRB_Sobel_buf_data = '1' then state_laneline_0 <= edge2_0; end if;		
--				--when edge2_0 =>
--					--h_line_0_cnt <= h_line_0_cnt + 1;
--					--if CRB_Sobel_buf_data = '0' then state_laneline_0 <= edgeend_0; end if;
--				--when edgeend_0 =>
--					--if CRB_Sobel_buf_data = '0' then 	
--						--if road_cnt0 < 30 then 
--							--road_cnt0 <= road_cnt0 + 1;
--						--else 
--							--state_laneline_0 <= road0;
--						--end if;	
--					--else	
--						--state_laneline_0 <= start_0; 
--						--h_line_0_cnt <= 0;
--						--road_cnt0 <= 0;
--					--end if;	
--				--when road0 =>	
--					--if h_line_0_cnt > 10 and h_line_0_cnt < 35  then
--						--h_line_0 <= cnt_h_sync_vga - 30;
--						--h_line_0_en <= '1';
--					--else
--						--state_laneline_0 <= start_0;
--						--h_line_0_cnt <= 0;
--						--h_line_0_en <= '0';
--					--end if;					
--				--when others => null;
--			--end case;				
--------			if  (CRB_vga_buf_data_2 ='1' or CRB_Skin_buf_data_2 ='1') or (MT_YS_data >= "00010100" or CRB_MDF_buf_data ='1') then--and (MT_YS_data >= "00110010" or CRB_MDF_buf_data ='1' or car_true = '1') then	
------			if CRB_Sobel_buf_data = '0' then
------				h_line_0_cnt <= h_line_0_cnt + 1;
------			else
------				if h_line_0_cnt > 5 and h_line_0_cnt < 20 then
------					h_line_0 <= cnt_h_sync_vga;
------					h_line_0_en <= '1';
------				else
--------					h_line_0 <= 0;
------					h_line_0_cnt <= 0;
------				end if;	
------			end if;
--		--elsif cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then 
--			--if h_line_0_en = '1' and laneline_point_en = '0' then 
--				--h_line_0_out <= h_line_0;
--			--else	
--				--h_line_0_out <= h_line_0_out;
--			--end if;	
--			--h_line_0_en <= '0';
--			--h_line_0_cnt <= 0;
--			--road_cnt0 <= 0;
--			--state_laneline_0 <= start_0;
--		--end if;
--	--end if;
----end process;
----
----
----process(rst_system,clk_video)
----begin
--	--if rst_system = '0' then
--		--h_line_1 <= 0;
--		--h_line_1_out <= 0;
--		--h_line_1_cnt <= 0;
--		--h_line_1_en <= '0';
--		--road_cnt1 <= 0;
--		--state_laneline_1 <= start_1;
--	--elsif rising_edge(clk_video) then
--		--if (cnt_h_sync_vga > 320 and cnt_h_sync_vga < laneline_pointrange_R and cnt_v_sync_vga = 360 
--			--and h_line_1_en = '0' and laneline_point_en = '0')then 
--			--case state_laneline_1 is
--				--when start_1 =>
--					--if CRB_Sobel_buf_data = '1' then state_laneline_1 <= edge1_1; end if;
--				--when edge1_1 =>
--					--h_line_1_cnt <= h_line_1_cnt + 1;
--					--if CRB_Sobel_buf_data = '0' then state_laneline_1 <= width_1; end if;
--				--when width_1 =>
--					--h_line_1_cnt <= h_line_1_cnt + 1;
--					--if CRB_Sobel_buf_data = '1' then state_laneline_1 <= edge2_1; end if;	
--				--when edge2_1 =>
--					--h_line_1_cnt <= h_line_1_cnt + 1;
--					--if CRB_Sobel_buf_data = '0' then state_laneline_1 <= edgeend_1; end if;	
--				--when edgeend_1 =>
--					--if CRB_Sobel_buf_data = '0' then 	
--						--if road_cnt1 < 30 then 
--							--road_cnt1 <= road_cnt1 + 1;
--						--else 
--							--state_laneline_1 <= road1;
--						--end if;	
--					--else	
--						--state_laneline_1 <= start_1; 
--						--h_line_1_cnt <= 0;
--						--road_cnt1 <= 0;
--					--end if;
--				--when road1 =>
--					--if h_line_1_cnt > 10 and h_line_1_cnt < 35 and cnt_h_sync_vga > h_line_0 + 200 then
--						--h_line_1 <= cnt_h_sync_vga - 30;
--						--h_line_1_en <= '1';
--					--else
--						--state_laneline_1 <= start_1;
--						--h_line_1_cnt <= 0;
--						--h_line_1_en <= '0';
--					--end if;	
--				--when others => null;
--			--end case;		
--------			if  (CRB_vga_buf_data_2 ='1' or CRB_Skin_buf_data_2 ='1') or (MT_YS_data >= "00010100" or CRB_MDF_buf_data ='1') then--and (MT_YS_data >= "00110010" or CRB_MDF_buf_data ='1' or car_true = '1') then	
------			if CRB_Sobel_buf_data = '0' then
------				h_line_1_cnt <= h_line_1_cnt + 1;
------			else
------				if h_line_1_cnt > 5 and h_line_1_cnt < 20 and cnt_h_sync_vga > h_line_0 + 100 then
------					h_line_1 <= cnt_h_sync_vga;
------					h_line_1_en <= '1';
------				else
--------					h_line_1 <= 0;
------					h_line_1_cnt <= 0;
------				end if;	
------			end if;
--		--elsif cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then 
--			--if h_line_1_en = '1' and laneline_point_en = '0' then 
--				--h_line_1_out <= h_line_1;
--			--else	
--				--h_line_1_out <= h_line_1_out;
--			--end if;	
--			--h_line_1_en <= '0';
--			--h_line_1_cnt <= 0;
--			--road_cnt1 <= 0;
--			--state_laneline_1 <= start_1;
--		--end if;
--	--end if;
----end process;
----
----process(rst_system,clk_video)
----begin
--	--if rst_system = '0' then
--		--h_line_2 <= 0;
--		--h_line_2_out <= 0;
--		--h_line_2_cnt <= 0;
--		--h_line_2_en <= '0';
--		--road_cnt2 <= 0;
--		--state_laneline_2 <= start_2;
--	--elsif rising_edge(clk_video) then
--		--if (cnt_h_sync_vga > laneline_pointrange_L and cnt_h_sync_vga < 320 and cnt_v_sync_vga = 350 
--			--and h_line_2_en = '0' and laneline_point_en = '0')then
--			--case state_laneline_2 is
--				--when start_2 =>
--					--if CRB_Sobel_buf_data = '1' then state_laneline_2 <= edge1_2; end if;
--				--when edge1_2 =>
--					--h_line_2_cnt <= h_line_2_cnt + 1;
--					--if CRB_Sobel_buf_data = '0' then state_laneline_2 <= width_2; end if;
--				--when width_2 =>
--					--h_line_2_cnt <= h_line_2_cnt + 1;
--					--if CRB_Sobel_buf_data = '1' then state_laneline_2 <= edge2_2; end if;	
--				--when edge2_2 =>
--					--h_line_2_cnt <= h_line_2_cnt + 1;
--					--if CRB_Sobel_buf_data = '0' then state_laneline_2 <= edgeend_2; end if;		
--				--when edgeend_2 =>
--					--if CRB_Sobel_buf_data = '0' then 	
--						--if road_cnt2 < 30 then 
--							--road_cnt2 <= road_cnt2 + 1;
--						--else 
--							--state_laneline_2 <= road2;
--						--end if;	
--					--else	
--						--state_laneline_2 <= start_2; 
--						--h_line_2_cnt <= 0;
--						--road_cnt2 <= 0;
--					--end if;				
--				--when road2 =>
--					--if h_line_2_cnt > 10 and h_line_2_cnt < 35 then
--						--h_line_2 <= cnt_h_sync_vga - 30;
--						--h_line_2_en <= '1';
--					--else
--						--state_laneline_2 <= start_2;
--						--h_line_2_cnt <= 0;
--						--h_line_2_en <= '0';
--					--end if;				
--				--when others => null;
--			--end case;
--------			if  (CRB_vga_buf_data_2 ='1' or CRB_Skin_buf_data_2 ='1') or (MT_YS_data >= "00010100" or CRB_MDF_buf_data ='1') then--and (MT_YS_data >= "00110010" or CRB_MDF_buf_data ='1' or car_true = '1') then	
------			if CRB_Sobel_buf_data = '0' then
------				h_line_2_cnt <= h_line_2_cnt + 1;
------			else
------				if h_line_2_cnt > 5 and h_line_2_cnt < 20  then
------					h_line_2 <= cnt_h_sync_vga;
------					h_line_2_en <= '1';
------				else
--------					h_line_2 <= 0;
------					h_line_2_cnt <= 0;
------				end if;	
------			end if;
--		--elsif cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then 
--			--if h_line_2_en = '1' and laneline_point_en = '0' then 
--				--h_line_2_out <= h_line_2;
--			--else	
--				--h_line_2_out <= h_line_2_out;
--			--end if;	
--			--h_line_2_en <= '0';
--			--h_line_2_cnt <= 0;
--			--road_cnt2 <= 0;
--			--state_laneline_2 <= start_2;
--		--end if;
--	--end if;
----end process;
----
----process(rst_system,clk_video)
----begin
--	--if rst_system = '0' then
--		--h_line_3 <= 0;
--		--h_line_3_out <= 0;
--		--h_line_3_cnt <= 0;
--		--h_line_3_en <= '0';
--		--road_cnt3 <= 0;
--		--state_laneline_3 <= start_3;
--	--elsif rising_edge(clk_video) then
--		--if (cnt_h_sync_vga > 320 and cnt_h_sync_vga < laneline_pointrange_R and cnt_v_sync_vga = 350 
--			--and h_line_3_en = '0' and laneline_point_en = '0')then 
--			--case state_laneline_3 is
--				--when start_3 =>
--					--if CRB_Sobel_buf_data = '1' then state_laneline_3 <= edge1_3; end if;
--				--when edge1_3 =>
--					--h_line_3_cnt <= h_line_3_cnt + 1;
--					--if CRB_Sobel_buf_data = '0' then state_laneline_3 <= width_3; end if;
--				--when width_3 =>
--					--h_line_3_cnt <= h_line_3_cnt + 1;
--					--if CRB_Sobel_buf_data = '1' then state_laneline_3 <= edge2_3; end if;	
--				--when edge2_3 =>
--					--h_line_3_cnt <= h_line_3_cnt + 1;
--					--if CRB_Sobel_buf_data = '0' then state_laneline_3 <= edgeend_3; end if;	
--				--when edgeend_3 => 
--					--if CRB_Sobel_buf_data = '0' then 	
--						--if road_cnt3 < 30 then 
--							--road_cnt3 <= road_cnt3 + 1;
--						--else 
--							--state_laneline_3 <= road3;
--						--end if;	
--					--else	
--						--state_laneline_3 <= start_3; 
--						--h_line_3_cnt <= 0;
--						--road_cnt3 <= 0;
--					--end if;	
--				--when road3 =>
--					--if h_line_3_cnt > 10 and h_line_3_cnt < 35 and cnt_h_sync_vga > h_line_2 + 200 then
--						--h_line_3 <= cnt_h_sync_vga - 30;
--						--h_line_3_en <= '1';
--					--else
--						--state_laneline_3 <= start_3;
--						--h_line_3_cnt <= 0;
--						--h_line_3_en <= '0';
--					--end if;					
--				--when others => null;
--			--end case;
--------			if  (CRB_vga_buf_data_2 ='1' or CRB_Skin_buf_data_2 ='1') or (MT_YS_data >= "00010100" or CRB_MDF_buf_data ='1') then--and (MT_YS_data >= "00110010" or CRB_MDF_buf_data ='1' or car_true = '1') then	
------			if CRB_Sobel_buf_data = '0' then
------				h_line_3_cnt <= h_line_3_cnt + 1;
------			else
------				if h_line_3_cnt > 5 and h_line_3_cnt < 20 and cnt_h_sync_vga > h_line_2 + 100 then
------					h_line_3 <= cnt_h_sync_vga;
------					h_line_3_en <= '1';
------				else
--------					h_line_3 <= 0;
------					h_line_3_cnt <= 0;
------				end if;	
------			end if;
--		--elsif cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then 
--			--if h_line_3_en = '1' and laneline_point_en = '0' then 
--				--h_line_3_out <= h_line_3;
--			--else	
--				--h_line_3_out <= h_line_3_out;
--			--end if;				
--			--h_line_3_en <= '0';
--			--h_line_3_cnt <= 0;
--			--road_cnt3 <= 0;
--			--state_laneline_3 <= start_3;
--		--end if;
--	--end if;
----end process;
----
----process(rst_system,clk_video) ---debug point too much
----begin
--	--if rst_system = '0' then
--		--laneline_point_cnt <= 0;
--		--laneline_point_en <= '0';
--	--elsif rising_edge(clk_video) then
--		--if cnt_h_sync_vga > 100 and cnt_h_sync_vga < 500 and (cnt_v_sync_vga > 320 and cnt_v_sync_vga < 360) and CRB_Sobel_buf_data = '1'then	
--			--if laneline_point_cnt < 2000 then
--				--laneline_point_cnt <= laneline_point_cnt + 1;
--			--else
--				--laneline_point_cnt <= laneline_point_cnt;
--			--end if;	
--		--elsif cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then
--			--laneline_point_cnt <= 0;
--			--if laneline_point_cnt > 450 then
--				--laneline_point_en <= '1';
--			--else
--				--laneline_point_en <= '0';
--			--end if;	
--		--end if;
--	--end if;
----end process;
----
----process(rst_system,clk_video)
----begin
--	--if rst_system = '0' then
--		--laneline_sure <= '1';
--		--laneline_cnt <= 0;
--	--elsif rising_edge(clk_video) then
--		--if cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then	
--			--if h_line_0_out < h_line_2_out and h_line_0_out + 20 > h_line_2_out and h_line_0_en = '1' and h_line_2_en = '1' then 
--				--laneline_sure <= '1';
--				--laneline_cnt <= 0;
--			--else
--				--if laneline_cnt < 60 then
--					--laneline_cnt <= laneline_cnt + 1;
--					--laneline_sure <= '1';
--				--else
--					--laneline_sure <= '0';
--					--laneline_cnt <= 0;
--				--end if;
--			--end if;
--		--else
--			--laneline_cnt <= laneline_cnt;
--		--end if;
--	--end if;
----end process;
----
----process(rst_system,clk_video)
----begin
--	--if rst_system = '0' then
--		--laneline_sure_L_1 <= '1';
--		--laneline_cnt_1 <= 0;
--	--elsif rising_edge(clk_video) then
--		--if cnt_h_sync_vga = 640 and cnt_v_sync_vga = 480 then	
--			--if h_line_1_out > h_line_3_out and h_line_1_out - 20 < h_line_3_out and h_line_1_en = '1' and h_line_3_en = '1' then 
--				--laneline_sure_L_1 <= '1';
--				--laneline_cnt_1 <= 0;
--			--else
--				--if laneline_cnt_1 < 60 then
--					--laneline_cnt_1 <= laneline_cnt_1 + 1;
--					--laneline_sure_L_1 <= '1';
--				--else
--					--laneline_sure_L_1 <= '0';
--					--laneline_cnt_1 <= 0;
--				--end if;
--			--end if;
--		--else
--			--laneline_cnt_1 <= laneline_cnt_1;
--		--end if;
--	--end if;
----end process;
----
----process(rst_system,clk_video)-- store buffer
----begin
--	--if rst_system = '0' then
--		--laneline_R_out <= 0;
--		--laneline_L_out <= 0;
--		--lanelinefilter <= 0;
--		--laneline_R_out_four <= 0;
--		--laneline_L_out_four <= 0;
--		--laneline_R_out_logic <= "000000000000";
--		--laneline_L_out_logic <= "000000000000";
--		--laneline_R_out_0 <= 0;
--		--laneline_R_out_1 <= 0;
--		--laneline_R_out_2 <= 0;
--		--laneline_R_out_3 <= 0; 
--		--laneline_R_out_4 <= 0; 
--		--laneline_R_out_5 <= 0; 
--		--laneline_R_out_6 <= 0; 
--		--laneline_R_out_7 <= 0; 
--		--laneline_L_out_0 <= 0;
--		--laneline_L_out_1 <= 0;
--		--laneline_L_out_2 <= 0;
--		--laneline_L_out_3 <= 0;
--		--laneline_L_out_4 <= 0;
--		--laneline_L_out_5 <= 0;
--		--laneline_L_out_6 <= 0;
--		--laneline_L_out_7 <= 0;
--	--elsif rising_edge(clk_video) then
--		--if cnt_h_sync_vga < 640 and cnt_v_sync_vga > 360 and cnt_v_sync_vga < 480 and (laneline_sure = '1' or laneline_sure_L_1 = '1')then	
--			--case lanelinefilter is
--				--when 0 =>
--					--laneline_R_out_four  <= h_line_2_out + laneline_R_out_0 + laneline_R_out_1 + laneline_R_out_2;
--					--laneline_L_out_four <= h_line_3_out + laneline_L_out_0 + laneline_L_out_1 + laneline_L_out_2;
--					--lanelinefilter <= 1;
--				--when 1 =>
--					--laneline_R_out_0 <= h_line_2_out;
--					--laneline_R_out_1 <= laneline_R_out_0;
--					--laneline_R_out_2 <= laneline_R_out_1;
--					--laneline_R_out_3 <= laneline_R_out_2;
--					--laneline_R_out_4 <= laneline_R_out_3;
--					--laneline_R_out_5 <= laneline_R_out_4;
--					--laneline_R_out_6 <= laneline_R_out_5;
--					--laneline_R_out_7 <= laneline_R_out_6;
--					--laneline_L_out_0 <= h_line_3_out;
--					--laneline_L_out_1 <= laneline_L_out_0;
--					--laneline_L_out_2 <= laneline_L_out_1;	
--					--laneline_L_out_3 <= laneline_L_out_2;
--					--laneline_L_out_4 <= laneline_L_out_3;
--					--laneline_L_out_5 <= laneline_L_out_4;
--					--laneline_L_out_6 <= laneline_L_out_5;
--					--laneline_L_out_7 <= laneline_L_out_6;
--					--lanelinefilter <= 2;					
--				--when 2 =>
--					--laneline_R_out_logic <= CONV_STD_LOGIC_VECTOR(laneline_R_out_four, 12);
--					--laneline_L_out_logic <= CONV_STD_LOGIC_VECTOR(laneline_L_out_four, 12);
--					--lanelinefilter <= 3;
--				--when 3 =>
--					--laneline_R_out <= CONV_INTEGER(laneline_R_out_logic(11 downto 2));
--					--laneline_L_out <= CONV_INTEGER(laneline_L_out_logic(11 downto 2));	
--					--
--				--when others => null;
--			--end case;
--		--elsif cnt_h_sync_vga > 640 and cnt_v_sync_vga > 480 then 
--			--lanelinefilter <= 0;
--		--end if;
--	--end if;
----end process;
----
----process(rst_system,clk_video)
----begin
--	--if rst_system = '0' then
--		--laneline_width_x <= 240;
--		--laneline_width_en <= '1';
--	--elsif rising_edge(clk_video) then
--		--if shift_state = 1 or shift_state = 2 then
--			--if laneline_width_x + 20 > laneline_width and laneline_width_x - 20 < laneline_width then
--				--laneline_width_en <= '1';
--			--else
--				--laneline_width_x <= laneline_L_out - laneline_R_out;
--				--laneline_width_en <= '0';
--			--end if;
--		--else
--			--laneline_width_en <= '1';
--		--end if;	
--	--end if;
----end process;	
----
----process(rst_system,clk_video)
----begin
--	--if rst_system = '0' then
--		--laneline_half_state <= 0;
--		--laneline_half <= 320;
--		--laneline_quarter <= 80;
--		--laneline_half_two <= 0;
--		--laneline_half_logic <= "00000000000";
--		--laneline_half_en <= 0;
--		--laneline_halfsure_en <= '1';
--		--
--		--laneline_width <= 240;
--		--laneline_width_sure <= '1';
--		--laneline_width_logic <= "000000000";
--		--
--		--laneline_pointrange_L <= 0;
--		--laneline_pointrange_R <= 640;
--	--elsif rising_edge(clk_video) then
--		--if cnt_h_sync_vga < 640 and cnt_v_sync_vga < 350 and laneline_half_en = 1 and shift_state = 0 and delay_1s_cnt = 0 then
--			--
--			--case laneline_half_state is 
--				--when 0 =>
--					--laneline_half_two <= laneline_R_out + laneline_L_out;
------					if laneline_width > laneline_L_out - laneline_R_out - 30 and laneline_width < laneline_L_out - laneline_R_out + 30 then
--						--laneline_width <= laneline_L_out - laneline_R_out;
--						--laneline_half_state <= 1;
--						--laneline_width_sure <= '1';
------					else
------						laneline_half_state <= 0;
------						laneline_width_sure <= '0';
------					end if;	
--				--when 1 =>
--					--laneline_half_logic <= CONV_STD_LOGIC_VECTOR(laneline_half_two, 11);
--					--laneline_width_logic <= CONV_STD_LOGIC_VECTOR(laneline_width, 9);
--					--laneline_half_state <= 2;
--				--when 2 =>
--					--laneline_half <= CONV_INTEGER(laneline_half_logic(10 downto 1));
--					--laneline_quarter <= CONV_INTEGER(laneline_width_logic(8 downto 2));
--					--laneline_half_state <= 3;
--				--when 3 =>	
------					laneline_pointrange_L <= laneline_R_out - laneline_quarter;
------					laneline_pointrange_R <= laneline_L_out + laneline_quarter;
--					--laneline_pointrange_L <= 0;
--					--laneline_pointrange_R <= 640;
--					--laneline_half_en <= 2;
--					--laneline_halfsure_en <= '1';								
--				--when others => null;	
--			--end case;	
--		--elsif shift_state = 1 or shift_state = 2 or shift_state = 5 then
--			--laneline_half_en <= 1;
--			--laneline_half_state <= 0;
--			--laneline_halfsure_en <= '0';
--		--end if;
--	--end if;
----end process;	
----process(rst_system,clk_video)
----begin
--	--if rst_system = '0' then
--		--delay_1s_cnt <= 0;
--	--elsif rising_edge(clk_video) then
--		--if shift_state = 1 or shift_state = 2 then 
--			--if delay_1s_cnt < 13500000 then 
--				--delay_1s_cnt <= delay_1s_cnt + 1;
--			--else
--				--delay_1s_cnt <= 0;
--			--end if;	
--		--else
--			--delay_1s_cnt <= 0;
--		--end if;	
--	--end if;
----end process;	
----process(rst_system,clk_video)-- 0:middle 1:big left shift 2:big right shift 3:little left shift 4:little right shift 5:unusual
----begin
--	--if rst_system = '0' then
--		--shift_state <= 0;
--	--elsif rising_edge(clk_video) then
--        --case system_state is -- system_state => 0 : disable , 1 : setup mode , 2 : system working
----
--            --when 0 => shift_state <= 5;
--            --when 1 => shift_state <= 5;
--            --when 2 =>
--                --if cnt_h_sync_vga < 640 and cnt_v_sync_vga < 480 and lanelinefilter = 0 and delay_1s_cnt = 0 and laneline_width_en = '1' then	
--        ----			if ((h_line_2_out > laneline_R_out_0)  and (laneline_R_out_0 > laneline_R_out_1)  and (laneline_R_out_1 > laneline_R_out_2)) or 		
--        ----				((h_line_3_out > laneline_L_out_0)  and (laneline_L_out_0 > laneline_L_out_1)  and (laneline_L_out_1 > laneline_L_out_2)) then	
--        ----			if ((h_line_2_out > laneline_R_out_0 + 10) and (h_line_2_out > laneline_R_out_1 + 20) and (h_line_2_out > laneline_R_out_2 + 30)) or 
--        ----				((h_line_3_out > laneline_L_out_0 + 10) and (h_line_3_out > laneline_L_out_1 + 20) and (h_line_3_out > laneline_L_out_1 + 30)) then
--        ----			if	((h_line_2_out > laneline_R_out_7 + 60) and (h_line_2_out > laneline_R_out_3 + 30) and h_line_2_out < laneline_R_out_3 + 100 and laneline_sure = '1') and 
--        ----				((h_line_3_out > laneline_L_out_7 + 60) and (h_line_3_out > laneline_L_out_3 + 30) and h_line_3_out < laneline_L_out_3 + 100 and laneline_sure_L_1 = '1')  then
--        ----				shift_state <= 1;
--                        --
--        ----			elsif ((h_line_2_out < laneline_R_out_0)  and (laneline_R_out_0 < laneline_R_out_1)  and (laneline_R_out_1 < laneline_R_out_2 )) or  
--        ----					((h_line_3_out < laneline_L_out_0)  and (laneline_L_out_0 < laneline_L_out_1)  and (laneline_L_out_1 < laneline_L_out_2))then
--        ----			elsif ((h_line_2_out < laneline_R_out_0 - 10)  and (h_line_2_out < laneline_R_out_1 - 20) and (h_line_2_out < laneline_R_out_2 - 30)) or 
--        ----					((h_line_3_out < laneline_L_out_0 - 10) and (h_line_3_out < laneline_L_out_1 - 20) and (h_line_3_out < laneline_L_out_2- 30))then
--        ----			elsif ((h_line_2_out < laneline_R_out_7 - 60) and (h_line_2_out < laneline_R_out_3 - 30 ) and h_line_2_out > laneline_R_out_3 - 100 and laneline_sure = '1') and 
--        ----					((h_line_3_out < laneline_L_out_7 - 60) and (h_line_3_out < laneline_L_out_3 - 30) and h_line_3_out > laneline_L_out_3 - 100 and laneline_sure_L_1 = '1')  then
--        ----				shift_state <= 2;
--                        --
--                    --if laneline_R_out >= laneline_half - laneline_quarter - 20 and laneline_R_out <= laneline_half and laneline_halfsure_en = '1' then 
--                        --shift_state <= 1;
--        ----			elsif laneline_R_out > 260 and laneline_R_out < 320 and h_line_2_out < laneline_R_out_3 - 30 then 
--        ----				shift_state <= 2;	
--        ----			elsif laneline_L_out > 320 and laneline_L_out < 380 and h_line_3_out > laneline_L_out_3 + 30 then 
--        ----				shift_state <= 1;	
--                    --elsif laneline_L_out >= laneline_half and laneline_L_out <= laneline_half + laneline_quarter + 20 and laneline_halfsure_en = '1' then 
--                        --shift_state <= 2;
--                    --elsif laneline_R_out >= laneline_half - laneline_quarter - 70 and laneline_R_out <= laneline_half and laneline_halfsure_en = '1' then 
--                        --shift_state <= 3;
--                    --elsif laneline_L_out >= laneline_half and laneline_L_out <= laneline_half + laneline_quarter + 70 and laneline_halfsure_en = '1' then 
--                        --shift_state <= 4;		
--                    --elsif laneline_point_en = '1' then 
--                        --shift_state <= 5;
--                    --elsif laneline_R_out > 320 or laneline_L_out < 320 then 
--                        --shift_state <= 5;
--        ----			elsif laneline_width > 500 then 
--        ----				shift_state <= 5;
--                    --elsif laneline_width_sure = '0' then
--                        --shift_state <= 5;
--                    --else
--                        --shift_state <= 0;	
--                    --end if;
--                --elsif laneline_point_en = '1' then
--                    --shift_state <= 0;
--                --else
--                    --shift_state <= shift_state;
--                --end if;
--            --when others =>shift_state <= 5;
--        --end case;
--	--end if;
----end process;
----------------------------------------lane line---------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------  cnt_v_sync_vga = 360    end     -----------------------------------------
-----------------------------------------------------------------------------------------------------------------------------

--
--process(clk_video)--system_state
--begin
--	if rising_edge(clk_video) then
--        if disable_but = '1' then
--            system_state <= 2;
--        else
--            system_state <= 1;
--        end if;
--	end if;
--end process;	
--

--VGA-Sync---------------------------------------------------------------------------------------------------
process(rst_system, clk_video)--h_sync_vga & v_sync_vga
begin
if rst_system = '0' then
	h_sync_vga <= '1';
	v_sync_vga <= '1';
else
	if rising_edge(clk_video) then
		if (cnt_vga_en = '1' and sync_vga_en = '1') then
			if (cnt_h_sync_vga >= 705 and cnt_h_sync_vga < 808)then --640
				h_sync_vga <= '1';
			else
				h_sync_vga <= '0';
			end if;
			
			if (cnt_v_sync_vga >= 494 and cnt_v_sync_vga < 497)then --480
				v_sync_vga <= '1';
				RD_WR_v <= '1';
			else
				v_sync_vga <= '0';
				RD_WR_v <= '0';
			end if;
		else
		RD_WR_v<= '1';
			h_sync_vga <= '1';
			v_sync_vga <= '1';
		end if;
	end if;
end if;
end process;
--VGA-Sync---------------------------------------------------------------------------------------------------
--



----------------------------------------select-clk-------------------------------------------------------------------------------------
----------------------------------------select-clk-------------------------------------------------------------------------------------
process(rst_system, clk_video)--clk_video_in & clk_video_cnt
begin
if rst_system = '0' then
	clk_video_in <= '0';
	clk_video_cnt <= "00";
elsif rising_edge(clk_video) then
		if clk_video_cnt = "00" then 
			clk_video_in <= not clk_video_in ;
			clk_video_cnt <= "00";
		else
			clk_video_cnt <= clk_video_cnt + '1';
		end if;
end if;
end process;
-------------------------------------select-clk-----------------------------------------------------------------------------------------
-------------------------------------select-clk-----------------------------------------------------------------------------------------

--
--VGA-RGB-9bit----------------------------------------------------------------------------------------------------
process(rst_system, clk_video)--VGA RGB
begin
if rst_system = '0' then
	r_vga <= "000";
	g_vga <= "000";
	b_vga <= "000";
	buf_vga_Y_out_cnt <= 0;
else
	if rising_edge(clk_video) then
		if (((f_video_en = '0' and black_vga_en = '0') or (f_video_en = '1' and black_vga_en = '1')) and cnt_h_sync_vga < 640 and cnt_v_sync_vga > 1 and cnt_v_sync_vga < 480)and buf_vga_en = '1' then
--		if (f_video_en = '0' and black_vga_en = '0' and cnt_h_sync_vga < 640 and cnt_v_sync_vga > 1 and cnt_v_sync_vga < 480) then
			buf_vga_Y_out_cnt <= buf_vga_Y_out_cnt + 1;
--            if system_state = 1 then
--              if CRB_vga_buf_data_2 = '1' then
--                    r_vga <= "111";
--                    g_vga <= "111";
--                    b_vga <= "111";
                    
                if ( cnt_h_sync_vga > 300 and cnt_h_sync_vga < 320 and cnt_v_sync_vga > 460 and cnt_v_sync_vga < 480) and MPAS_brightness_state = 0 then
                        r_vga <= "000";
                        g_vga <= "000";
                        b_vga <= "111";

                elsif ( cnt_h_sync_vga > 320 and cnt_h_sync_vga < 340 and cnt_v_sync_vga > 460 and cnt_v_sync_vga < 480) and MPAS_brightness_state = 1  then	
                        r_vga <= "000";
                        g_vga <= "111";
                        b_vga <= "000";

                elsif ( cnt_h_sync_vga > 340 and cnt_h_sync_vga < 360 and cnt_v_sync_vga > 460 and cnt_v_sync_vga < 480) and MPAS_brightness_state = 2 then	
                        r_vga <= "111";
                        g_vga <= "000";
                        b_vga <= "000";
                
                elsif ( cnt_h_sync_vga > 0 and cnt_h_sync_vga < 640 and cnt_v_sync_vga > 318 and cnt_v_sync_vga < 322) then	--light line
                    if MPAS_brightness_state = 2 then
                            r_vga <= "111";
                            g_vga <= "111";
                            b_vga <= "111";
                    end if;
                elsif (( cnt_h_sync_vga > 0 and cnt_h_sync_vga < 80 and (cnt_v_sync_vga = 0 or cnt_v_sync_vga = 80))or
                        ( cnt_v_sync_vga > 0 and cnt_v_sync_vga < 80 and (cnt_h_sync_vga = 0 or cnt_h_sync_vga = 80))) and MPAS_squarelight_7 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";				
                elsif (( cnt_h_sync_vga > 80 and cnt_h_sync_vga < 160 and (cnt_v_sync_vga = 0 or cnt_v_sync_vga = 80))or
                        ( cnt_v_sync_vga > 0 and cnt_v_sync_vga < 80 and (cnt_h_sync_vga = 80 or cnt_h_sync_vga = 160))) and MPAS_squarelight_6 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 160 and cnt_h_sync_vga < 240 and (cnt_v_sync_vga = 0 or cnt_v_sync_vga = 80))or
                        ( cnt_v_sync_vga > 0 and cnt_v_sync_vga < 80 and (cnt_h_sync_vga = 160 or cnt_h_sync_vga = 240))) and MPAS_squarelight_5 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 240 and cnt_h_sync_vga < 320 and (cnt_v_sync_vga = 0 or cnt_v_sync_vga = 80))or
                        ( cnt_v_sync_vga > 0 and cnt_v_sync_vga < 80 and (cnt_h_sync_vga = 240 or cnt_h_sync_vga = 320))) and MPAS_squarelight_4 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 320 and cnt_h_sync_vga < 400 and (cnt_v_sync_vga = 0 or cnt_v_sync_vga = 80))or
                        ( cnt_v_sync_vga > 0 and cnt_v_sync_vga < 80 and (cnt_h_sync_vga = 320 or cnt_h_sync_vga = 400))) and MPAS_squarelight_3 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 400 and cnt_h_sync_vga < 480 and (cnt_v_sync_vga = 0 or cnt_v_sync_vga = 80))or
                        ( cnt_v_sync_vga > 0 and cnt_v_sync_vga < 80 and (cnt_h_sync_vga = 400 or cnt_h_sync_vga = 480))) and MPAS_squarelight_2 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 480 and cnt_h_sync_vga < 560 and (cnt_v_sync_vga = 0 or cnt_v_sync_vga = 80))or
                        ( cnt_v_sync_vga > 0 and cnt_v_sync_vga < 80 and (cnt_h_sync_vga = 480 or cnt_h_sync_vga = 560))) and MPAS_squarelight_1 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 560 and cnt_h_sync_vga < 640 and (cnt_v_sync_vga = 0 or cnt_v_sync_vga = 80))or
                        ( cnt_v_sync_vga > 0 and cnt_v_sync_vga < 80 and (cnt_h_sync_vga = 560 or cnt_h_sync_vga = 640))) and MPAS_squarelight_0 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 0 and cnt_h_sync_vga < 80 and (cnt_v_sync_vga = 80 or cnt_v_sync_vga = 160))or
                        ( cnt_v_sync_vga > 80 and cnt_v_sync_vga < 160 and (cnt_h_sync_vga = 0 or cnt_h_sync_vga = 80))) and MPAS_squarelight_15 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 80 and cnt_h_sync_vga < 160 and (cnt_v_sync_vga = 80 or cnt_v_sync_vga = 160))or
                        ( cnt_v_sync_vga > 80 and cnt_v_sync_vga < 160 and (cnt_h_sync_vga = 80 or cnt_h_sync_vga = 160))) and MPAS_squarelight_14 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 160 and cnt_h_sync_vga < 240 and (cnt_v_sync_vga = 80 or cnt_v_sync_vga = 160))or
                        ( cnt_v_sync_vga > 80 and cnt_v_sync_vga < 160 and (cnt_h_sync_vga = 160 or cnt_h_sync_vga = 240))) and MPAS_squarelight_13 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 240 and cnt_h_sync_vga < 320 and (cnt_v_sync_vga = 80 or cnt_v_sync_vga = 160))or
                        ( cnt_v_sync_vga > 80 and cnt_v_sync_vga < 160 and (cnt_h_sync_vga = 240 or cnt_h_sync_vga = 320))) and MPAS_squarelight_12 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 320 and cnt_h_sync_vga < 400 and (cnt_v_sync_vga = 80 or cnt_v_sync_vga = 160))or
                        ( cnt_v_sync_vga > 80 and cnt_v_sync_vga < 160 and (cnt_h_sync_vga = 320 or cnt_h_sync_vga = 400))) and MPAS_squarelight_11 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 400 and cnt_h_sync_vga < 480 and (cnt_v_sync_vga = 80 or cnt_v_sync_vga = 160))or
                        ( cnt_v_sync_vga > 80 and cnt_v_sync_vga < 160 and (cnt_h_sync_vga = 400 or cnt_h_sync_vga = 480))) and MPAS_squarelight_10 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 480 and cnt_h_sync_vga < 560 and (cnt_v_sync_vga = 80 or cnt_v_sync_vga = 160))or
                        ( cnt_v_sync_vga > 80 and cnt_v_sync_vga < 160 and (cnt_h_sync_vga = 480 or cnt_h_sync_vga = 560))) and MPAS_squarelight_9 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 560 and cnt_h_sync_vga < 640 and (cnt_v_sync_vga = 80 or cnt_v_sync_vga = 160))or
                        ( cnt_v_sync_vga > 80 and cnt_v_sync_vga < 160 and (cnt_h_sync_vga = 560 or cnt_h_sync_vga = 640))) and MPAS_squarelight_8 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 0 and cnt_h_sync_vga < 80 and (cnt_v_sync_vga = 160 or cnt_v_sync_vga = 240))or
                        ( cnt_v_sync_vga > 160 and cnt_v_sync_vga < 240 and (cnt_h_sync_vga = 0 or cnt_h_sync_vga = 80))) and MPAS_squarelight_23 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 80 and cnt_h_sync_vga < 160 and (cnt_v_sync_vga = 160 or cnt_v_sync_vga = 240))or
                        ( cnt_v_sync_vga > 160 and cnt_v_sync_vga < 240 and (cnt_h_sync_vga = 80 or cnt_h_sync_vga = 160))) and MPAS_squarelight_22 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 160 and cnt_h_sync_vga < 240 and (cnt_v_sync_vga = 160 or cnt_v_sync_vga = 240))or
                        ( cnt_v_sync_vga > 160 and cnt_v_sync_vga < 240 and (cnt_h_sync_vga = 160 or cnt_h_sync_vga = 240))) and MPAS_squarelight_21 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 240 and cnt_h_sync_vga < 320 and (cnt_v_sync_vga = 160 or cnt_v_sync_vga = 240))or
                        ( cnt_v_sync_vga > 160 and cnt_v_sync_vga < 240 and (cnt_h_sync_vga = 240 or cnt_h_sync_vga = 320))) and MPAS_squarelight_20 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 320 and cnt_h_sync_vga < 400 and (cnt_v_sync_vga = 160 or cnt_v_sync_vga = 240))or
                        ( cnt_v_sync_vga > 160 and cnt_v_sync_vga < 240 and (cnt_h_sync_vga = 320 or cnt_h_sync_vga = 400))) and MPAS_squarelight_19 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 400 and cnt_h_sync_vga < 480 and (cnt_v_sync_vga = 160 or cnt_v_sync_vga = 240))or
                        ( cnt_v_sync_vga > 160 and cnt_v_sync_vga < 240 and (cnt_h_sync_vga = 400 or cnt_h_sync_vga = 480))) and MPAS_squarelight_18 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 480 and cnt_h_sync_vga < 560 and (cnt_v_sync_vga = 160 or cnt_v_sync_vga = 240))or
                        ( cnt_v_sync_vga > 160 and cnt_v_sync_vga < 240 and (cnt_h_sync_vga = 480 or cnt_h_sync_vga = 560))) and MPAS_squarelight_17 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 560 and cnt_h_sync_vga < 640 and (cnt_v_sync_vga = 160 or cnt_v_sync_vga = 240))or
                        ( cnt_v_sync_vga > 160 and cnt_v_sync_vga < 240 and (cnt_h_sync_vga = 560 or cnt_h_sync_vga = 640))) and MPAS_squarelight_16 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 0 and cnt_h_sync_vga < 80 and (cnt_v_sync_vga = 240 or cnt_v_sync_vga = 320))or
                        ( cnt_v_sync_vga > 240 and cnt_v_sync_vga < 320 and (cnt_h_sync_vga = 0 or cnt_h_sync_vga = 80))) and MPAS_squarelight_31 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 80 and cnt_h_sync_vga < 160 and (cnt_v_sync_vga = 240 or cnt_v_sync_vga = 320))or
                        ( cnt_v_sync_vga > 240 and cnt_v_sync_vga < 320 and (cnt_h_sync_vga = 80 or cnt_h_sync_vga = 160))) and MPAS_squarelight_30 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 160 and cnt_h_sync_vga < 240 and (cnt_v_sync_vga = 240 or cnt_v_sync_vga = 320))or
                        ( cnt_v_sync_vga > 240 and cnt_v_sync_vga < 320 and (cnt_h_sync_vga = 160 or cnt_h_sync_vga = 240))) and MPAS_squarelight_29 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 240 and cnt_h_sync_vga < 320 and (cnt_v_sync_vga = 240 or cnt_v_sync_vga = 320))or
                        ( cnt_v_sync_vga > 240 and cnt_v_sync_vga < 320 and (cnt_h_sync_vga = 240 or cnt_h_sync_vga = 320))) and MPAS_squarelight_28 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 320 and cnt_h_sync_vga < 400 and (cnt_v_sync_vga = 240 or cnt_v_sync_vga = 320))or
                        ( cnt_v_sync_vga > 240 and cnt_v_sync_vga < 320 and (cnt_h_sync_vga = 320 or cnt_h_sync_vga = 400))) and MPAS_squarelight_27 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 400 and cnt_h_sync_vga < 480 and (cnt_v_sync_vga = 240 or cnt_v_sync_vga = 320))or
                        ( cnt_v_sync_vga > 240 and cnt_v_sync_vga < 320 and (cnt_h_sync_vga = 400 or cnt_h_sync_vga = 480))) and MPAS_squarelight_26 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 480 and cnt_h_sync_vga < 560 and (cnt_v_sync_vga = 240 or cnt_v_sync_vga = 320))or
                        ( cnt_v_sync_vga > 240 and cnt_v_sync_vga < 320 and (cnt_h_sync_vga = 480 or cnt_h_sync_vga = 560))) and MPAS_squarelight_25 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                elsif (( cnt_h_sync_vga > 560 and cnt_h_sync_vga < 640 and (cnt_v_sync_vga = 240 or cnt_v_sync_vga = 320))or
                        ( cnt_v_sync_vga > 240 and cnt_v_sync_vga < 320 and (cnt_h_sync_vga = 560 or cnt_h_sync_vga = 640))) and MPAS_squarelight_24 = '1' then	
                        r_vga <= "111";
                        g_vga <= "111";
                        b_vga <= "111";
                else
                    r_vga <= buf_vga_Y(buf_vga_Y_out_cnt);
                    g_vga <= buf_vga_Y(buf_vga_Y_out_cnt);
                    b_vga <= buf_vga_Y(buf_vga_Y_out_cnt);
                end if;
--            elsif system_state = 2 or system_state = 0 then
--                if ((cnt_h_sync_vga > (ld_focus_x - focus_range) and cnt_h_sync_vga < (ld_focus_x + focus_range) and cnt_v_sync_vga = (ld_focus_y - focus_range) )or 
--                      (cnt_h_sync_vga > (ld_focus_x - focus_range) and cnt_h_sync_vga < (ld_focus_x + focus_range) and cnt_v_sync_vga = (ld_focus_y + focus_range) )or
--                      (cnt_v_sync_vga > (ld_focus_y - focus_range) and cnt_v_sync_vga < (ld_focus_y + focus_range) and cnt_h_sync_vga = (ld_focus_x + focus_range) )or 
--                      (cnt_v_sync_vga > (ld_focus_y - focus_range) and cnt_v_sync_vga < (ld_focus_y + focus_range) and cnt_h_sync_vga = (ld_focus_x - focus_range) )or
--                      (cnt_h_sync_vga > (rd_focus_x - focus_range) and cnt_h_sync_vga < (rd_focus_x + focus_range) and cnt_v_sync_vga = (rd_focus_y - focus_range) )or 
--                      (cnt_h_sync_vga > (rd_focus_x - focus_range) and cnt_h_sync_vga < (rd_focus_x + focus_range) and cnt_v_sync_vga = (rd_focus_y + focus_range) )or
--                      (cnt_v_sync_vga > (rd_focus_y - focus_range) and cnt_v_sync_vga < (rd_focus_y + focus_range) and cnt_h_sync_vga = (rd_focus_x + focus_range) )or 
--                      (cnt_v_sync_vga > (rd_focus_y - focus_range) and cnt_v_sync_vga < (rd_focus_y + focus_range) and cnt_h_sync_vga = (rd_focus_x - focus_range) ))and (system_state = 1 or system_state = 0) then
--                    r_vga <= "111";
--                    g_vga <= "011";
--                    b_vga <= "000";
--                elsif((cnt_h_sync_vga > (lu_focus_x - focus_range) and cnt_h_sync_vga < (lu_focus_x + focus_range) and cnt_v_sync_vga = (lu_focus_y - focus_range) )or 
--                      (cnt_h_sync_vga > (lu_focus_x - focus_range) and cnt_h_sync_vga < (lu_focus_x + focus_range) and cnt_v_sync_vga = (lu_focus_y + focus_range) )or
--                      (cnt_v_sync_vga > (lu_focus_y - focus_range) and cnt_v_sync_vga < (lu_focus_y + focus_range) and cnt_h_sync_vga = (lu_focus_x + focus_range) )or 
--                      (cnt_v_sync_vga > (lu_focus_y - focus_range) and cnt_v_sync_vga < (lu_focus_y + focus_range) and cnt_h_sync_vga = (lu_focus_x - focus_range) )or
--                      (cnt_h_sync_vga > (ru_focus_x - focus_range) and cnt_h_sync_vga < (ru_focus_x + focus_range) and cnt_v_sync_vga = (ru_focus_y - focus_range) )or 
--                      (cnt_h_sync_vga > (ru_focus_x - focus_range) and cnt_h_sync_vga < (ru_focus_x + focus_range) and cnt_v_sync_vga = (ru_focus_y + focus_range) )or
--                      (cnt_v_sync_vga > (ru_focus_y - focus_range) and cnt_v_sync_vga < (ru_focus_y + focus_range) and cnt_h_sync_vga = (ru_focus_x + focus_range) )or 
--                      (cnt_v_sync_vga > (ru_focus_y - focus_range) and cnt_v_sync_vga < (ru_focus_y + focus_range) and cnt_h_sync_vga = (ru_focus_x - focus_range) ))and (system_state = 1 or system_state = 0) then
--                    r_vga <= "111";
--                    g_vga <= "011";
--                    b_vga <= "011";
--                    
--                    
--                    
--    --			elsif (cnt_h_sync_vga > 145 and cnt_h_sync_vga < 520 and cnt_v_sync_vga > 95 and 
--    --					cnt_v_sync_vga < 365 and MPAS_cnt >= 50 and MPAS_cnt <= 200 ) and 
--    --					(MT_YS_data >= "00110010" or CRB_MDF_buf_data ='1' or car_true = '1') then
--    --				r_vga <= "000";
--    --				g_vga <= "111";
--    --				b_vga <= "000";
--
--
--    --			elsif ( MPAS_cnt >= 50 and MPAS_cnt <= 200 )and (MT_YS_data >= "00110010" or CRB_MDF_buf_data ='1' or car_true = '1') then
--    --				r_vga <= "000";
--    --				g_vga <= "111";
--    --				b_vga <= "000";
--    --			elsif (cnt_h_sync_vga > 145 and cnt_h_sync_vga < 520 and cnt_v_sync_vga > 95 and 
--    --					cnt_v_sync_vga < 365 and  CRB_vga_buf_data ='1' )then
--    --				r_vga <= "111";
--    --				g_vga <= "000";
--    --				b_vga <= "111";
--
--    ---------------------------------------------------------lane line----------------------------------------------------
--    ---------------------------------------------***************************************
--                elsif rst_button_click_times_LDW = 3 then
--                    if CRB_Sobel_buf_data ='1' then
--                        r_vga <= "111";
--                        g_vga <= "111";
--                        b_vga <= "111";
--        -----------------------------------------------------------------------------------------------------------------------------
--        -------------------------------------      cnt_v_sync_vga = 360  begin     --------------------------------------------------
--        ----------------------------------------------------------------------------------------------------------------------------- 
--                    elsif cnt_h_sync_vga > 0 and cnt_h_sync_vga < 640 and cnt_v_sync_vga = ldw_level_one_base then
--                        r_vga <= "111";
--                        g_vga <= "111";
--                        b_vga <= "111";
--                    elsif cnt_h_sync_vga > 0 and cnt_h_sync_vga < 640 and cnt_v_sync_vga = ldw_level_one_base - ldw_level_range then
--                        r_vga <= "111";
--                        g_vga <= "111";
--                        b_vga <= "111";		
--                    elsif cnt_v_sync_vga > ldw_level_one_base - ldw_level_range and cnt_v_sync_vga < ldw_level_one_base and cnt_h_sync_vga = laneline_half_0 then
--                        r_vga <= "111";
--                        g_vga <= "000";
--                        b_vga <= "000";
--                    elsif cnt_v_sync_vga > ldw_level_one_base - ldw_level_range and cnt_v_sync_vga < ldw_level_one_base and cnt_h_sync_vga = laneline_half_0 - laneline_quarter_0 - 20  then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";
--                    elsif cnt_v_sync_vga > ldw_level_one_base - ldw_level_range and cnt_v_sync_vga < ldw_level_one_base and cnt_h_sync_vga = laneline_half_0 + laneline_quarter_0 + 20 then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";
--                    elsif cnt_v_sync_vga > ldw_level_one_base - ldw_level_range and cnt_v_sync_vga < ldw_level_one_base and cnt_h_sync_vga = laneline_half_0 - laneline_quarter_0 - 70 then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";
--                    elsif cnt_v_sync_vga > ldw_level_one_base - ldw_level_range and cnt_v_sync_vga < ldw_level_one_base and cnt_h_sync_vga = laneline_half_0 + laneline_quarter_0 + 70 then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";
--                    elsif cnt_h_sync_vga > laneline_L_out_0 - 5 and cnt_h_sync_vga < laneline_L_out_0 + 5 and 
--                            cnt_v_sync_vga > ldw_level_one_base - 10 and cnt_v_sync_vga < ldw_level_one_base and laneline_sure_R_0 = '1' and 
--                            (shift_state_0 = 0 or shift_state_0 = 1 or shift_state_0 = 3 or shift_state_0 = 5) then
--                        r_vga <= "000";
--                        g_vga <= "000";
--                        b_vga <= "111";
--                    elsif cnt_h_sync_vga > laneline_L_out_0 - 15 and cnt_h_sync_vga < laneline_L_out_0 + 15 and 
--                            cnt_v_sync_vga > ldw_level_one_base - 30 and cnt_v_sync_vga < ldw_level_one_base and laneline_sure_R_0 = '1' and  shift_state_0 = 2 then
--                        r_vga <= "000";
--                        g_vga <= "000";
--                        b_vga <= "111";
--                        
--                    elsif cnt_h_sync_vga > laneline_L_out_0 - 10 and cnt_h_sync_vga < laneline_L_out_0 + 10 and 
--                            cnt_v_sync_vga > ldw_level_one_base - 20 and cnt_v_sync_vga < ldw_level_one_base and laneline_sure_R_0 = '1' and  shift_state_0 = 4 then
--                        r_vga <= "000";
--                        g_vga <= "000";
--                        b_vga <= "111";
--                    elsif cnt_h_sync_vga > laneline_R_out_0 - 5 and cnt_h_sync_vga < laneline_R_out_0 + 5 and 
--                            cnt_v_sync_vga > ldw_level_one_base - 10 and cnt_v_sync_vga < ldw_level_one_base and laneline_sure_L_0 = '1' and 
--                            (shift_state_0 = 0 or shift_state_0 = 2 or shift_state_0 = 4 or shift_state_0 = 5) then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";
--                        
--                    elsif cnt_h_sync_vga > laneline_R_out_0 - 15 and cnt_h_sync_vga < laneline_R_out_0 + 15 and 
--                            cnt_v_sync_vga > ldw_level_one_base - 30 and cnt_v_sync_vga < ldw_level_one_base and laneline_sure_L_0 = '1' and  shift_state_0 = 1  then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";	
--                        
--                    elsif cnt_h_sync_vga > laneline_R_out_0 - 10 and cnt_h_sync_vga < laneline_R_out_0 + 10 and 
--                            cnt_v_sync_vga > ldw_level_one_base - 20 and cnt_v_sync_vga < ldw_level_one_base and laneline_sure_L_0 = '1' and  shift_state_0 = 3  then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";
--                    elsif cnt_h_sync_vga > 0 and cnt_h_sync_vga < 10 and 
--                            cnt_v_sync_vga > ldw_level_one_base - 10 and cnt_v_sync_vga < ldw_level_one_base and laneline_sure_L_0 = '1' and 
--                            (shift_state_0 = 0 or shift_state_0 = 2 or shift_state_0 = 4 or shift_state_0 = 5) then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";	
--                    elsif cnt_h_sync_vga > 0 and cnt_h_sync_vga < 30 and 
--                            cnt_v_sync_vga > ldw_level_one_base - 30 and cnt_v_sync_vga < ldw_level_one_base and laneline_sure_L_0 = '1' and  shift_state_0 = 1  then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";	
--                        
--                    elsif cnt_h_sync_vga > 0 and cnt_h_sync_vga < 20 and 
--                            cnt_v_sync_vga > ldw_level_one_base - 20 and cnt_v_sync_vga < ldw_level_one_base and laneline_sure_L_0 = '1' and  shift_state_0 = 3  then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";				
--                    elsif cnt_h_sync_vga > 630 and cnt_h_sync_vga < 640 and 
--                            cnt_v_sync_vga > ldw_level_one_base - 10 and cnt_v_sync_vga < ldw_level_one_base and laneline_sure_R_0 = '1' and 
--                            (shift_state_0 = 0 or shift_state_0 = 1 or shift_state_0 = 3 or shift_state_0 = 5) then
--                        r_vga <= "000";
--                        g_vga <= "000";
--                        b_vga <= "111";
--
--                    elsif cnt_h_sync_vga > 610 and cnt_h_sync_vga < 640 and 
--                            cnt_v_sync_vga > ldw_level_one_base - 30 and cnt_v_sync_vga < ldw_level_one_base and laneline_sure_R_0 = '1' and  shift_state_0 = 2 then
--                        r_vga <= "000";
--                        g_vga <= "000";
--                        b_vga <= "111";
--                        
--                    elsif cnt_h_sync_vga > 620 and cnt_h_sync_vga < 640 and 
--                            cnt_v_sync_vga > ldw_level_one_base - 20 and cnt_v_sync_vga < ldw_level_one_base and laneline_sure_R_0 = '1' and  shift_state_0 = 4 then
--                        r_vga <= "000";
--                        g_vga <= "000";
--                        b_vga <= "111";				
--                        
--                        
--                    elsif cnt_h_sync_vga > 310 and cnt_h_sync_vga < 330 and cnt_v_sync_vga > 40 and cnt_v_sync_vga < 60 and shift_state_0 = 5 then
--                        r_vga <= "111";
--                        g_vga <= "111";
--                        b_vga <= "111";
--
--        -----------------------------------------------------------------------------------------------------------------------------
--        ------------------------  cnt_v_sync_vga = 360  end       cnt_v_sync_vga = 320  begin     -----------------------------------
--        -----------------------------------------------------------------------------------------------------------------------------
--                    elsif cnt_h_sync_vga > 0 and cnt_h_sync_vga < 640 and cnt_v_sync_vga = ldw_level_two_base then
--                        r_vga <= "111";
--                        g_vga <= "111";
--                        b_vga <= "111";
--                    elsif cnt_h_sync_vga > 0 and cnt_h_sync_vga < 640 and cnt_v_sync_vga = ldw_level_two_base - ldw_level_range then
--                        r_vga <= "111";
--                        g_vga <= "111";
--                        b_vga <= "111";		
--                    elsif cnt_v_sync_vga > ldw_level_two_base - ldw_level_range and cnt_v_sync_vga < ldw_level_two_base and cnt_h_sync_vga = laneline_half_2 then
--                        r_vga <= "111";
--                        g_vga <= "000";
--                        b_vga <= "000";
--                    elsif cnt_v_sync_vga > ldw_level_two_base - ldw_level_range and cnt_v_sync_vga < ldw_level_two_base and cnt_h_sync_vga = laneline_half_2 - laneline_quarter_2 - 20  then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";
--                    elsif cnt_v_sync_vga > ldw_level_two_base - ldw_level_range and cnt_v_sync_vga < ldw_level_two_base and cnt_h_sync_vga = laneline_half_2 + laneline_quarter_2 + 20 then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";
--                    elsif cnt_v_sync_vga > ldw_level_two_base - ldw_level_range and cnt_v_sync_vga < ldw_level_two_base and cnt_h_sync_vga = laneline_half_2 - laneline_quarter_2 - 70 then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";
--                    elsif cnt_v_sync_vga > ldw_level_two_base - ldw_level_range and cnt_v_sync_vga < ldw_level_two_base and cnt_h_sync_vga = laneline_half_2 + laneline_quarter_2 + 70 then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";
--                    elsif cnt_h_sync_vga > laneline_L_out_2 - 5 and cnt_h_sync_vga < laneline_L_out_2 + 5 and 
--                            cnt_v_sync_vga > ldw_level_two_base - 10 and cnt_v_sync_vga < ldw_level_two_base and laneline_sure_R_2 = '1' and 
--                            (shift_state_2 = 0 or shift_state_2 = 1 or shift_state_2 = 3 or shift_state_2 = 5) then
--                        r_vga <= "000";
--                        g_vga <= "000";
--                        b_vga <= "111";
--                    elsif cnt_h_sync_vga > laneline_L_out_2 - 15 and cnt_h_sync_vga < laneline_L_out_2 + 15 and 
--                            cnt_v_sync_vga > ldw_level_two_base - 30 and cnt_v_sync_vga < ldw_level_two_base and laneline_sure_R_2 = '1' and  shift_state_2 = 2 then
--                        r_vga <= "000";
--                        g_vga <= "000";
--                        b_vga <= "111";
--                        
--                    elsif cnt_h_sync_vga > laneline_L_out_2 - 10 and cnt_h_sync_vga < laneline_L_out_2 + 10 and 
--                            cnt_v_sync_vga > ldw_level_two_base - 20 and cnt_v_sync_vga < ldw_level_two_base and laneline_sure_R_2 = '1' and  shift_state_2 = 4 then
--                        r_vga <= "000";
--                        g_vga <= "000";
--                        b_vga <= "111";
--                    elsif cnt_h_sync_vga > laneline_R_out_2 - 5 and cnt_h_sync_vga < laneline_R_out_2 + 5 and 
--                            cnt_v_sync_vga > ldw_level_two_base - 10 and cnt_v_sync_vga < ldw_level_two_base and laneline_sure_L_2 = '1' and 
--                            (shift_state_2 = 0 or shift_state_2 = 2 or shift_state_2 = 4 or shift_state_2 = 5) then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";
--                        
--                    elsif cnt_h_sync_vga > laneline_R_out_2 - 15 and cnt_h_sync_vga < laneline_R_out_2 + 15 and 
--                            cnt_v_sync_vga > ldw_level_two_base - 30 and cnt_v_sync_vga < ldw_level_two_base and laneline_sure_L_2 = '1' and  shift_state_2 = 1  then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";	
--                        
--                    elsif cnt_h_sync_vga > laneline_R_out_2 - 10 and cnt_h_sync_vga < laneline_R_out_2 + 10 and 
--                            cnt_v_sync_vga > ldw_level_two_base - 20 and cnt_v_sync_vga < ldw_level_two_base and laneline_sure_L_2 = '1' and  shift_state_2 = 3  then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";
--                    elsif cnt_h_sync_vga > 0 and cnt_h_sync_vga < 10 and 
--                            cnt_v_sync_vga > ldw_level_two_base - 10 and cnt_v_sync_vga < ldw_level_two_base and laneline_sure_L_2 = '1' and 
--                            (shift_state_2 = 0 or shift_state_2 = 2 or shift_state_2 = 4 or shift_state_2 = 5) then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";	
--                    elsif cnt_h_sync_vga > 0 and cnt_h_sync_vga < 30 and 
--                            cnt_v_sync_vga > ldw_level_two_base - 30 and cnt_v_sync_vga < ldw_level_two_base and laneline_sure_L_2 = '1' and  shift_state_2 = 1  then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";	
--                        
--                    elsif cnt_h_sync_vga > 0 and cnt_h_sync_vga < 20 and 
--                            cnt_v_sync_vga > ldw_level_two_base - 20 and cnt_v_sync_vga < ldw_level_two_base and laneline_sure_L_2 = '1' and  shift_state_2 = 3  then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";				
--                    elsif cnt_h_sync_vga > 630 and cnt_h_sync_vga < 640 and 
--                            cnt_v_sync_vga > ldw_level_two_base - 10 and cnt_v_sync_vga < ldw_level_two_base and laneline_sure_R_2 = '1' and 
--                            (shift_state_2 = 0 or shift_state_2 = 1 or shift_state_2 = 3 or shift_state_2 = 5) then
--                        r_vga <= "000";
--                        g_vga <= "000";
--                        b_vga <= "111";
--
--                    elsif cnt_h_sync_vga > 610 and cnt_h_sync_vga < 640 and 
--                            cnt_v_sync_vga > ldw_level_two_base - 30 and cnt_v_sync_vga < ldw_level_two_base and laneline_sure_R_2 = '1' and  shift_state_2 = 2 then
--                        r_vga <= "000";
--                        g_vga <= "000";
--                        b_vga <= "111";
--                        
--                    elsif cnt_h_sync_vga > 620 and cnt_h_sync_vga < 640 and 
--                            cnt_v_sync_vga > ldw_level_two_base - 20 and cnt_v_sync_vga < ldw_level_two_base and laneline_sure_R_2 = '1' and  shift_state_2 = 4 then
--                        r_vga <= "000";
--                        g_vga <= "000";
--                        b_vga <= "111";				
--                        
--                        
--                    elsif cnt_h_sync_vga > 310 and cnt_h_sync_vga < 330 and cnt_v_sync_vga > 20 and cnt_v_sync_vga < 40 and shift_state_2 = 5 then
--                        r_vga <= "111";
--                        g_vga <= "111";
--                        b_vga <= "111";
--
--        -----------------------------------------------------------------------------------------------------------------------------
--        ------------------------  cnt_v_sync_vga = 320  end       cnt_v_sync_vga = 280  begin     -----------------------------------
--        -----------------------------------------------------------------------------------------------------------------------------
--                    elsif cnt_h_sync_vga > 0 and cnt_h_sync_vga < 640 and cnt_v_sync_vga = ldw_level_three_base then
--                        r_vga <= "111";
--                        g_vga <= "111";
--                        b_vga <= "111";
--                    elsif cnt_h_sync_vga > 0 and cnt_h_sync_vga < 640 and cnt_v_sync_vga = ldw_level_three_base - ldw_level_range then
--                        r_vga <= "111";
--                        g_vga <= "111";
--                        b_vga <= "111";		
--                    elsif cnt_v_sync_vga > ldw_level_three_base - ldw_level_range and cnt_v_sync_vga < ldw_level_three_base and cnt_h_sync_vga = laneline_half_1 then
--                        r_vga <= "111";
--                        g_vga <= "000";
--                        b_vga <= "000";
--                    elsif cnt_v_sync_vga > ldw_level_three_base - ldw_level_range and cnt_v_sync_vga < ldw_level_three_base and cnt_h_sync_vga = laneline_half_1 - laneline_quarter_1 - 20  then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";
--                    elsif cnt_v_sync_vga > ldw_level_three_base - ldw_level_range and cnt_v_sync_vga < ldw_level_three_base and cnt_h_sync_vga = laneline_half_1 + laneline_quarter_1 + 20 then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";
--                    elsif cnt_v_sync_vga > ldw_level_three_base - ldw_level_range and cnt_v_sync_vga < ldw_level_three_base and cnt_h_sync_vga = laneline_half_1 - laneline_quarter_1 - 70 then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";
--                    elsif cnt_v_sync_vga > ldw_level_three_base - ldw_level_range and cnt_v_sync_vga < ldw_level_three_base and cnt_h_sync_vga = laneline_half_1 + laneline_quarter_1 + 70 then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";
--                    elsif cnt_h_sync_vga > laneline_L_out_1 - 5 and cnt_h_sync_vga < laneline_L_out_1 + 5 and 
--                            cnt_v_sync_vga > ldw_level_three_base - 10 and cnt_v_sync_vga < ldw_level_three_base and laneline_sure_R_1 = '1' and 
--                            (shift_state_1 = 0 or shift_state_1 = 1 or shift_state_1 = 3 or shift_state_1 = 5) then
--                        r_vga <= "000";
--                        g_vga <= "000";
--                        b_vga <= "111";
--                    elsif cnt_h_sync_vga > laneline_L_out_1 - 15 and cnt_h_sync_vga < laneline_L_out_1 + 15 and 
--                            cnt_v_sync_vga > ldw_level_three_base - 30 and cnt_v_sync_vga < ldw_level_three_base and laneline_sure_R_1 = '1' and  shift_state_1 = 2 then
--                        r_vga <= "000";
--                        g_vga <= "000";
--                        b_vga <= "111";
--                        
--                    elsif cnt_h_sync_vga > laneline_L_out_1 - 10 and cnt_h_sync_vga < laneline_L_out_1 + 10 and 
--                            cnt_v_sync_vga > ldw_level_three_base - 20 and cnt_v_sync_vga < ldw_level_three_base and laneline_sure_R_1 = '1' and  shift_state_1 = 4 then
--                        r_vga <= "000";
--                        g_vga <= "000";
--                        b_vga <= "111";
--                    elsif cnt_h_sync_vga > laneline_R_out_1 - 5 and cnt_h_sync_vga < laneline_R_out_1 + 5 and 
--                            cnt_v_sync_vga > ldw_level_three_base - 10 and cnt_v_sync_vga < ldw_level_three_base and laneline_sure_L_1 = '1' and 
--                            (shift_state_1 = 0 or shift_state_1 = 2 or shift_state_1 = 4 or shift_state_1 = 5) then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";
--                        
--                    elsif cnt_h_sync_vga > laneline_R_out_1 - 15 and cnt_h_sync_vga < laneline_R_out_1 + 15 and 
--                            cnt_v_sync_vga > ldw_level_three_base - 30 and cnt_v_sync_vga < ldw_level_three_base and laneline_sure_L_1 = '1' and  shift_state_1 = 1  then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";	
--                        
--                    elsif cnt_h_sync_vga > laneline_R_out_1 - 10 and cnt_h_sync_vga < laneline_R_out_1 + 10 and 
--                            cnt_v_sync_vga > ldw_level_three_base - 20 and cnt_v_sync_vga < ldw_level_three_base and laneline_sure_L_1 = '1' and  shift_state_1 = 3  then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";
--                    elsif cnt_h_sync_vga > 0 and cnt_h_sync_vga < 10 and 
--                            cnt_v_sync_vga > ldw_level_three_base - 10 and cnt_v_sync_vga < ldw_level_three_base and laneline_sure_L_1 = '1' and 
--                            (shift_state_1 = 0 or shift_state_1 = 2 or shift_state_1 = 4 or shift_state_1 = 5) then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";	
--                    elsif cnt_h_sync_vga > 0 and cnt_h_sync_vga < 30 and 
--                            cnt_v_sync_vga > ldw_level_three_base - 30 and cnt_v_sync_vga < ldw_level_three_base and laneline_sure_L_1 = '1' and  shift_state_1 = 1  then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";	
--                        
--                    elsif cnt_h_sync_vga > 0 and cnt_h_sync_vga < 20 and 
--                            cnt_v_sync_vga > ldw_level_three_base - 20 and cnt_v_sync_vga < ldw_level_three_base and laneline_sure_L_1 = '1' and  shift_state_1 = 3  then
--                        r_vga <= "000";
--                        g_vga <= "111";
--                        b_vga <= "000";				
--                    elsif cnt_h_sync_vga > 630 and cnt_h_sync_vga < 640 and 
--                            cnt_v_sync_vga > ldw_level_three_base - 10 and cnt_v_sync_vga < ldw_level_three_base and laneline_sure_R_1 = '1' and 
--                            (shift_state_1 = 0 or shift_state_1 = 1 or shift_state_1 = 3 or shift_state_1 = 5) then
--                        r_vga <= "000";
--                        g_vga <= "000";
--                        b_vga <= "111";
--
--                    elsif cnt_h_sync_vga > 610 and cnt_h_sync_vga < 640 and 
--                            cnt_v_sync_vga > ldw_level_three_base - 30 and cnt_v_sync_vga < ldw_level_three_base and laneline_sure_R_1 = '1' and  shift_state_1 = 2 then
--                        r_vga <= "000";
--                        g_vga <= "000";
--                        b_vga <= "111";
--                        
--                    elsif cnt_h_sync_vga > 620 and cnt_h_sync_vga < 640 and 
--                            cnt_v_sync_vga > ldw_level_three_base - 20 and cnt_v_sync_vga < ldw_level_three_base and laneline_sure_R_1 = '1' and  shift_state_1 = 4 then
--                        r_vga <= "000";
--                        g_vga <= "000";
--                        b_vga <= "111";				
--                        
--                        
--                    elsif cnt_h_sync_vga > 310 and cnt_h_sync_vga < 330 and cnt_v_sync_vga > 0 and cnt_v_sync_vga < 20 and shift_state_1 = 5 then
--                        r_vga <= "111";
--                        g_vga <= "111";
--                        b_vga <= "111";
--        -----------------------------------------------------------------------------------------------------------------------------
--        --------------------------------------------------  cnt_v_sync_vga = 280    end     -----------------------------------------
--        -----------------------------------------------------------------------------------------------------------------------------
--                    else
--                        r_vga <= "000";
--                        g_vga <= "000";
--                        b_vga <= "000";	
--                    end if;
--
--    ---------------------------------------------***************************************				
--    --			elsif cnt_h_sync_vga > 0 and cnt_h_sync_vga < 640 and cnt_v_sync_vga = 240 then
--    --				r_vga <= "111";
--    --				g_vga <= "111";
--    --				b_vga <= "111";			
--                    
--    --			elsif cnt_v_sync_vga > 0 and cnt_v_sync_vga < 480 and cnt_h_sync_vga = h_line_0_out and h_line_0_en = '1' then
--    --				r_vga <= "111";
--    --				g_vga <= "000";
--    --				b_vga <= "000";		
--    --			elsif cnt_v_sync_vga > 0 and cnt_v_sync_vga < 480 and cnt_h_sync_vga = h_line_1_out and h_line_1_en = '1' then
--    --				r_vga <= "000";
--    --				g_vga <= "111";
--    --				b_vga <= "000";	
--    --			elsif cnt_v_sync_vga > 0 and cnt_v_sync_vga < 480 and cnt_h_sync_vga = h_line_2_out and h_line_2_en = '1' then
--    --				r_vga <= "000";
--    --				g_vga <= "000";
--    --				b_vga <= "111";				
--    --			elsif cnt_v_sync_vga > 0 and cnt_v_sync_vga < 480 and cnt_h_sync_vga = h_line_3_out and h_line_3_en = '1' then
--    --				r_vga <= "111";
--    --				g_vga <= "111";
--    --				b_vga <= "111";	
--        
--    --			elsif cnt_h_sync_vga > laneline_R_out - 2 and cnt_h_sync_vga < laneline_R_out + 2 and 
--    --					cnt_v_sync_vga > 0 and cnt_v_sync_vga < 480 and laneline_sure = '1' then
--    --				r_vga <= "111";
--    --				g_vga <= "111";
--    --				b_vga <= "111";						
--    --			elsif cnt_h_sync_vga > laneline_L_out - 2 and cnt_h_sync_vga < laneline_L_out + 2 and 
--    --					cnt_v_sync_vga > 0 and cnt_v_sync_vga < 480 and laneline_sure_L_1 = '1' then
--    --				r_vga <= "111";
--    --				g_vga <= "111";
--    --				b_vga <= "111";				
--    ---------------------------------------------***************************************
--                --elsif cnt_h_sync_vga > laneline_R_out - 5 and cnt_h_sync_vga < laneline_R_out + 5 and 
--                        --cnt_v_sync_vga > 350 and cnt_v_sync_vga < 360 and laneline_sure = '1' and 
--                        --(shift_state = 0 or shift_state = 2 or shift_state = 4 or shift_state = 5) then
--                    --r_vga <= "000";
--                    --g_vga <= "111";
--                    --b_vga <= "000";
--                    --
--                --elsif cnt_h_sync_vga > laneline_R_out - 15 and cnt_h_sync_vga < laneline_R_out + 15 and 
--                        --cnt_v_sync_vga > 330 and cnt_v_sync_vga < 360 and laneline_sure = '1' and  shift_state = 1  then
--                    --r_vga <= "000";
--                    --g_vga <= "111";
--                    --b_vga <= "000";	
--                    --
--                --elsif cnt_h_sync_vga > laneline_R_out - 10 and cnt_h_sync_vga < laneline_R_out + 10 and 
--                        --cnt_v_sync_vga > 340 and cnt_v_sync_vga < 360 and laneline_sure = '1' and  shift_state = 3  then
--                    --r_vga <= "000";
--                    --g_vga <= "111";
--                    --b_vga <= "000";
--    ---------------------------------------------***************************************				
--                elsif cnt_h_sync_vga > 0 and cnt_h_sync_vga < 10 and 
--                        cnt_v_sync_vga > 350 and cnt_v_sync_vga < 360 and laneline_sure_L_0 = '1' and 
--                        (shift_state_0 = 0 or shift_state_0 = 2 or shift_state_0 = 4 or shift_state_0 = 5) then
--                    r_vga <= "000";
--                    g_vga <= "111";
--                    b_vga <= "000";	
--                elsif cnt_h_sync_vga > 0 and cnt_h_sync_vga < 30 and 
--                        cnt_v_sync_vga > 330 and cnt_v_sync_vga < 360 and laneline_sure_L_0 = '1' and  shift_state_0 = 1  then
--                    r_vga <= "000";
--                    g_vga <= "111";
--                    b_vga <= "000";	
--                    
--                elsif cnt_h_sync_vga > 0 and cnt_h_sync_vga < 20 and 
--                        cnt_v_sync_vga > 340 and cnt_v_sync_vga < 360 and laneline_sure_L_0 = '1' and  shift_state_0 = 3  then
--                    r_vga <= "000";
--                    g_vga <= "111";
--                    b_vga <= "000";				
--                    
--    ---------------------------------------------***************************************				
--                --elsif cnt_h_sync_vga > laneline_L_out - 5 and cnt_h_sync_vga < laneline_L_out + 5 and 
--                        --cnt_v_sync_vga > 350 and cnt_v_sync_vga < 360 and laneline_sure_L_1 = '1' and 
--                        --(shift_state = 0 or shift_state = 1 or shift_state = 3 or shift_state = 5) then
--                    --r_vga <= "000";
--                    --g_vga <= "000";
--                    --b_vga <= "111";
--    --
--                --elsif cnt_h_sync_vga > laneline_L_out - 15 and cnt_h_sync_vga < laneline_L_out + 15 and 
--                        --cnt_v_sync_vga > 330 and cnt_v_sync_vga < 360 and laneline_sure_L_1 = '1' and  shift_state = 2 then
--                    --r_vga <= "000";
--                    --g_vga <= "000";
--                    --b_vga <= "111";
--                    --
--                --elsif cnt_h_sync_vga > laneline_L_out - 10 and cnt_h_sync_vga < laneline_L_out + 10 and 
--                        --cnt_v_sync_vga > 340 and cnt_v_sync_vga < 360 and laneline_sure_L_1 = '1' and  shift_state = 4 then
--                    --r_vga <= "000";
--                    --g_vga <= "000";
--                    --b_vga <= "111";
--    ---------------------------------------------***************************************
--                elsif cnt_h_sync_vga > 630 and cnt_h_sync_vga < 640 and 
--                        cnt_v_sync_vga > 350 and cnt_v_sync_vga < 360 and laneline_sure_R_0 = '1' and 
--                        (shift_state_0 = 0 or shift_state_0 = 1 or shift_state_0 = 3 or shift_state_0 = 5) then
--                    r_vga <= "000";
--                    g_vga <= "000";
--                    b_vga <= "111";
--
--                elsif cnt_h_sync_vga > 610 and cnt_h_sync_vga < 640 and 
--                        cnt_v_sync_vga > 330 and cnt_v_sync_vga < 360 and laneline_sure_R_0 = '1' and  shift_state_0 = 2 then
--                    r_vga <= "000";
--                    g_vga <= "000";
--                    b_vga <= "111";
--                    
--                elsif cnt_h_sync_vga > 620 and cnt_h_sync_vga < 640 and 
--                        cnt_v_sync_vga > 340 and cnt_v_sync_vga < 360 and laneline_sure_R_0 = '1' and  shift_state_0 = 4 then
--                    r_vga <= "000";
--                    g_vga <= "000";
--                    b_vga <= "111";				
--                    
--                    
--                elsif cnt_h_sync_vga > 310 and cnt_h_sync_vga < 330 and cnt_v_sync_vga > 0 and cnt_v_sync_vga < 20 and shift_state_0 = 5 then
--                    r_vga <= "111";
--                    g_vga <= "111";
--                    b_vga <= "111";			
--                        
--                else
--                        r_vga <= buf_vga_Y(buf_vga_Y_out_cnt);
--                        g_vga <= buf_vga_Y(buf_vga_Y_out_cnt);
--                        b_vga <= buf_vga_Y(buf_vga_Y_out_cnt);
--                end if;
--            else
--                        r_vga <= buf_vga_Y(buf_vga_Y_out_cnt);
--                        g_vga <= buf_vga_Y(buf_vga_Y_out_cnt);
--                        b_vga <= buf_vga_Y(buf_vga_Y_out_cnt);
--            end if;
		else
			r_vga <= "000";
			g_vga <= "000";
			b_vga <= "000";
			buf_vga_Y_out_cnt <= 0;

		end if;
	end if;
end if;
end process;
------------i2cslave---------------------------------------------------------
addresscnt:process(clk_video,rst_system)
	begin
		if rst_system = '0' then
			code_cnt <= 0;
			code_cnt_en <= '1';
			commend_cnt <= 0;
		elsif clk_video'event and clk_video = '1' then
			if state_i2c_slave = commend and scl_slave = '1' and code_cnt_en = '1' then
				code_cnt_en <= '0';
				if code_cnt < 7 then
					code_cnt <= code_cnt + 1;
				else
					code_cnt <= code_cnt;
				end if;	
				
				if commend_cnt < 8 then 
					commend_cnt <= commend_cnt + 1;
				else
					commend_cnt <= commend_cnt;
				end if;				
				
			elsif (state_i2c_slave = code_1 or state_i2c_slave = code_2 or state_i2c_slave = code_3 or 
					 state_i2c_slave = code_4) and scl_slave = '1' and code_cnt_en = '1' then 	
				code_cnt_en <= '0';
				if code_cnt < 8 then
					code_cnt <= code_cnt + 1;					
				else
					code_cnt <= 8;
				end if;	
				
			elsif (state_i2c_slave = commend or state_i2c_slave = code_1 or state_i2c_slave = code_2 or 
					state_i2c_slave = code_3 or state_i2c_slave = code_4)and scl_slave = '0' then		
				code_cnt_en <= '1';
				
			elsif state_i2c_slave = slvackup or state_i2c_slave = masack_1up or state_i2c_slave = masack_2up or
					state_i2c_slave = masack_3up or state_i2c_slave = masack_4up or state_i2c_slave = stop then
				code_cnt <= 0;
				commend_cnt <= 0;
			end if;
		end if;
	end process;

	state:process(clk_video,rst_system)
	begin
		if rst_system = '0' then
			code0 <= "01010101";
			state_i2c_slave <= ready;
			sda_reg <= '0';
			sda_sure <= 0;
			sda_slave <= 'Z'; 
			timeout_i2c <= 0;
--			code1 <= "00011011000111001111000101010000";
		elsif clk_video'event and clk_video = '1' then
			case state_i2c_slave is
				when ready =>
					if	sda_slave = '0' and scl_slave = '1' then
						state_i2c_slave <= start;
					else
						state_i2c_slave <= ready;
					end if;
					timeout_i2c <= 0;
				when start =>
					if timeout_i2c < 10000000 then
						timeout_i2c <= timeout_i2c + 1;
						if scl_slave = '0' then 
							if commend_cnt = 8 then 
								state_i2c_slave <= slvackup;
							else	
								state_i2c_slave <= commend;
								sda_reg <= code0(code_cnt);
								sda_slave <= 'Z';
							end if;	
						else
							state_i2c_slave <= start;
						end if;	
					else
						state_i2c_slave <= ready;
						timeout_i2c <= 0;
					end if;
				when commend =>
					if timeout_i2c < 10000000 then
						timeout_i2c <= timeout_i2c + 1;
						if scl_slave = '1' and commend_cnt <= 8 then 
							state_i2c_slave <= start;
							sda_slave <= 'Z';
							if sda_slave = sda_reg then 
								sda_sure <= sda_sure;
							else
								sda_sure <= sda_sure + 1;
							end if;
						else
							state_i2c_slave <= commend;
						end if;	
					else
						state_i2c_slave <= ready;
						timeout_i2c <= 0;
					end if;
				when slvackup =>
					if timeout_i2c < 10000000 then
						timeout_i2c <= timeout_i2c + 1;
						if scl_slave = '0' then 				
							if sda_sure = 0 then 
								sda_slave <= '0';
								state_i2c_slave <= slvackup; 
							else
								sda_slave <= '1';
								state_i2c_slave <= slvackup;
							end if;	
						else					
							state_i2c_slave <= slvackdown;
						end if;
					else
						state_i2c_slave <= ready;
						timeout_i2c <= 0;
					end if;
				when slvackdown =>
					if timeout_i2c < 10000000 then
						timeout_i2c <= timeout_i2c + 1;
						if scl_slave = '1' then
							state_i2c_slave <= slvackdown;
						else
							state_i2c_slave <= code_1;
						end if;	
					else
						state_i2c_slave <= ready;
						timeout_i2c <= 0;
					end if;
				when code_1 =>
					if timeout_i2c < 10000000 then
						timeout_i2c <= timeout_i2c + 1;
						if scl_slave = '0' and code_cnt < 8 then 
							sda_slave <= code1(code_cnt);
							state_i2c_slave <= code_1;
						elsif scl_slave = '0' and code_cnt = 8 then
							state_i2c_slave <= masack_1up;
						end if;
					else
						state_i2c_slave <= ready;
						timeout_i2c <= 0;
					end if;
				when masack_1up =>
					
					sda_slave <= 'Z';
					if timeout_i2c < 10000000 then
						timeout_i2c <= timeout_i2c + 1;
						if scl_slave = '1' then state_i2c_slave <= masack_1down;end if;
					else
						state_i2c_slave <= ready;
						timeout_i2c <= 0;
					end if;
				when masack_1down =>
					if timeout_i2c < 10000000 then
						timeout_i2c <= timeout_i2c + 1;
						if scl_slave = '0' then state_i2c_slave <= code_2;end if;
					else
						state_i2c_slave <= ready;
						timeout_i2c <= 0;
					end if;
				when code_2 =>
					if timeout_i2c < 10000000 then
							timeout_i2c <= timeout_i2c + 1;
						if scl_slave = '0' and code_cnt < 8 then 
							sda_slave <= code1(8 + code_cnt);
							state_i2c_slave <= code_2;
						elsif scl_slave = '0' and code_cnt = 8 then
							state_i2c_slave <= masack_2up;
						end if;
					else
						state_i2c_slave <= ready;
						timeout_i2c <= 0;
					end if;
				when masack_2up =>
					
					sda_slave <= 'Z';
					if timeout_i2c < 10000000 then
						timeout_i2c <= timeout_i2c + 1;
						if scl_slave = '1' then state_i2c_slave <= masack_2down;end if;
					else
						state_i2c_slave <= ready;
						timeout_i2c <= 0;
					end if;
				when masack_2down =>
					if timeout_i2c < 10000000 then
						timeout_i2c <= timeout_i2c + 1;
						if scl_slave = '0' then state_i2c_slave <= code_3;end if;
					else
						state_i2c_slave <= ready;
						timeout_i2c <= 0;
					end if;
				when code_3 =>
					if timeout_i2c < 10000000 then
						timeout_i2c <= timeout_i2c + 1;
						if scl_slave = '0' and code_cnt < 8 then 
							sda_slave <= code1(16 + code_cnt);
							state_i2c_slave <= code_3;
						elsif scl_slave = '0' and code_cnt = 8 then
							state_i2c_slave <= masack_3up;
						end if;
					else
						state_i2c_slave <= ready;
						timeout_i2c <= 0;
					end if;
				when masack_3up =>
					
					sda_slave <= 'Z';
					if timeout_i2c < 10000000 then
						timeout_i2c <= timeout_i2c + 1;
						if scl_slave = '1' then state_i2c_slave <= masack_3down;end if;
					else
						state_i2c_slave <= ready;
						timeout_i2c <= 0;
					end if;
				when masack_3down =>
					if timeout_i2c < 10000000 then
						timeout_i2c <= timeout_i2c + 1;
						if scl_slave = '0' then state_i2c_slave <= code_4;end if;
					else
						state_i2c_slave <= ready;
						timeout_i2c <= 0;
					end if;
					
				when code_4 =>
					if timeout_i2c < 10000000 then
						timeout_i2c <= timeout_i2c + 1;
						if scl_slave = '0' and code_cnt < 8 then 
							sda_slave <= code1(24 + code_cnt);
							state_i2c_slave <= code_4;
						elsif scl_slave = '0' and code_cnt = 8 then
							state_i2c_slave <= masack_4up;
						end if;
					else
						state_i2c_slave <= ready;
						timeout_i2c <= 0;
					end if;
				when masack_4up =>
					sda_slave <= 'Z';
					if timeout_i2c < 10000000 then
						timeout_i2c <= timeout_i2c + 1;
						if scl_slave = '1' then state_i2c_slave <= masack_4down; end if;
					else
						state_i2c_slave <= ready;
						timeout_i2c <= 0;
					end if;
				when masack_4down =>
					if timeout_i2c < 10000000 then
						timeout_i2c <= timeout_i2c + 1;
						if scl_slave = '0' then state_i2c_slave <= stop; end if;
					else
						state_i2c_slave <= ready;
						timeout_i2c <= 0;
					end if;
				when stop => 
					if timeout_i2c < 10000000 then
						timeout_i2c <= timeout_i2c + 1;
						if scl_slave = '1' and sda_slave = '1' then
							state_i2c_slave <= ready;
						else
							state_i2c_slave <= stop;
						end if;	
					else
						state_i2c_slave <= ready;
						timeout_i2c <= 0;
					end if;
				when others => null;
			end case;
		end if;
	end process;
------------i2cslave---------------------------------------------------------

------------i2cmaster---------------------------------------------------------
	div_clk:process(clk_video,rst_system)
	begin
		if rst_system = '0' then
			divcount_master <= (others => '0');
		elsif clk_video'event and clk_video = '1' then
				divcount_master <= divcount_master + '1';
		end if;
	end process;
	
	divclk <= divcount_master(16);
--	clk <= divcount(1);
	
	scldata:process(divclk,rst_system)
	begin	
		if rst_system = '0' then
			scl_master <= '1';
		elsif divclk'event and divclk = '1' then
			scl_master <= not scl_master;
			if state_i2c_master = stop and wrrd = 2 then scl_master <= '1'; end if;
		end if;	
	end process;
	
	cnt_code:process(divclk,rst_system)
	begin
		if rst_system = '0' then
			cntcode <= 0;
			changstate <= 0;
		elsif divclk'event and divclk = '1' then
			if state_i2c_master = commend or state_i2c_master = readcode1 or state_i2c_master = readcode2 
			or state_i2c_master = readcode3 or state_i2c_master = readcode4 then
 				if	cntcode < 7 and scl_master = '1' then 
					cntcode <= cntcode + 1 ; 
				elsif cntcode = 7 and scl_master = '1' then
					cntcode <= 0;
					if changstate < 6 then	changstate <= changstate + 1; end if;
				end if;
			elsif state_i2c_master = start then 
				changstate <= 0;
			end if;	
		end if;	
	end process;

	sta:process(divclk,clk_video,rst_system)
	begin

		if rst_system = '0' then
--			code0 <= "00011101"; --commend address
			--code3 <= "01111101";
			code4 <= "01010101"; --commend address(7) change to '1'
			state_i2c_master <= ready;
			sda_master <= '1';
			wrrd <= 0;
		elsif clk_video'event and clk_video = '1' then
			case state_i2c_master is
				when ready =>
					if divclk = '0' and scl_master = '1' then sda_master <= '0'; end if;	
					if sda_master = '0' then state_i2c_master <= start; end if;	
				when start =>
					if scl_master = '0' then state_i2c_master <= commend; end if;	
				when commend =>
					if cntcode < 8 and scl_master = '0' and divclk = '0' then 
						sda_master <= code4(cntcode);
					end if;
					if changstate = 1 and divclk = '0' then
						sda_master <= 'Z';
						if scl_master = '0'  then state_i2c_master <= mastack; end if;	
					end if;	
				when mastack =>
					if divclk = '1' and scl_master = '0'  then state_i2c_master <=readcode1; end if;
					sda_master <= 'Z';
				when readcode1 =>
--					if cntcode < 8 and scl = '0' and divclk = '0' and changstate = 1 then sda <= 'Z' ; end if;
					if changstate = 2 then
						sda_master <= '1';
						if scl_master = '0'  then state_i2c_master <= readack1; end if;	
					else
						sda_master <= 'Z';
					end if;		
				when readack1 =>	
					if divclk = '1' and scl_master = '0'  then 
						sda_master <= '0';
						state_i2c_master <= readcode2;						
					end if;	
					
				when readcode2 =>
					if changstate = 3 then
						sda_master <= '1';
						if scl_master = '0'  then state_i2c_master <= readack2; end if;	
					else
						sda_master <= 'Z';
					end if;	
				when readack2 =>	
					if divclk = '1' and scl_master = '0'  then 
						sda_master <= '0';
						state_i2c_master <= readcode3;						
					end if;	
					
				when readcode3 =>
					if changstate = 4 then
						sda_master <= '1';
						if scl_master = '0'  then state_i2c_master <= readack3; end if;	
					else
						sda_master <= 'Z';
					end if;
				when readack3 =>	
					if divclk = '1' and scl_master = '0'  then 
						sda_master <= '0';
						state_i2c_master <= readcode4;						
					end if;	
					
				when readcode4 =>
					if changstate = 5 then
						sda_master <= '1';
						if scl_master = '0'  then state_i2c_master <= readack4; end if;	
					else
						sda_master <= 'Z';
					end if;	
				when readack4 =>	
					if divclk = '1' and scl_master = '0'  then 
						sda_master <= '0';
						state_i2c_master <= stop;						
					end if;			
					
				when stop => 
					if divclk = '1' and scl_master = '1' and sda_master = '1'  then 
--						wrrd <= wrrd + 1;
						state_i2c_master <= ready ;			
					elsif divclk = '0' and scl_master = '1' then 
						sda_master <= '1';
					end if;
				when others => null;
			end case;
		end if;
	end process;
----i2c------------------------------------------------------------------------------------------	




------------i2cmaster---------------------------------------------------------

----------------------------- focus begin -----------------------------------
--process(rst_system,clk_video)--focus_matrix(unuse)
--begin
	--if rst_system = '0' then
		--led_matrix_cnt <= 0;
	--elsif rising_edge(clk_video) then
        --if led_matrix_cnt < 8 then
            --led_matrix_cnt <= led_matrix_cnt + 1;
        --else
            --led_matrix_cnt <= 0;
            --if laneline_R_out_0 > lu_focus_x and laneline_R_out_0 - lu_focus_x >= 0 and laneline_R_out_0 - lu_focus_x < 10 then
                --focus_matrix(7 downto 4) <= "0000";
            --elsif laneline_R_out_0 > lu_focus_x and laneline_R_out_0 - lu_focus_x >= 10 and laneline_R_out_0 - lu_focus_x < 40 then
                --focus_matrix(7 downto 4) <= "0001";
            --elsif laneline_R_out_0 > lu_focus_x and laneline_R_out_0 - lu_focus_x >= 40 and laneline_R_out_0 - lu_focus_x < 100 then
                --focus_matrix(7 downto 4) <= "0011";
            --elsif laneline_R_out_0 > lu_focus_x and laneline_R_out_0 - lu_focus_x >= 100 and laneline_R_out_0 - lu_focus_x < 180 then
                --focus_matrix(7 downto 4) <= "0111";
            --else
                --focus_matrix(7 downto 4) <= "1111";
            --end if;
            --if ru_focus_x > laneline_L_out_0 and ru_focus_x - laneline_L_out_0 >= 0 and ru_focus_x - laneline_L_out_0 < 10 then
                --focus_matrix(3 downto 0) <= "0000";
            --elsif ru_focus_x > laneline_L_out_0 and ru_focus_x - laneline_L_out_0 >= 10 and ru_focus_x - laneline_L_out_0 < 40 then
                --focus_matrix(3 downto 0) <= "1000";
            --elsif ru_focus_x > laneline_L_out_0 and ru_focus_x - laneline_L_out_0 >= 40 and ru_focus_x - laneline_L_out_0 < 100 then
                --focus_matrix(3 downto 0) <= "1100";
            --elsif ru_focus_x > laneline_L_out_0 and ru_focus_x - laneline_L_out_0 >= 100 and ru_focus_x - laneline_L_out_0 < 180 then
                --focus_matrix(3 downto 0) <= "1110";
            --else
                --focus_matrix(3 downto 0) <= "1111";
            --end if;
        --end if;
    --end if;
--end process;

----------------------------- focus end -----------------------------------

focus_matrix(0) <= MPAS_squarelight_7 & MPAS_squarelight_6 & MPAS_squarelight_5 & MPAS_squarelight_4 & MPAS_squarelight_3 & MPAS_squarelight_2 & MPAS_squarelight_1 & MPAS_squarelight_0 ;
focus_matrix(1) <= MPAS_squarelight_7 & MPAS_squarelight_6 & MPAS_squarelight_5 & MPAS_squarelight_4 & MPAS_squarelight_3 & MPAS_squarelight_2 & MPAS_squarelight_1 & MPAS_squarelight_0 ;
focus_matrix(2) <= MPAS_squarelight_15 & MPAS_squarelight_14 & MPAS_squarelight_13 & MPAS_squarelight_12 & MPAS_squarelight_11 & MPAS_squarelight_10 & MPAS_squarelight_9 & MPAS_squarelight_8 ;
focus_matrix(3) <= MPAS_squarelight_15 & MPAS_squarelight_14 & MPAS_squarelight_13 & MPAS_squarelight_12 & MPAS_squarelight_11 & MPAS_squarelight_10 & MPAS_squarelight_9 & MPAS_squarelight_8 ;
focus_matrix(4) <= MPAS_squarelight_23 & MPAS_squarelight_22 & MPAS_squarelight_21 & MPAS_squarelight_20 & MPAS_squarelight_19 & MPAS_squarelight_18 & MPAS_squarelight_17 & MPAS_squarelight_16 ;
focus_matrix(5) <= MPAS_squarelight_23 & MPAS_squarelight_22 & MPAS_squarelight_21 & MPAS_squarelight_20 & MPAS_squarelight_19 & MPAS_squarelight_18 & MPAS_squarelight_17 & MPAS_squarelight_16 ;
focus_matrix(6) <= MPAS_squarelight_31 & MPAS_squarelight_30 & MPAS_squarelight_29 & MPAS_squarelight_28 & MPAS_squarelight_27 & MPAS_squarelight_26 & MPAS_squarelight_25 & MPAS_squarelight_24 ;
focus_matrix(7) <= MPAS_squarelight_31 & MPAS_squarelight_30 & MPAS_squarelight_29 & MPAS_squarelight_28 & MPAS_squarelight_27 & MPAS_squarelight_26 & MPAS_squarelight_25 & MPAS_squarelight_24 ;
process(rst_system,clk_video)--standing (SAH light LED)
begin
	if rst_system = '0' then
		standing_1 <= "00000000";	standing_2 <= "00000000";
	elsif rising_edge(clk_video) then
        --if led_matrix_cnt < 8 then
            --led_matrix_cnt <= led_matrix_cnt + 1;
        --else
            --led_matrix_cnt <= 0;
            case(led_matrix_cnt) is --  1 3 0 4 2
            when 0 =>standing_1 <= "10000000"; standing_2 <= focus_matrix(0);
            when 1 =>standing_1 <= "01000000"; standing_2 <= focus_matrix(1);
            when 2 =>standing_1 <= "00100000"; standing_2 <= focus_matrix(2);
            when 3 =>standing_1 <= "00010000"; standing_2 <= focus_matrix(3);
            when 4 =>standing_1 <= "00001000"; standing_2 <= focus_matrix(4);
            when 5 =>standing_1 <= "00000100"; standing_2 <= focus_matrix(5);
            when 6 =>standing_1 <= "00000010"; standing_2 <= focus_matrix(6);
            when 7 =>standing_1 <= "00000001"; standing_2 <= focus_matrix(7);

            when others =>standing_1 <= "00000000";	standing_2 <= "00000000";
            end case;
        --end if;
    end if;
end process;

--process(rst_system,clk_video)--led_matrix_cnt
--
--begin
--	if rst_system = '0' then
--		led_matrix_cnt <= 0;
--	elsif rising_edge(divcount(13)) then
--        if led_matrix_cnt < 8 then
--            led_matrix_cnt <= led_matrix_cnt + 1;
--        else
--            led_matrix_cnt <= 0;
--        end if;
--    end if;
--end process;

--process(rst_system,clk_video)--squarelight (LDW state LED)
--begin
--	if rst_system = '0' then
--		squarelight_2 <= "11111111";
--		squarelight_1 <= "11111111";
--	elsif rising_edge(clk_video) then
--case(shift_state_0) is --  1 3 0 4 2
--when 0 =>squarelight_1 <= "11111111"; squarelight_2 <= "10000001";
--when 1 =>squarelight_1 <= "11111111"; squarelight_2 <= "00001111";
--when 2 =>squarelight_1 <= "11111111"; squarelight_2 <= "11110000";
--when 3 =>squarelight_1 <= "11111111"; squarelight_2 <= "00000011";
--when 4 =>squarelight_1 <= "11111111"; squarelight_2 <= "11000000";
--when 5 =>squarelight_1 <= "00000000"; squarelight_2 <= "00000000";
--when others =>squarelight_2 <= "11111111";	squarelight_1 <= "11111111";
--end case;
--    end if;
--end process;

--process(rst_system,clk_video)--warning_cnt_level (for buzzer working time)
--begin
--	if rst_system = '0' then
--        warning_cnt_level <= 0;
--	elsif rising_edge(clk_video) then
--        case(shift_state_0) is --  1 3 0 4 2
--            when 0 =>warning_cnt_level <= 0;
--            when 1 =>warning_cnt_level <= 40;
--            when 2 =>warning_cnt_level <= 40;
--            when 3 =>warning_cnt_level <= 80;
--            when 4 =>warning_cnt_level <= 80;
--            when 5 =>warning_cnt_level <= 0;
--            when others =>warning_cnt_level <= 0;
--        end case;
--    end if;
--end process;

--process(rst_system,divcount(16))--buzzer
--begin
--	if rst_system = '0' then
--		buzzer <=  '0';
--        warning_cnt <= 0;
--	elsif rising_edge(divcount(17)) then
--        if warning_cnt < warning_cnt_level then
--            if warning_cnt_level - 15 >= warning_cnt then
--                buzzer <=  '0';
--            else
--                buzzer <=  '1';
--            end if;
--            warning_cnt <= warning_cnt + 1;
--        else
--            buzzer <=  '0';
--            warning_cnt <= 0;
--        end if;
--    end if;
--end process;



--process(rst_system,clk_video)--SAH_Y_threshold_8bit
--begin
	--if rst_system = '0' then
        --SAH_Y_threshold_8bit <= "10100000";
	--elsif rising_edge(clk_video) then
        --if rst_button_click_times_SAH = 0 then
            --SAH_Y_threshold_8bit <= "01010000";
        --elsif rst_button_click_times_SAH = 1 then
            --SAH_Y_threshold_8bit <= "01100000";
        --elsif rst_button_click_times_SAH = 2 then
            --SAH_Y_threshold_8bit <= "01110000";
        --elsif rst_button_click_times_SAH = 3 then
            --SAH_Y_threshold_8bit <= "10000000";
        --elsif rst_button_click_times_SAH = 4 then
            --SAH_Y_threshold_8bit <= "10010000";
        --elsif rst_button_click_times_SAH = 5 then
            --SAH_Y_threshold_8bit <= "10100000";
        --elsif rst_button_click_times_SAH = 6 then
            --SAH_Y_threshold_8bit <= "10110000";
        --elsif rst_button_click_times_SAH = 7 then
            --SAH_Y_threshold_8bit <= "11000000";
        --else
            --SAH_Y_threshold_8bit <= "01010000";
        --end if;
    --end if;
--end process;
--process(rst_system,clk_video)--SAH_Y_threshold_8bit
--begin
	--if rst_system = '0' then
----        SAH_Y_threshold_8bit <= "10100101";
	--elsif rising_edge(clk_video) then
--
        --if rst_button_click_times_SAH = 0 then
            --SAH_Y_threshold_8bit <= "01010101";
        ----elsif rst_button_click_times_SAH = 1 then
            ----SAH_Y_threshold_8bit <= "01101000";
        ----elsif rst_button_click_times_SAH = 2 then
            ----SAH_Y_threshold_8bit <= "01110101";
        ----elsif rst_button_click_times_SAH = 3 then
            ----SAH_Y_threshold_8bit <= "10000110";
        ----elsif rst_button_click_times_SAH = 4 then
            ----SAH_Y_threshold_8bit <= "10011101";
        ----elsif rst_button_click_times_SAH = 5 then
            ----SAH_Y_threshold_8bit <= "10100000";
        ----elsif rst_button_click_times_SAH = 6 then
            ----SAH_Y_threshold_8bit <= "10111011";
        ----elsif rst_button_click_times_SAH = 7 then
            ----SAH_Y_threshold_8bit <= "11001111";
        ----else
            ----SAH_Y_threshold_8bit <= "10100000";
        --end if;
    --end if;
--end process;

process(rst_system,clk_video)--SAH_Y_threshold_8bit
begin
	if rst_system = '0' then
        SAH_Y_threshold_4bit <= "0101";
	elsif rising_edge(clk_video) then
----        if rst_button_click_times_SAH = 0 then
--			 if switch_select = "0001" then
--            SAH_Y_threshold_4bit <= "1110";
----        elsif rst_button_click_times_SAH = 1 then
--			 elsif switch_select = "0010" then
--            SAH_Y_threshold_4bit <= "1101";
--
----        elsif rst_button_click_times_SAH = 2 then
--			 elsif switch_select = "0100" then
--            SAH_Y_threshold_4bit <= "1100";
--		 
----        elsif rst_button_click_times_SAH = 3 then
--			 elsif switch_select = "1000" then
--            SAH_Y_threshold_4bit <= "1010";			
--				
--          else
            SAH_Y_threshold_4bit <= "0101";
--        end if;
    end if;
end process;


 -- only for keeping away from pruning
 
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
				if RD_WR_v = '1' then
					code_out_state <= 1;
				end if;
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
				UartOut <= code1(7 downto 0);
				if RD_WR_cnt < 28120 then
					RD_WR_cnt <= RD_WR_cnt + 1 ;
					RD_WR <= '1';
				else
					RD_WR <= '0';
					RD_WR_cnt <= 0;
					code_out_state <= 3;
				end if;
			when 3 =>
				UartOut <= code1(15 downto 8);
				if RD_WR_cnt < 28120 then
					RD_WR_cnt <= RD_WR_cnt + 1 ;
					RD_WR <= '1';
				else
					RD_WR <= '0';
					RD_WR_cnt <= 0;
					code_out_state <= 4;
				end if;
			when 4 =>
				UartOut <= code1(23 downto 16);
				if RD_WR_cnt < 28120 then
					RD_WR_cnt <= RD_WR_cnt + 1 ;
					RD_WR <= '1';
				else
					RD_WR <= '0';
					RD_WR_cnt <= 0;
					code_out_state <= 5;
				end if;
			when 5 =>
				UartOut <= code1(31 downto 24);
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
					UartOut <= "10101010";
					RD_WR <= '1';
					RD_WR_cnt <= RD_WR_cnt + 1 ;
				else
					UartOut <= "01010101";
					RD_WR <= '0';
					RD_WR_cnt <= 0;
					code_out_state <= 0;
				end if;
			when others =>
				RD_WR <= '1';
				code_out_state <= 0;
      end case;
   end if;
end process;

end Behavioral;
