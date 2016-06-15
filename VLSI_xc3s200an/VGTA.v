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
module VGTA(Tosc, clr, Start, clk, Cnt,Tosc_Cnt);
    input Tosc;
    input clr;
	input Start;
	input clk;
    output reg [15:0] Cnt;
	output reg Tosc_Cnt;
	reg Tp = 1'd0;
	wire Td;
	wire Counter_clk;
	//reg [15:0] Tosc_Cnt;
	
	parameter M = 16'd5000;

	//assign Td = (Tosc_Cnt>M)? 1'd1: 1'd0;
	assign Counter_clk = Tp & clk;
	
always@(posedge Tosc or negedge clr)
begin
	if(~clr)
		Tosc_Cnt <= 16'd0;
	else
		Tosc_Cnt <= Tosc_Cnt + 1'd1;
end

always@(posedge Start or posedge Td)
begin
	if(Start) begin
		if(Td)
			Tp <= 1'd0;
		else
			Tp <= 1'd1;
	end
	else
		Tp <= 1'd0;
end

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
