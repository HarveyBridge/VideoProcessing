`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:58:19 06/16/2016 
// Design Name: 
// Module Name:    TestBoard 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module TestBoard(Start, clr,LEDin, FPGA_clk, ScanEn, Dout,LED);
    input Start;
    input clr;
	 input FPGA_clk;
	 input LEDin;
	 output [3:0] ScanEn;
    output [7:0] Dout;
	 output   [15:0]LED;
	 wire osc_1_out;
	
	 wire [15:0] Cnt_Dout;
	 

     wire Tout;
	 wire w1 /* synthesis keep = 1 */;
	 wire w2 /* synthesis keep = 1 */;
	 wire w3 /* synthesis keep = 1 */;
	 wire w4 /* synthesis keep = 1 */;
	 wire w5 /* synthesis keep = 1 */;
	 wire w6 /* synthesis keep = 1 */;
	 wire w7 /* synthesis keep = 1 */;
	 wire w8 /* synthesis keep = 1 */;
	 wire w9 /* synthesis keep = 1 */;	 
	 
	parameter M = 16'd7000;
	reg [15:0] Tosc_Cnt = 16'd0;
	reg [15:0] Cnt;
	reg [31:0] SwitchCnt = 32'd0;
	wire Tp ;
	reg Td ;
	reg Start_reg = 1'd0;
	reg clr_reg = 1'd1;
	wire Counter_clk;
	//wire clr;
	// assign Counter_clk = Tp & FPGA_clk;
	// assign Td = (Tosc_Cnt>M)?1'd1:1'd0;
	//  Tp + Td + Counter_clk + 
	//assign Td = (Tosc_Cnt>M)? 1'd1: 1'd0;
	assign Counter_clk = Tp & FPGA_clk;
	assign Tp = Start^Td;
	//assign clr = clr_reg;
	assign LED[15:3] = Cnt[15:3];
	assign LED[2] = Counter_clk;
	assign LED[1] = Td;
	assign LED[0] = Tp;
	

	Scan_7Segment s1(.clk(FPGA_clk), .rst(clr), .DataIn_A(Cnt[3:0]), .DataIn_B(Cnt[7:4]), .DataIn_C(Cnt[11:8]), .DataIn_D(Cnt[15:12]), .ScanEn(ScanEn), .DataOut(Dout));
	
NAND2 n1(w1,w9,Start);
NAND2 n2(w2,w1,w1);
NAND2 n3(w3,w2,w2);
NAND2 n4(w4,w3,w3);
NAND2 n5(w5,w4,w4);
NAND2 n6(w6,w5,w5);
NAND2 n7(w7,w6,w6);
NAND2 n8(w8,w7,w7);
NAND2 n9(w9,w8,w8);
NAND2 n10(Tout,1'b1,w9);
		
always@(posedge FPGA_clk or negedge clr)
begin
	if(~clr)
		SwitchCnt <= 32'd0;
	else
		SwitchCnt <= SwitchCnt + 1'd1;
end

always@(posedge FPGA_clk or negedge clr)
begin
	if(~clr) begin
		Start_reg <= 1'd0;
		clr_reg <= 1'd1;
	end
	else if(SwitchCnt[22] == 1'd1)
		Start_reg <= 1'd1;
	else begin
		Start_reg <= 1'd0;
		clr_reg <= 1'd1;
	end
end

always@(posedge Tout or negedge clr)
begin
	if(~clr) begin
		Tosc_Cnt <= 16'd0;
		Td <= 1'd0;
	end
	else begin		
		if(Tosc_Cnt<M) begin
			Tosc_Cnt <= Tosc_Cnt + 1'd1;
			Td <= 1'd0;
		end
		else if(Tosc_Cnt>=M) begin
			Tosc_Cnt <= Tosc_Cnt; 
			Td <= 1'd1;		
		end
	end
end


// always@(posedge Start or posedge Td)
// begin
	// if(Start) begin
		// if(Td)
			// Tp <= 1'd0;
		// else
			// Tp <= 1'd1;
	// end
	// else
		// Tp <= 1'd0;
// end

always@(posedge Counter_clk or negedge clr)
begin
	if(~clr)	
		Cnt <= 16'd0;		
	else begin
		if(Cnt[3:0] == 4'd9) begin
			Cnt[3:0] <= 4'd0 ;
			if(Cnt[7:4] == 4'd9) begin
				Cnt[7:4] <= 4'd0 ;
				if(Cnt[11:8] == 4'd9) begin
					Cnt[11:8] <= 4'd0 ;
					if(Cnt[15:12] == 4'd9) 
						Cnt[15:12] <= 4'd0 ;
					else
						Cnt[15:12] <= Cnt[15:12] + 1'd1;
				end
				else
					Cnt[11:8] <= Cnt[11:8] + 1'd1;
			end
			else
				Cnt[7:4] <= Cnt[7:4] + 1'd1;
		end
		else 
			Cnt[3:0] <= Cnt[3:0] + 1'd1;
	end
end


endmodule
