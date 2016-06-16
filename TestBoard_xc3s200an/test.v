`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   16:22:02 06/16/2016
// Design Name:   TestBoard
// Module Name:   C:/Users/BowenHsu/Documents/VideoProcessing/TestBoard_xc3s200an/test.v
// Project Name:  TestBoard_xc3s200an
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: TestBoard
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module test;

	// Inputs
	reg Start;
	reg clr;
	reg LEDin;
	reg FPGA_clk;

	// Outputs
	wire [3:0] ScanEn;
	wire [7:0] Dout;
	wire Tp;

	// Instantiate the Unit Under Test (UUT)
	TestBoard uut (
		.Start(Start), 
		.clr(clr), 
		.LEDin(LEDin), 
		.FPGA_clk(FPGA_clk), 
		.ScanEn(ScanEn), 
		.Dout(Dout), 
		.Tp(Tp)
	);
	initial forever #5 FPGA_clk = ~FPGA_clk;
	initial begin
		// Initialize Inputs
		Start = 0;
		clr = 0;
		LEDin = 0;
		FPGA_clk = 0;

		// Wait 100 ns for global reset to finish
		#50 clr = 1'd1;
		#50 Start = 1'd1; 
		#10000 $finish;
        
		// Add stimulus here

	end
      
endmodule

