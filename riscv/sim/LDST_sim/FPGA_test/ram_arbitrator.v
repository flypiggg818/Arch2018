`include "macro.vh"

// module port naming convention: name_dstModule_i/o. 

/**
  This module regulates 'mem_dout, mem_a, mem_wr'. 
*/
module RAM_ARBITRATOR(
  input wire rst, 
  
  input wire[31:0] addr_IF_i, 
  
  input wire re_MEM_i, 
  input wire[31:0] raddr_MEM_i, 
  input wire we_MEM_i, 
  input wire[31:0] waddr_MEM_i, 
  input wire[7:0] wdata_MEM_i, 

  output wire[7:0] wdata_RAM_o, 
  output reg[31:0] addr_RAM_o, 
  output reg wr_RAM_o, // 1 for write 

  output reg ramStall_IF_o // feed back to IF to let it stall 
); 

  assign wdata_RAM_o = wdata_MEM_i; 
  
  always @ (*) begin 
    if (rst == `Enable) begin 
      wdata_RAM_o <= `ZeroByte; 
      addr_RAM_o <= `ZeroWord; 
      wr_RAM_o <= `Disable; // read 
      ramStall_IF_o <= `Disable; // no stall 
    end else begin 
      if (re_MEM_i == `Enable) begin // MEM has higher priority
        addr_RAM_o <= raddr_MEM_i;
        wr_RAM_o <= `Disable; // read  
        ramStall_IF_o <= `Enable; // IF stalls 
      end else if (we_MEM_i == `Enable) begin 
        addr_RAM_o <= waddr_MEM_i; 
        wr_RAM_o <= `Disable; // write 
        ramStall_IF_o <= `Enable; // IF stalls 
      end else begin 
        addr_RAM_o <= addr_IF_i; 
        wr_RAM_o <= `Disable; // write 
        ramStall_IF_o <= `Disable; // no stall 
      end 
    end 
  end 
endmodule