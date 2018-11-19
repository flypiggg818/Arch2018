`timescale 1ns / 1ps
`include "macro.vh"

/**
  test MEM module's ram-reading-access 
*/
module mem_read_sim;

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

  wire re_MEM_o; 
  wire[31:0] raddr_MEM_o; 
  wire[7:0] rdata_MEM_i; 
  wire wreg_MEM_o; 
  wire[4:0] waddr_MEM_o;
  wire[31:0] wdata_MEM_o; 
  MEM MEM0(.rst(rst), 
           .clk(clk), 
           .dclk(dclk), 
           .aluop_EXMEM_i(`ALU_LH_OP), 
           .wreg_EXMEM_i(1'b1),
           .waddr_EXMEM_i(5'b0), 
           .alurslt_EXMEM_i(32'b0), 
           .re_RAM_o(re_MEM_o),
           .raddr_RAM_o(raddr_MEM_o), 
           .rdata_RAM_i(rdata_MEM_i),
           .wreg_MEMWB_o(wreg_MEM_o),  
           .waddr_MEMWB_o(waddr_MEM_o), 
           .wdata_MEMWB_o(wdata_MEM_o)); 

  // ram instantiation
  wire [RAM_ADDR_WIDTH-1:0]	ram_a;
  wire[7:0] data_RAM_o; 
  assign rdata_MEM_i = data_RAM_o; 
  assign ram_a = raddr_MEM_o[RAM_ADDR_WIDTH-1:0];
  ram ram0(.clk_in(clk), 
           .en_in(1'b1), 
           .r_nw_in(1'b1), 
           .a_in(ram_a), 
           .d_in(8'b0), 
           .d_out(data_RAM_o)); 

endmodule 