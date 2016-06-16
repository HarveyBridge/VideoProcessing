`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:55:34 06/16/2016 
// Design Name: 
// Module Name:    SmartTempSensor 
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
module SmartTempSensor(Start, clr, FPGA_clk, ScanEn, Dout,DebugLED);
	input Start;
	input clr;
	input FPGA_clk;
	output [3:0] ScanEn;
    output [7:0] Dout;
	output [15:0] DebugLED;
	wire u1_Tout;
	wire [15:0] u2_Dout;
	OSC u1(.Start(Start), .Tout(u1_Tout));
	VGTA u2(.Start(Start),.Tosc(u1_Tout),.clr(clr),.FPGA_clk(FPGA_clk),.Dout(u2_Dout),.DebugLED(DebugLED));
	Scan_7Segment u3(.clk(FPGA_clk), .rst(clr), .DataIn_A(u2_Dout[3:0]), .DataIn_B(u2_Dout[7:4]), .DataIn_C(u2_Dout[11:8]), .DataIn_D(u2_Dout[15:12]), .ScanEn(ScanEn), .DataOut(Dout));
	
endmodule
