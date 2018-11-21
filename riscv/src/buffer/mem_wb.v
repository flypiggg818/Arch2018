`include "macro.vh"

module MEM_WB(
  input wire rst, 
  input wire dclk, 
  input wire wreg_MEM_i, 
  input wire[4:0] waddr_MEM_i, 
  input wire[31:0] wdata_MEM_i, 
  
  output reg wreg_REGFILE_o, 
  output reg[4:0] waddr_REGFILE_o, 
  output reg[31:0] wdata_REGFILE_o 
);
  always @ (posedge dclk, posedge rst) begin 
    if (rst == `Enable) begin 
      wreg_REGFILE_o <= `Disable; 
      waddr_REGFILE_o <= `NopRegAddr;
      wdata_REGFILE_o <= `ZeroWord; 
    end else begin 
      wreg_REGFILE_o <= wreg_MEM_i; 
      waddr_REGFILE_o <= waddr_MEM_i; 
      wdata_REGFILE_o <= wdata_MEM_i; 
    end 
  end 
endmodule 