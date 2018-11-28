`timescale 1ns / 1ps

/**
  Since the clock cycle has been changed, retest IF module 
*/
module if_sim;

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
	  
  wire dclk; 
  clk_div clk_div0(clk, rst, dclk);

  wire[31:0] addr_IF_o; 
  wire[7:0] data_IF_i; 
  wire[31:0] inst_IF_o; 
  IF IF0(.clk(clk), 
         .dclk(dclk), 
         .rst(rst), 
         .rdy(rdy), 
         .addr_RAM_o(addr_IF_o), 
         .data_RAM_i(data_IF_i), 
         .inst_IFID_o(inst_IF_o));   

  // ram instantiation
  wire [RAM_ADDR_WIDTH-1:0]	ram_a;
  wire[7:0] data_RAM_o; 
  assign data_IF_i = data_RAM_o; 
  assign ram_a = addr_IF_o[RAM_ADDR_WIDTH-1:0];
  ram ram0(.clk_in(clk), 
           .en_in(1'b1), 
           .r_nw_in(1'b1), 
           .a_in(ram_a), 
           .d_in(8'b0), 
           .d_out(data_RAM_o)); 

endmodule 