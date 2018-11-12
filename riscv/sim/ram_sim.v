`timescale 1ns / 1ps

/**
  This is a simulation testbench for riscv cpu. 
  It contains both cpu and ram. 
*/
module ram_sim; 

  reg clk, rst; 
	wire [7:0] dread; 
	reg [7:0] dwrite; 
	reg [31:0] addr; 
	reg wr;
	reg ram_ce; 
  initial begin 
  	clk <= 1'b0; 
		forever #10 clk = ~clk; 
  end 

initial begin
  rst <= 1'b1; 
  ram_ce <= 1'b1; 
	addr <= 32'b0; 
	wr <= 1'b1; 
  #195 rst <= 1'b0; 
	#50 addr <= addr + 1'b1; 
	#50 addr <= addr + 1'b1; 
	#50 addr <= addr + 1'b1; 
	#50 addr <= addr + 1'b1; 
  #4000 rst <= 1'b1; 
  #5000 $stop; 
end 
	  

  ram ram0(.clk_in(clk), 
           .en_in(ram_ce), 
           .r_nw_in(wr), 
           .a_in(addr), 
           .d_in(dwrite), 
           .d_out(dread)); 
endmodule 