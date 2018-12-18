`include "macro.vh"

// module port naming convention: name_dstModule_i/o. 
/**
  IF module is a combinational logic to catch up to 5 cycles. But considering more slower parts, we use 6 times divided clock here. 
  See README in sim/IF_sim for more instruction. 
*/
module IF(
  input wire clk, 
  input wire rst, 
  input wire[1:0] stl_STALLER_i,

  // ram ce is true when addr is valid (handled in cpu module). 
  output reg re_CACHE_o,
	output reg[31:0] addr_CACHE_o, 
  input wire[31:0] data_CACHE_i, 
  input wire hit_CACHE_i, 
  input wire JBje_ID_i, // jump enable provided by ID 
  input wire[31:0] JBtaraddr_ID_i, 
  
  output reg[31:0] inst_IFID_o, 
  output reg[31:0] pc_IFID_o // pass down pc value used by JUMP and BRANCH in ID. 
); 
	
	reg[31:0] JBtaraddr_temp; 
	always @ (posedge clk or posedge rst) begin
		if (rst == `Enable) begin
			re_CACHE_o <= `Disable; 
			addr_CACHE_o <= `ZeroWord; 
			inst_IFID_o <= `ZeroWord; 
			pc_IFID_o <= `ZeroWord;  
			JBtaraddr_temp <= 32'hffffffff; 
		end else if (JBje_ID_i) begin 
			re_CACHE_o <= `Enable; 
			addr_CACHE_o <= (hit_CACHE_i) ? JBtaraddr_ID_i : addr_CACHE_o; 
//			addr_CACHE_o <= JBtaraddr_ID_i;
			JBtaraddr_temp <= (hit_CACHE_i) ? 32'hffffffff : JBtaraddr_ID_i; 
			inst_IFID_o <= `ZeroWord; 
			pc_IFID_o <= `ZeroWord;  
		end else  if (stl_STALLER_i == `STALL) begin // if IF is stalled, then don't do anything.
		end else if (hit_CACHE_i) begin 
			re_CACHE_o <= `Enable; 
			inst_IFID_o <= (JBtaraddr_temp == 32'hffffffff) ? data_CACHE_i : `ZeroWord; 
			pc_IFID_o <= (JBtaraddr_temp == 32'hffffffff) ? addr_CACHE_o : `ZeroWord; 
			addr_CACHE_o <= (JBtaraddr_temp == 32'hffffffff) ? addr_CACHE_o + 32'h4 : JBtaraddr_temp; 
			JBtaraddr_temp <= 32'hffffffff; 
		end  else begin
			re_CACHE_o <= `Enable; 
			inst_IFID_o <= `ZeroWord; 
			pc_IFID_o <= `ZeroWord;
		end 
	end 
endmodule 