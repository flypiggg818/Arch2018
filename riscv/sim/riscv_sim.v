
`timescale 1ns / 1ps

/**
  This is a simulation testbench for riscv cpu. 
  It contains both cpu and ram. 
*/
module riscv_sim;
	
  // cpu instantiation 
  reg clk, rst, cpu_pause;
  initial begin 
  	clk <= 1'b0; 
		forever #50 clk = ~clk; 
  end 

initial begin 
  rst <= 1'b1; 
  cpu_pause <= 1'b0; 
  #195 rst <= 1'b0; 
  #4000 rst <= 1'b1; 
  #5000 $stop; 
end 
	  
  // cprm is the abbreviation for cpu_ram.
  wire [7:0] cprm_dread; 
  wire [7:0] cprm_dwrite; 
  wire [31:0] cprm_addr; 
  wire cprm_wr;

  wire [31:0] dbgreg_dout; 

  cpu cpu0(.clk_in(clk), 
           .rst_in(rst), 
           .rdy_in(cpu_pause),
           .mem_din(cprm_dread), 
           .mem_dout(cprm_dwrite), 
           .mem_a(cprm_addr), 
           .mem_wr(cprm_wr), 
           .dbgreg_dout(dbgreg_dout));  

  // ram instantiation
  wire ram_ce; 
  ram ram0(.clk_in(clk), 
           .en_in(ram_ce), 
           .r_nw_in(cprm_wr), 
           .a_in(cprm_addr), 
           .d_in(cprm_dwrite), 
           .d_out(cprm_dread)); 
endmodule 