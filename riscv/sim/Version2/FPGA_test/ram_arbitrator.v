`include "macro.vh"

// module port naming convention: name_dstModule_i/o. 
/**
  This module regulates 'mem_dout, mem_a, mem_wr'. 
*/
module RAM_ARBITRATOR(
  input wire[31:0] addr_IF_i, // IF always reading, no re\we signal. 
  input wire[3:0] FSM_IF_i, 

  input wire re_MEM_i, 
  input wire[31:0] raddr_MEM_i, 
  input wire we_MEM_i, 
  input wire[31:0] waddr_MEM_i, 
  input wire[7:0] wdata_MEM_i, 

  output reg[31:0] addr_RAM_o, 
  output wire[7:0] wdata_RAM_o, 
  output wire wr_RAM_o, // 1 for write 

  output reg[1:0] accessor_STALLER_o // indicator for current memory accessor 
); 

  // assign accessor 
  always @ (*) begin 
    if ((re_MEM_i == `Disable && we_MEM_i == `Disable)) begin
      // no MEM memory access, world peace 
      accessor_STALLER_o = `IF_ACCESS; 
    end else if (FSM_IF_i != 4'b0000) begin 
      accessor_STALLER_o = `IF_BLOCK_MEM; 
    end else begin 
      accessor_STALLER_o = `MEM_BLOCK_IF; 
    end 
  end 

  // data assignment; only for writing data. 
  assign wdata_RAM_o = (accessor_STALLER_o == `MEM_BLOCK_IF && we_MEM_i == `Enable) ? wdata_MEM_i : 7'b0; 
  // assign RAM read/write control signal. 1 for write
  assign wr_RAM_o = (accessor_STALLER_o == `MEM_BLOCK_IF && we_MEM_i == `Enable) ? 1'b1 : 1'b0; 

  // assign address 
  always @ (*) begin 
    if (accessor_STALLER_o != `MEM_BLOCK_IF) begin 
      addr_RAM_o = addr_IF_i; 
    end else if (we_MEM_i == `Enable) begin 
      addr_RAM_o = waddr_MEM_i; 
    end else begin 
      addr_RAM_o = raddr_MEM_i; 
    end 
  end 
endmodule