`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:26:28 06/06/2016 
// Design Name: 
// Module Name:    Scan_7Segment 
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
module Scan_7Segment(clk, rst, DataIn_A, DataIn_B, DataIn_C, DataIn_D, ScanEn, DataOut);
    input clk;
    input rst;
    input [3:0] DataIn_A;
	 input [3:0] DataIn_B;
	 input [3:0] DataIn_C;
	 input [3:0] DataIn_D;
    output reg [3:0] ScanEn;
    output reg [7:0] DataOut;

reg [3:0]decoderIn;
reg [32:0] div_cnt;
reg [1:0]scan_state;



always@(posedge clk or negedge rst)
begin
	if(~rst)
		div_cnt <= 0;
	else
		div_cnt <= div_cnt + 1'b1;
end


//  scan cnt
always@(posedge div_cnt[16] or negedge rst)
begin
	if(~rst)
		scan_state <= 2'b00;
	else
		scan_state <= scan_state + 1'b1;
end

always@(posedge div_cnt[16] or negedge rst)
begin
	if(~rst)
		ScanEn <= 4'b1110;
	else
	begin
		case(scan_state)
			2'b00 : ScanEn <= 4'b1101;
			2'b01 : ScanEn <= 4'b1011;
			2'b10 : ScanEn <= 4'b0111;
			2'b11 : ScanEn <= 4'b1110;
		endcase
	end	
end 
//  scan cnt
//
always@(*)
begin
	case(decoderIn)
	4'b0000	: 	DataOut <= ~(8'h3F);
	4'b0001	: 	DataOut <= ~(8'h06);
	4'b0010	:	DataOut <= ~(8'h5B);
	4'b0011	:	DataOut <= ~(8'h4F);
	4'b0100	:	DataOut <= ~(8'h66);
	4'b0101	:	DataOut <= ~(8'h6D);
	4'b0110	:	DataOut <= ~(8'h7D);
	4'b0111	:	DataOut <= ~(8'h27);
	4'b1000	:	DataOut <= ~(8'h7F);
	4'b1001	:	DataOut <= ~(8'h6F);
	4'b1010	:	DataOut <= ~(8'h77);
	4'b1011	:	DataOut <= ~(8'h7C);
	4'b1100	:	DataOut <= ~(8'h58);
	4'b1101	:	DataOut <= ~(8'h5E);
	4'b1110	:	DataOut <= ~(8'h79);
	4'b1111	:	DataOut <= ~(8'h71);
	
	endcase
end

// MUX 4 to 1 TO decoder
always@(*)
begin
	case(scan_state)
	2'b00	: 	decoderIn <= DataIn_A;
	2'b01	: 	decoderIn <= DataIn_B;
	2'b10	: 	decoderIn <= DataIn_C;
	2'b11	: 	decoderIn <= DataIn_D;
	endcase
end


endmodule
