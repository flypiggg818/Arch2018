
`timescale 1ns / 1ps

/**
  This is a simulation testbench for riscv cpu. 
  It contains both cpu and ram. 
*/
module if_sim;

	localparam RAM_ADDR_WIDTH = 17; 			// 128KiB ram, should not be modified
  
  // cpu instantiation 
  reg clk, rst, rdy;
  initial begin 
  	clk <= 1'b0; 
		forever #20 clk = ~clk; 
  end 

	initial begin 
		rst <= 1'b1; 
    #50 rdy <= 1'b1; rst <= 1'b0; 
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
           .rdy_in(rdy),
           .mem_din(cprm_dread), 
           .mem_dout(cprm_dwrite), 
           .mem_a(cprm_addr), 
           .mem_wr(cprm_wr), 
           .dbgreg_dout(dbgreg_dout));  

  // ram instantiation
  wire [RAM_ADDR_WIDTH-1:0]	ram_a;
  assign ram_a = cprm_addr[RAM_ADDR_WIDTH-1:0];
  reg[16:0] cnt; 
  always @ (posedge clk) begin 
  	if (rst == 1'b1) begin 
  		cnt <= 17'b0; 
  	end else begin 
  		cnt <= (cnt + 17'b1) & (3'b111); 
  	end 
  end 
  ram ram0(.clk_in(clk), 
           .en_in(1'b1), 
           .r_nw_in(cprm_wr), 
           .a_in(cnt), 
           .d_in(cprm_dwrite), 
           .d_out(cprm_dread)); 

endmodule 