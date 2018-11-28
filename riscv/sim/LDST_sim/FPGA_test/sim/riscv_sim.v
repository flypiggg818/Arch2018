`timescale 1ns / 1ps

/**
  Fully functional ricv simulation copied from Lin's top module. 
*/
module riscv_sim;
	
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
		#200 rst <= 1'b0;  
    #10000 $stop; 
	end 
		
	//
	// System Memory Buses
	//
	wire [ 7:0]	cpumc_din;
	wire [31:0]	cpumc_a;
	wire        cpumc_wr;
	
	//
	// RAM: internal ram
	//
	wire 						ram_en;
	wire [RAM_ADDR_WIDTH-1:0]	ram_a;
	wire [ 7:0]					ram_dout;
	
	ram #(.ADDR_WIDTH(RAM_ADDR_WIDTH))ram0(
		.clk_in(clk),
		.en_in(ram_en),
		.r_nw_in(~cpumc_wr),
		.a_in(ram_a),
		.d_in(cpumc_din),
		.d_out(ram_dout)
	);
	
	assign 		ram_en = (cpumc_a[RAM_ADDR_WIDTH] == 1'b1) ? 1'b0 : 1'b1;
	assign 		ram_a = cpumc_a[RAM_ADDR_WIDTH-1:0];
	
	//
	// CPU: CPU that implements RISC-V 32b integer base user-level real-mode ISA
	//
	wire [31:0] cpu_ram_a;
	wire        cpu_ram_wr;
	wire [ 7:0] cpu_ram_din;
	wire [ 7:0] cpu_ram_dout;
	wire		cpu_rdy;
	
	wire [31:0] cpu_dbgreg_dout;
	cpu cpu0(
		.clk_in(clk),
		.rst_in(rst),
		.rdy_in(cpu_rdy),
	
		.mem_din(cpu_ram_din),
		.mem_dout(cpu_ram_dout),
		.mem_a(cpu_ram_a),
		.mem_wr(cpu_ram_wr),
	
		.dbgreg_dout(cpu_dbgreg_dout)	// demo
	);

// Mux cpumc signals from cpu or hci blk, depending on debug break state (hci_active).
assign cpumc_a      = cpu_ram_a;
assign cpumc_wr		= cpu_ram_wr;
assign cpumc_din    = cpu_ram_dout;

assign cpu_ram_din 	=  ram_dout;

endmodule 