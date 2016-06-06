`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:05:50 06/06/2016 
// Design Name: 
// Module Name:    VLSI_Final 
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
module VLSI_Final(Start, clr, FPGA_clk, ScanEn, Dout);
    input Start;
    input clr;
	 input FPGA_clk;
	 output [3:0] ScanEn;
    output [7:0] Dout;
	 
	 wire osc_1_out;
	 wire vgta_1_out;

	 wire tp;
	 wire n2_out;
	 wire [15:0] cnt_1_out;
	 wire [3:0] w_one;
	 wire [3:0] w_ten;
	 wire [3:0] w_hun;
	 wire [15:0] BTD_out;

	 reg [15:0] BTD1_out;
OSC osc_1(.Start(~Start), .Tout(osc_1_out));
VGTA u1(.clk(osc_1_out), .clr(clr), .Start(Start), .out(vgta_1_out));
XOR2 xor2_1(tp,vgta_1_out,Start);
AND2 n2(n2_out,tp,FPGA_clk);
Counter cnt_1(.clr(clr), .Tc(n2_out), .Out(cnt_1_out));

BinaryToDec btd_1(.clk(FPGA_clk),.rst(clr),.Input(16'h1234),.Output(BTD_out[15:0]));
Scan_7Segment s1(.clk(FPGA_clk), .rst(clr), .DataIn_A(BTD_out[3:0]), .DataIn_B(BTD_out[7:4]), .DataIn_C(BTD_out[11:8]), .DataIn_D(BTD_out[15:12]), .ScanEn(ScanEn), .DataOut(Dout));


endmodule
