`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:55:34 06/16/2016 
// Design Name: 
// Module Name:    OSC 
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
module OSC(Start, Tout);
    input Start;
    output Tout;
	 wire w1 /* synthesis keep = 1 */;
	 wire w2 /* synthesis keep = 1 */;
	 wire w3 /* synthesis keep = 1 */;
	 wire w4 /* synthesis keep = 1 */;
	 wire w5 /* synthesis keep = 1 */;
	 wire w6 /* synthesis keep = 1 */;
	 wire w7 /* synthesis keep = 1 */;
	 wire w8 /* synthesis keep = 1 */;
	 wire w9 /* synthesis keep = 1 */;	 
	 
NAND2 n1(w1,w9,Start);
NAND2 n2(w2,w1,w1);
NAND2 n3(w3,w2,w2);
NAND2 n4(w4,w3,w3);
NAND2 n5(w5,w4,w4);
NAND2 n6(w6,w5,w5);
NAND2 n7(w7,w6,w6);
NAND2 n8(w8,w7,w7);
NAND2 n9(w9,w8,w8);
NAND2 n10(Tout,1'b1,w9);

endmodule
