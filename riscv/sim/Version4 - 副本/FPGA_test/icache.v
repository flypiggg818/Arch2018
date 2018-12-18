`include "macro.vh"

/**
  The input address of this cache needs to be maintained when missing. 
  But it will free IF right before it completes block replacement so that the 
  first instruction after recovery is correctly appointed by IF. 
*/
module ICACHE
#(
	parameter INSTSEL_BIT = 2, // instruction is the smallest storage element.  4 instruction per row 
	parameter ROW_BIT = 2, 
	parameter SET_BIT = 1
)
(
	input wire clk, 
	input wire rst, 
	
	input wire re_IF_i, 
	input wire[31:0] addr_IF_i, 
	output reg[31:0] data_IF_o, 
	output wire miss_IF_o, // can be busy or done, feedback to IF module 

	// copied from MEM module 
	output reg re_CTRL_o, // read enable 
	output reg[31:0] addr_CTRL_o, 
	input wire[7:0] data_RAM_i, 

  input wire stl_CTRL_i
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
	wire[TAG_BIT-1:0]				  rtag 		= addr_IF_i[TAG_BIT+(ROW_BIT+INSTSEL_BIT+2) - 1:ROW_BIT+INSTSEL_BIT+2]; // 16:14
	
  /** miss detector */
	wire miss; 
	wire[SET_NUM-1:0] miss_in_set; // this is one-hot encoding, where each bit represent a cache. Note that we are not using binary representation here. 
	assign miss = &miss_in_set; 
	assign miss_IF_o = miss; // re_IF_i && miss; 
	generate 
		genvar i; 
		for (i = 0; i < SET_NUM; i = i+1) begin 
			assign miss_in_set[i] =  re_IF_i && (!valid[rrow][i] || tag[rrow][i] != rtag); 
		end 
	endgenerate 

	localparam STATE_INIT 				= 5'h0; 
	localparam STATE_RAM_ACCESS 	= 5'h1; 
	localparam STATE_FINISH       = 5'h2; 

	integer rt, st; // row_interator, set_interator
	reg[4:0] FSM; 
	// target configuration 
	reg[SET_BIT-1:0] 	      tar_set; 
  reg[31:0] tar_addr; // delayed address 
  wire[INSTSEL_BIT+1:0]   tar_pos = tar_addr[INSTSEL_BIT+1:0]; // where to put 
	wire[INSTSEL_BIT-1:0] 	tar_inst = tar_addr[INSTSEL_BIT+1:2]; 
	wire[1:0] 					    tar_byte = tar_addr[1:0]; 
	reg[INSTSEL_BIT+1:0]    saturate_pos = -1; 
	wire[INSTSEL_BIT+1:0] lowCTRLaddr_pos = addr_CTRL_o[INSTSEL_BIT+1:0]; 
	reg wait_flag; 
	
	always @ (posedge clk) begin 
		if (rst == `Enable) begin 			// reset cache content 
			for (rt = 0; rt < ROW_NUM; rt = rt+1)
				for (st = 0; st < SET_NUM; st = st+1) begin 
					valid[rt][st] <= `Disable; 
					rectuse[rt] <= 1'b0; 
				end 
			re_CTRL_o <= `Disable; 
			addr_CTRL_o <= `ZeroWord; 
			tar_set <= 'b0; 
			FSM <= STATE_INIT; 
		end else begin 
			case (FSM)
				STATE_INIT: begin 
					if (miss) begin 
						// set RAM_CTRL access configuration 
						addr_CTRL_o[31:INSTSEL_BIT+2] <= addr_IF_i[31:INSTSEL_BIT+2]; 
						addr_CTRL_o[INSTSEL_BIT+2-1:0] <= 'b0; 
						re_CTRL_o <= `Enable; 
						tar_set <= ~rectuse[rrow]; 
						FSM <= STATE_RAM_ACCESS; 
						wait_flag <= 1'b1; // need to wait in the next clock 
					end else begin 
					end 
				end 
				STATE_RAM_ACCESS: begin // control signal has been sent to RAM_CTRL in INIT STATE
          /** RAM ACCESS may not be able to start, but once start, it's unstopable. */
          if (stl_CTRL_i) begin end 
          else if (wait_flag) begin 
            wait_flag <= 1'b0; 
            tar_addr <= addr_CTRL_o; // prepare to put into the first place. 
            addr_CTRL_o <= addr_CTRL_o + 1; 
          end else begin 
            // take data from RAM to CACHE 
            data[rrow][tar_set][tar_inst] = data[rrow][tar_set][tar_inst] >> 32'h8; 
						data[rrow][tar_set][tar_inst][31:24] = data_RAM_i; 
            // finish if complete fetching
            if (lowCTRLaddr_pos != saturate_pos) begin 
							addr_CTRL_o 	<= addr_CTRL_o + 1; 
              tar_addr <= tar_addr + 1; 
           	end else begin // tar_pos == saturated_pos. It's incremented the previous cycle, thus the data is just fetched on bus. 
              addr_CTRL_o 	<= `ZeroWord; 
							re_CTRL_o 		<= `Disable; 
							FSM						 	<= STATE_FINISH; 
              tar_addr <= tar_addr + 1; // now, addr_CTRL_o == saturated_pos, while tar_addr increments to be saturated. 
            end 
          end 
        end 
        STATE_FINISH: begin 
          data[rrow][tar_set][tar_inst] = data[rrow][tar_set][tar_inst] >> 32'h8; 
          data[rrow][tar_set][tar_inst][31:24] = data_RAM_i; 
          FSM <= STATE_INIT; 
          // update cache tag, valid, and recentuse, which eliminates miss (exclude FSM's STATE_RAM_ACCESS). 
          // instruction sent back to IF instantly. 
          tag[rrow][tar_set] <= rtag; 
          valid[rrow][tar_set] <= `Enable; 
          rectuse[rrow] <= tar_set; 
        end 
        default: begin end 
      endcase 
    end 
	end 
	
	/** asynchronous cache access */ 
	always @ (*) begin 
		if (rst == `Enable) begin 
			data_IF_o = `ZeroWord; 
		end else if (!miss_IF_o && re_IF_i) begin 
			data_IF_o = (miss_in_set[0]) ? data[rrow][1][rinst] : data[rrow][0][rinst];
		end else begin 
			data_IF_o = `ZeroWord; 
		end 
	end 
endmodule 
