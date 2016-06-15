`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   02:30:29 06/16/2016
// Design Name:   VGTA
// Module Name:   C:/Users/BowenHsu/Documents/VideoProcessing/VLSI_xc3s200an/test_VGTA.v
// Project Name:  VLSI_xc3s200an
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: VGTA
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module test_VGTA;

	// Inputs
	reg Tosc;
	reg clr;
	reg Start;
	reg clk;
	// Outputs
	wire [7:0] Dout;

	// Instantiate the Unit Under Test (UUT)
	VGTA uut (
		.Tosc(Tosc), 
		.clr(clr), 
		.Start(Start), 
		.clk(clk),
		.Dout(Dout)
	);
initial forever #30 Tosc=~Tosc;
initial forever #5 clk=~clk;
	initial begin
		// Initialize Inputs
		Tosc = 0;
		clr = 0;
		Start = 0;
		clk = 0;
		#10 clr = 1'd1;
		#10 Start = 1'd1;
		
		// Wait 100 ns for global reset to finish
		#1000 $finish;
        
		// Add stimulus here

	end
      
endmodule

