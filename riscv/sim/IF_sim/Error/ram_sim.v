
`timescale 1ns / 1ps

/**
  This is a simulation testbench for riscv cpu. 
  It contains both cpu and ram. 
*/
module ram_sim;

	localparam RAM_ADDR_WIDTH = 17; 			// 128KiB ram, should not be modified
  
  // cpu instantiation 
  reg clk, rst, rdy;
  initial begin 
  	clk <= 1'b0; 
		forever #20 clk = ~clk; 
  end 

  reg[31:0] ram_a; 
  reg[7:0] cprm_dwrite; 
  wire[7:0] cprm_dread; 
  
	initial begin 
		rst <= 1'b1; 
    #50 rdy <= 1'b1; rst <= 1'b0; 
    #100 ram_a <= 32'h2;
    #5000 $stop; 
	end 
	
  always @ (posedge clk) begin 
    if(rst == 1'b1) begin 
      ram_a <= 32'b0; 
    end 
  end 

  ram ram0(.clk_in(clk), 
           .en_in(1'b1), 
           .r_nw_in(1'b1), 
           .a_in(ram_a), 
           .d_in(cprm_dwrite), 
           .d_out(cprm_dread)); 

endmodule 