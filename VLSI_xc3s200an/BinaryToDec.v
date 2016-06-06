`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:04:51 06/06/2016 
// Design Name: 
// Module Name:    BinaryToDec 
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
module BinaryToDec(clk,rst,Input,Output);
    input clk;
    input rst;
    input [15:0] Input;
    output [15:0] Output;
    

	wire [3:0]RegOne_1;
	wire [3:0]RegTen_1;
	wire [3:0]RegHun_1;
	reg [4:0]Reg_1;
	
	wire [3:0]RegOne_2;
	wire [3:0]RegTen_2;
	wire [3:0]RegHun_2;
	reg [4:0]Reg_2;
	reg [4:0]Reg_3;
	
bin_dec bd_1(.clk(clk),.Input(Input[7:0]),.rst_n(rst),.one(RegOne_1),.ten(RegTen_1),.hun(RegHun_1));
bin_dec bd_2(.clk(clk),.Input(Input[15:8]),.rst_n(rst),.one(RegOne_2),.ten(RegTen_2),.hun(RegHun_2));

assign Output = {Reg_3[3:0],Reg_2[3:0],Reg_1[3:0]};
always@(posedge clk or negedge rst)
begin
	if(~rst)
	begin
		Reg_1 <= 5'd0;
		Reg_2 <= 5'd0;
		Reg_3 <= 5'd0;
	end
	else
	begin
		Reg_1 <= RegOne_1 + RegOne_2;
		Reg_2 <= Reg_1[4] + RegTen_1 + RegTen_2;
		Reg_3 <= Reg_2[4] + RegHun_1 + RegHun_2;
		
	end
end

endmodule
