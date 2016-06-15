`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   01:43:57 06/16/2016
// Design Name:   OSC
// Module Name:   C:/Users/BowenHsu/Documents/VideoProcessing/VLSI_xc3s200an/test_osc.v
// Project Name:  VLSI_xc3s200an
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: OSC
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module test_osc;

	// Inputs
	reg Start;

	// Outputs
	wire Tout;

	// Instantiate the Unit Under Test (UUT)
	OSC uut (
		.Start(Start), 
		.Tout(Tout)
	);

	initial begin
		// Initialize Inputs
		Start = 0;

		// Wait 100 ns for global reset to finish
		#10 Start = 1'd0;
		#10 Start = 1'd1;
		#10000000 $finish;
        
		// Add stimulus here

	end
      
endmodule

