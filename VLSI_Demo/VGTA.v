`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:59:47 06/16/2016 
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
module VGTA(Start,Tosc,clr,FPGA_clk,Dout,DebugLED);
	input Start;
	input Tosc;
	input clr;
	input FPGA_clk;
	output [15:0] Dout;
	output [15:0] DebugLED;
	
	parameter M = 16'd7000;
	reg [15:0] Tosc_Cnt = 16'd0;
	reg [15:0] Cnt;
	reg [31:0] SwitchCnt = 32'd0;
	reg Td ;
	
	wire Tp ;
	wire Counter_clk;

	assign Counter_clk = Tp & FPGA_clk;
	assign Tp = Start^Td;
	assign Dout = Cnt;
	assign DebugLED[15:3] = Cnt[15:3];
	assign DebugLED[2] = Counter_clk;
	assign DebugLED[1] = Td;
	assign DebugLED[0] = Tp;

always@(posedge Tosc or negedge clr)
begin
	if(~clr) begin
		Tosc_Cnt <= 16'd0;
		Td <= 1'd0;
	end
	else begin		
		if(Tosc_Cnt<M) begin
			Tosc_Cnt <= Tosc_Cnt + 1'd1;
			Td <= 1'd0;
		end
		else if(Tosc_Cnt>=M) begin
			Tosc_Cnt <= Tosc_Cnt; 
			Td <= 1'd1;		
		end
	end
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
