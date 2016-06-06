`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:56:43 06/06/2016 
// Design Name: 
// Module Name:    VGTA 
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
module VGTA(clk, clr, Start, out);
    input clk;
    input clr;
	 input Start;
    output reg out;
	 
reg [15:0] cnt;

always@(posedge clk or negedge clr)
begin
	if(~clr)
	begin
		cnt <= 0;		
		
	end
	else
	begin
		if(cnt < 5000)
		begin
			cnt <= cnt +1'b1 ;

		end
		else
		begin
			cnt <= cnt ;

		end
	end
end


endmodule
