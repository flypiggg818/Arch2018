`timescale 1ns / 1ps

/**
  Fully functional ricv simulation copied from Lin's top module. 
*/
module cache_sim;
	localparam RAM_ADDR_WIDTH = 17; 			// 128KiB ram, should not be modified
	localparam BYTE = 8;  
	// cpu instantiation 
	reg clk, rst, rdy;
	
	reg[1:0] sel; 
	reg[31:0] data;
	reg[7:0] out; 
	
	initial begin 
		clk <= 1'b0; 
		forever #10 clk = ~clk; 
	end 

	initial begin 
		rst <= 1'b0; 
		rdy <= 1'b1;
		#200 rst <= 1'b1; 
		#200 rst <= 1'b0;  

    #5000 $stop; 
	end 
	
endmodule 