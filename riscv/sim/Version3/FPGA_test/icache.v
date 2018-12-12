`include "macro.vh"

/**
  Before, RAM_ARBITRATOR and RAM are connected directly with each other. While now, cache builds a bridge with them. 
  Note that this cache has to support parallel access of four bytes, which may cause 4 misses at the same time. 
  for a 32-bit addr, we have bytesel 1:0, rowsel 12:2, cachetag 16:13. 
*/

/**
	Think about what a cache should do? READ & WRITE. 
	These two tasks can be regarded as one task.
	First sub-task is hit/miss detection, which requires a little bit port declaration trick.  
	If hit, then everything is fine. 
	Second sub-task is miss rescure, which consists of dirty detection, write back and fetch new data from ram to cache. And maintain which cache to replace in an association. 
	Maintain which cache to replace in an association is a tricky task. We maintain a recent-use-counter, because this is two-way association, the least-recent used way is the opposite of the 
	recently used way, a tiny flip will do. 
*/

/**
	Get really used to the difference between vector and array. 
*/

/**
	The problem really lies here, a query may cause miss in multiple rows, and I need to detect them simultaneously? 
*/
/**
	OK, I give up writing dcache, Icache is OK... 
*/
/**
	This is a simplified cache which is read-only and no concern needs to be paid for BYTE-SELECTION 
*/
module ICACHE
#(
	parameter INSTSEL_BIT = 2, // instruction is the smallest storage element.  4 instruction per row 
	parameter ROW_BIT = 1, 
	parameter SET_BIT = 1
)
(
	input wire clk, 
	input wire rst, 
	
	input wire re_IF_i, 
	input wire[31:0] addr_IF_i, 
	output reg[31:0] data_IF_o, 
	output wire hit_IF_o, // can be busy or done, feedback to IF module 
		
	// copied from MEM module 
	output reg re_RAMCTRL_o, // read enable 
	output reg[31:0] addr_RAMCTRL_o, 
	input wire[7:0] data_RAMCTRL_i, 
	input wire status_RAMCTRL_i
); 
	localparam TAG_BIT = 17 - 2 - INSTSEL_BIT - ROW_BIT; // 17-2-2-10 = 3
	localparam ROW_NUM = 1 << ROW_BIT; 
	localparam SET_NUM 	= 1 << SET_BIT;
	localparam INST_NUM = 1 << INSTSEL_BIT; 
	
	// which row, in which set, which instruction. 
	reg[31:0] 									data[ROW_NUM-1:0][SET_NUM-1:0][INST_NUM-1:0];
	reg[TAG_BIT-1:0] 						tag[ROW_NUM-1:0][SET_NUM-1:0]; 
	// cache row can be in three status : invalid (uninitialized), clean, dirty. But here this is a read-only cache, only consider whether valid. 
	reg  												valid[ROW_NUM-1:0][SET_NUM-1:0];
	// record which SET is used most recently, thus determining which SET to be replaced for a particular ROW when miss happens.  
	// Note that only when SET number is 2 can we do this trick. 
	reg 												rectuse[ROW_NUM-1:0];
	
	// translate raddress into selection signal. rinst: read_inst
	wire[INSTSEL_BIT-1:0] 		rinst 	= addr_IF_i[INSTSEL_BIT+2 - 1:2]; 	// 3:2
	wire[ROW_BIT-1:0] 				rrow 	= addr_IF_i[ROW_BIT+(INSTSEL_BIT+2) - 1:INSTSEL_BIT+2]; 				// 13:4
	wire[TAG_BIT-1:0]				rtag 		= addr_IF_i[TAG_BIT+(ROW_BIT+INSTSEL_BIT+2) - 1:ROW_BIT+INSTSEL_BIT+2]; // 16:14
	
	// these are read info buffers, beacause IF may change reading address while missing. 
//	reg[INSTSEL_BIT-1:0] 		rinst_bf; // 3:2
//	reg[ROW_BIT-1:0] 				rrow_bf; // 13:4
//	reg[TAG_BIT-1:0]				rtag_bf; // 16:14
	
	wire miss; 
	wire[SET_NUM-1:0] miss_in_set; // this is one-hot encoding, where each bit represent a cache. Note that we are not using binary representation here. 
	generate 
		genvar i; 
		for (i = 0; i < SET_NUM; i = i+1) begin 
			assign miss_in_set[i] =  re_IF_i && (!valid[rrow][i] || tag[rrow][i] != rtag); 
		end 
	endgenerate 

	localparam STATE_INIT 				= 5'h0; 
	localparam STATE_RAM_ACCESS 	= 5'h1; 
	
	integer rt, st; // row_interator, set_interator
	reg[4:0] FSM; 
	// target configuration 
	reg[SET_BIT-1:0] 	tar_set; 
	wire[INSTSEL_BIT+1:0] tar_pos = addr_RAMCTRL_o[INSTSEL_BIT+1:0]; 
	wire[INSTSEL_BIT-1:0] 	tar_inst = addr_RAMCTRL_o[INSTSEL_BIT+1:2]; 
	wire[1:0] 					tar_byte = addr_RAMCTRL_o[1:0]; 
	reg[INSTSEL_BIT+1:0] saturate_pos = -1; 
	reg wait_flag; 
	
	always @ (posedge clk) begin 
		if (rst == `Enable) begin 			// reset cache content 
			for (rt = 0; rt < ROW_NUM; rt = rt+1)
				for (st = 0; st < SET_NUM; st = st+1) begin 
					valid[rt][st] <= `Disable; 
					rectuse[rt] <= 1'b0; 
				end 
			re_RAMCTRL_o <= `Disable; 
			addr_RAMCTRL_o <= `ZeroWord; 
			tar_set <= 'b0; 
			FSM <= STATE_INIT; 
		end else begin 
			case (FSM)
				STATE_INIT: begin 
					if (miss) begin 
						// set RAM_CTRL access configuration 
						addr_RAMCTRL_o[31:INSTSEL_BIT+2] <= addr_IF_i[31:INSTSEL_BIT+2]; 
						addr_RAMCTRL_o[INSTSEL_BIT+2-1:0] <= 'b0; 
						re_RAMCTRL_o <= `Enable; 
						tar_set <= ~rectuse[rrow]; 
						FSM <= STATE_RAM_ACCESS; 
						wait_flag <= 1'b1; // need to wait in the next clock 
//						rinst_bf <= rinst; // 3:2
//						rrow_bf <= rrow; // 13:4
//						rtag_bf <= rtag; // 16:14
					end else begin 
					end 
				end 
				STATE_RAM_ACCESS: begin // control signal has been sent to RAM_CTRL in INIT STATE
					if (status_RAMCTRL_i == `BUSY) begin 
						wait_flag <= 1'b1; 
					end else if (wait_flag == 1'b1) begin 
						wait_flag <= 1'b0; 
					end else begin 
						// take data from RAM to CACHE 
						data[rrow][tar_set][tar_inst] = data[rrow][tar_set][tar_inst] >> 32'h8; 
						data[rrow][tar_set][tar_inst][31:24] = data_RAMCTRL_i; 
						// finish if complete fetching
						if (tar_pos != saturate_pos) begin 
							addr_RAMCTRL_o 	<= addr_RAMCTRL_o + 1; 
							wait_flag <= 1'b1; 
						end else begin 
							addr_RAMCTRL_o 	<= `ZeroWord; 
							re_RAMCTRL_o 		<= `Disable; 
							tar_set 					<= 'b0; 
							FSM						 	<= STATE_INIT; 
							// update cache tag, valid, and recentuse, which eliminates miss (exclude FSM's STATE_RAM_ACCESS). 
							tag[rrow][~rectuse[rrow]] <= rtag; 
							valid[rrow][~rectuse[rrow]] <= `Enable; 
							rectuse[rrow] <= ~rectuse[rrow]; 
						end 
					end 
				end 
				default: begin end 
			endcase 
		end 
	end 

	assign miss = &miss_in_set; 
	assign hit_IF_o = re_IF_i && !miss; 
	
	/** asynchronous cache access */ 
	always @ (*) begin 
		if (hit_IF_o) begin 
			data_IF_o = (miss_in_set[0]) ? data[rrow][1][rinst] : data[rrow][0][rinst];
		end else begin 
			data_IF_o = `ZeroWord; 
		end 
	end 
endmodule 
