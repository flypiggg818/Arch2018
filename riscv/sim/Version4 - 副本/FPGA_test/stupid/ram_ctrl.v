`include "macro.vh"

/** encapsulate ram from upward modules. Status are BUSY and DONE, which means whether ram_ctrl has completed its work. 
			Note that DONE signal comes out together with current completed data. 			
			The throughput capacity is 8 bits. 
*/
/**
	Clarify that ram_ctrl is a combinational logic rather than sequential 
*/
module RAMCTRL(
	input wire clk, 
	input wire rst, 
	
	input wire re_CACHE_i, // IF always reading, no re\we signal. 
	input wire[31:0] addr_CACHE_i, 
	output wire[7:0] data_CACHE_o, 
	output reg status_CACHE_o, // when DONE
	
	input wire[1:0] rw_MEM_i, // rw[1] for read, rw[0] for write. No read and write at the same time.
	input wire[31:0] addr_MEM_i,
	output wire[7:0] rdata_MEM_o,  
	input wire[7:0] wdata_MEM_i,
//	output reg status_MEM_o, // when DONE  

	output wire wr_RAM_o, // 1 for write 
	output reg[31:0] addr_RAM_o, 
	output wire[7:0] wdata_RAM_o, 
	input wire[7:0] rdata_RAM_i
); 
	
	localparam NOP = 2'h0; 
	localparam CACHE = 2'h1; 
	localparam MEM = 2'h2; 
	reg[1:0] accessor; 
	
	// wire-assign for write-read enable signal 
	assign wr_RAM_o = (rw_MEM_i[0]) ? 1'b1 : 1'b0; // if write request issued by MEM, then write, overwise read. 
	// always block for addr and wdata assignment 
	assign wdata_RAM_o = (rw_MEM_i[0]) ? wdata_MEM_i : 8'b0; 
	// assign asynchronous data feedback. 
	assign data_CACHE_o = (accessor == CACHE) ? rdata_RAM_i : 8'b0; 
	assign rdata_MEM_o = (accessor == MEM) ? rdata_RAM_i : 8'b0; 
	// choose which task to do.  
	always @ (*) begin 
		if (rw_MEM_i[0]) begin // write
			accessor = MEM; 
			addr_RAM_o = addr_MEM_i; 
			status_CACHE_o = `BUSY; 
		end else if (rw_MEM_i[1]) begin // mem read  
			accessor = MEM; 
			addr_RAM_o = addr_MEM_i; 
			status_CACHE_o = `BUSY; 
		end else if (re_CACHE_i) begin // cache read 
			accessor = CACHE; 
			addr_RAM_o = addr_CACHE_i; 
			status_CACHE_o = `DONE;  
		end else begin 
			accessor = NOP; 
		end 
	end 
endmodule 