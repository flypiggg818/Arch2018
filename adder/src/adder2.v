/* ACM Class System (I) 2018 Fall Assignment 1 
 *
 * Part I: Write an adder in Verilog
 *
 * Implement your Carry Look Ahead Adder here
 * 
 * GUIDE:
 *   1. Create a RTL project in Vivado
 *   2. Put this file into `Sources'
 *   3. Put `test_adder.v' into `Simulation Sources'
 *   4. Run Behavioral Simulation
 *   5. Make sure to run at least 100 steps during the simulation (usually 100ns)
 *   6. You can see the results in `Tcl console'
 *
 */

module Adder(
	input wire [15:0] A, B,
	output wire [15:0] rslt,
	output wire cout
); 
	wire [3:0] P; 
	wire [3:0] G; 
	wire Cin; 
	wire [3:0] C; 
	wire [3:0] wst; 
	CLU_16 CLU_16_0(.P(P), .G(G), .Cin(Cin), .C(C), .Cout(cout));
	bit4_adder FBA_0(.A(A[3:0]), .B(B[3:0]), .Cin(C[0]), .rslt(rslt[3:0]), .Cout(wst[0]), .PP(P[0]), .GG(G[0])); 
	bit4_adder FBA_1(.A(A[7:4]), .B(B[7:4]), .Cin(C[1]), .rslt(rslt[7:4]), .Cout(wst[1]), .PP(P[1]), .GG(G[1]));
	bit4_adder FBA_2(.A(A[11:8]), .B(B[11:8]), .Cin(C[2]), .rslt(rslt[11:8]), .Cout(wst[2]), .PP(P[2]), .GG(G[2]));
	bit4_adder FBA_3(.A(A[15:12]), .B(B[15:12]), .Cin(C[3]), .rslt(rslt[15:12]), .Cout(wst[3]), .PP(P[3]), .GG(G[3]));
endmodule

// implement each building block
module bit_full_adder(
	input wire A, // operands 
	input wire B, 
	input wire Cin, // carry 
	output wire P, // helper
	output wire G, 
	output wire S // bit sum  
); 
	assign P = A | B;
	assign G = A & B; 
	assign S = A ^ B ^ Cin; 
endmodule

module CLU_4(
	input wire [3:0] P, // adders info
	input wire [3:0] G, 
	input wire Cin, // total cin
	output wire [3:0] C, // adder carry rslt
	output wire Cout, // for 16-CLU
	output wire PP, 
	output wire GG
); 
	assign C[0] = Cin; 
	assign C[1] = G[0] | P[0] & C[0];
	assign C[2] = G[1] | P[1] & G[0] | P[1] & P[0] & C[0]; 
	assign C[3] = G[2] | P[2] & G[1] | P[2] & P[1] & G[0] | P[2] & P[1] & P[0] & C[0]; 
	assign Cout = G[3] | P[3] & G[2] | P[3] & P[2] & G[1] | P[3] & P[2] & P[1] & G[0] | P[3] & P[2] & P[1] & P[0] & C[0]; 
	assign GG = G[3] | P[3] & G[2] | P[3] & P[2] & G[1] | P[3] & P[2] & P[1] & G[0]; 
	assign PP = P[3] & P[2] & P[1] & P[0];  
endmodule

// digital element wrapper
module bit4_adder(
	input wire [3:0] A,
	input wire [3:0] B, 
	input wire Cin, 
	output wire [3:0] rslt,
	output wire Cout,
	output wire PP, 
	output wire GG
);
	wire [3:0] P; 
	wire [3:0] G; 
	wire [3:0] C; 
	CLU_4 CLU_4_0(.P(P), .G(G), .Cin(Cin), .C(C), .Cout(Cout), .PP(PP), .GG(GG)); 
	bit_full_adder FA_0(.A(A[0]), .B(B[0]), .Cin(C[0]), .P(P[0]), .G(G[0]), .S(rslt[0])); 
	bit_full_adder FA_1(.A(A[1]), .B(B[1]), .Cin(C[1]), .P(P[1]), .G(G[1]), .S(rslt[1])); 
	bit_full_adder FA_2(.A(A[2]), .B(B[2]), .Cin(C[2]), .P(P[2]), .G(G[2]), .S(rslt[2])); 
	bit_full_adder FA_3(.A(A[3]), .B(B[3]), .Cin(C[3]), .P(P[3]), .G(G[3]), .S(rslt[3])); 
endmodule 

module CLU_16(
	input wire [3:0] P,
	input wire [3:0] G, 
	input wire Cin, 
	output wire [3:0] C, 
	output wire Cout
);
	assign C[0] = Cin; 
	assign C[1] = G[0] | P[0] & C[0];
	assign C[2] = G[1] | P[1] & G[0] | P[1] & P[0] & C[0]; 
	assign C[3] = G[2] | P[2] & G[1] | P[2] & P[1] & G[0] | P[2] & P[1] & P[0] & C[0]; 
	assign Cout = G[3] | P[3] & G[2] | P[3] & P[2] & G[1] | P[3] & P[2] & P[1] & G[0] | P[3] & P[2] & P[1] & P[0] & C[0]; 
endmodule