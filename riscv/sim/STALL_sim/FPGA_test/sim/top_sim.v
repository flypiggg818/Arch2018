`timescale 1ns / 1ps

/**
  This is a simulation testbench for riscv cpu. 
  It contains both cpu and ram.
  But some ram ports are assigned as contant, thus not fully functional. 
*/
module top_sim;

	localparam RAM_ADDR_WIDTH = 17; 			// 128KiB ram, should not be modified
  
  // cpu instantiation 
  reg clk, rst, rdy;
  initial begin 
  	clk <= 1'b0; 
		forever #10 clk = ~clk; 
  end 

	initial begin 
		rst <= 1'b0; 
		rdy <= 1'b1;
		#100 rst <= 1'b1; 
		#100 rst <= 1'b0;  
    #10000 $stop; 
	end 
	  
  // cprm is the abbreviation for cpu_ram.
  wire [7:0] cprm_dread; 
  wire [7:0] cprm_dwrite; 
  wire [31:0] cprm_addr; 
  wire cprm_wr;
  wire [31:0] dbgreg_dout; 
  cpu cpu0(.clk_in(clk), 
           .rst_in(rst), 
           .rdy_in(rdy),
           .mem_din(cprm_dread), 
           .mem_dout(cprm_dwrite), 
           .mem_a(cprm_addr), 
           .mem_wr(cprm_wr), 
           .dbgreg_dout(dbgreg_dout));  

  // ram instantiation
  wire [RAM_ADDR_WIDTH-1:0]	ram_a;
  assign ram_a = cprm_addr[RAM_ADDR_WIDTH-1:0];
  ram ram0(.clk_in(clk), 
           .en_in(1'b1), 
           .r_nw_in(1'b1), 
           .a_in(ram_a), 
           .d_in(cprm_dwrite), 
           .d_out(cprm_dread)); 

endmodule 