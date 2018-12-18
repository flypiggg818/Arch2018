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
  input wire miss_CACHE_i, 
  input wire JBje_ID_i, // jump enable provided by ID 
  input wire[31:0] JBtaraddr_ID_i, 
  
  output wire[31:0] inst_IFID_o, // note these two signals have to be combinational 
  output wire[31:0] pc_IFID_o // pass down pc value used by JUMP and BRANCH in ID. 
); 

	reg[31:0] JBtaraddr_temp; // can't modify addr_CACHE_o when miss, because it's used as combinational logic input in ICACHE. 
  // make output combinational. Data passed to IFID at the next clock cycle. 
  // when JBtaraddr_temp isn't blocked, the instruction fetched is not the most updated branch address 
   reg recover; // when recover=1, cache will be available the next posedge, thus prepare address this posedge. 
 assign inst_IFID_o = (miss_CACHE_i || recover) ? 32'b0 : data_CACHE_i; 
  assign pc_IFID_o = (miss_CACHE_i || recover) ? 32'b0 : addr_CACHE_o; 

  always @ (posedge clk or posedge rst) begin 
    if (rst == `Enable) begin 
			re_CACHE_o <= `Disable; 
			 addr_CACHE_o <= `ZeroWord;
//			addr_CACHE_o <= 32'h10054;  
      JBtaraddr_temp <= 32'hffffffff; 
      recover <= `Disable; 
    end else if (stl_STALLER_i == `STALL) begin // if IF is stalled, don't do anything 
    end else begin 
      re_CACHE_o <= `Enable; 
      if (JBje_ID_i) begin 
        if (miss_CACHE_i) begin  
          recover <= `Enable; 
          JBtaraddr_temp <= JBtaraddr_ID_i; 
        end else if (recover) begin 
          recover <= `Disable; 
          addr_CACHE_o <= JBtaraddr_ID_i; // replace the most recent address 
          JBtaraddr_temp <= 32'hffffffff; // clean address cache 
        end else begin 
          addr_CACHE_o <= JBtaraddr_ID_i; 
          JBtaraddr_temp <= 32'hffffffff;
        end 
      end else begin 
        if (miss_CACHE_i) begin 
          recover <= `Enable;
        end else if (recover) begin 
          recover <= `Disable; 
          addr_CACHE_o <= (JBtaraddr_temp == 32'hffffffff) ? addr_CACHE_o : JBtaraddr_temp; 
          JBtaraddr_temp <= 32'hffffffff;
        end else begin 
          addr_CACHE_o <= (re_CACHE_o) ? addr_CACHE_o + 32'h4 : addr_CACHE_o; // wait for IF restart
        end 
      end 
    end 
  end 
endmodule 