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


	  
  wire dclk; 
  clk_div clk_div0(clk, rst, dclk);

  wire re_MEM_o; 
  wire[31:0] raddr_MEM_o; 
  wire[7:0] rdata_MEM_i; 
  wire wreg_MEM_o; 
  wire[31:0] waddr_MEM_o;
  wire[31:0] wdata_MEM_o; 
  reg[`AluOpBus] aluop_MEM_i;
  wire we_MEM_o; 
  wire[31:0] wbaddr_MEM_o;
  wire[31:0] wbdata_MEM_o; 
  MEM MEM0(.rst(rst), 
           .clk(clk), 
           .dclk(dclk), 
           .aluop_EXMEM_i(aluop_MEM_i), 
           .wreg_EXMEM_i(1'b1),
           .waddr_EXMEM_i(5'b0), 
           .alurslt_EXMEM_i(32'b0), 
           .SdataBoffset_EXMEM_i(32'b00001111111100000000111111110000), 
           .re_RAM_o(re_MEM_o),
           .raddr_RAM_o(raddr_MEM_o), 
           .rdata_RAM_i(rdata_MEM_i),
           .we_RAM_o(we_MEM_o), 
           .waddr_RAM_o(waddr_MEM_o), 
           .wdata_RAM_o(wdata_MEM_o), 
           .wreg_MEMWB_o(wreg_MEM_o),  
           .waddr_MEMWB_o(wbaddr_MEM_o), // note to distinguish wbaddr_MEM_o from waddr_MEM_o 
           .wdata_MEMWB_o(wbdata_MEM_o)); 

  wire[7:0] wdata_ARB_o;
  wire[31:0] addr_ARB_o; 
  wire wr_ARB_o; 
  RAM_ARBITRATOR RAM_ARBITRATOR0(.rst(rst), 
                                 .re_MEM_i(re_MEM_o), 
                                 .raddr_MEM_i(raddr_MEM_o), 
                                 .we_MEM_i(we_MEM_o), 
                                 .waddr_MEM_i(waddr_MEM_o), 
                                 .wdata_MEM_i(wdata_MEM_o), 
                                 .wdata_RAM_o(wdata_ARB_o), 
                                 .addr_RAM_o(addr_ARB_o), 
                                 .wr_RAM_o(wr_ARB_o)); 

  // ram instantiation
  wire [RAM_ADDR_WIDTH-1:0]	ram_a;
  wire[7:0] rdata_RAM_o; 
  wire r_nw_RAM_i; 
  wire[7:0] wdata_RAM_i; 
  assign r_nw_RAM_i = ~wr_ARB_o; 
  assign rdata_MEM_i = rdata_RAM_o; 
  assign ram_a = addr_ARB_o[RAM_ADDR_WIDTH-1:0];
  assign wdata_RAM_i = wdata_ARB_o; 
  ram ram0(.clk_in(clk), 
           .en_in(1'b1), 
           .r_nw_in(r_nw_RAM_i), 
           .a_in(ram_a), 
           .d_in(wdata_RAM_i), 
           .d_out(rdata_RAM_o)); 

	initial begin 
		rst <= 1'b0; 
		rdy <= 1'b1;
		#100 rst <= 1'b1; 
		#100 rst <= 1'b0;  
		aluop_MEM_i <= `ALU_SW_OP; 
		#200 aluop_MEM_i <= `ALU_LW_OP; 
    #10000 $stop; 
	end 
	
endmodule 