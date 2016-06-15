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
module VLSI_Final(Start, clr,LEDin, FPGA_clk, ScanEn, Dout,LED);
    input Start;
    input clr;
	 input FPGA_clk;
	 input LEDin;
	 output [3:0] ScanEn;
    output [7:0] Dout;
	 output [15:0] LED;
	 wire osc_1_out;
	
	 wire [15:0] Cnt_Dout;
	 
	 
OSC osc_1(.Start(Start), .Tout(osc_1_out));
VGTA v1(.Tosc(osc_1_out), .clr(clr), .Start(Start), .clk(FPGA_clk), .Cnt(Cnt_Dout), .Tosc_Cnt(LED));

Scan_7Segment s1(.clk(FPGA_clk), .rst(clr), .DataIn_A(Cnt_Dout[3:0]), .DataIn_B(Cnt_Dout[7:4]), .DataIn_C(Cnt_Dout[11:8]), .DataIn_D(Cnt_Dout[15:12]), .ScanEn(ScanEn), .DataOut(Dout));


endmodule
