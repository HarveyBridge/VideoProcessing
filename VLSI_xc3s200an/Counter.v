`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:43:13 06/06/2016 
// Design Name: 
// Module Name:    Counter 
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
module Counter(clr, Tc, Out);
    input clr;
    input Tc;
    output reg [15:0] Out;
always@(posedge Tc or negedge clr)
begin
	if(~clr)
		Out <= 0;
	else
		Out <= Out + 1;
end
endmodule
