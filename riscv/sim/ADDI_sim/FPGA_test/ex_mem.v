`include "macro.vh"

module EX_MEM(
  input wire rst, 
  input wire dclk, 
  input wire wreg_EX_i, 
  input wire[4:0] waddr_EX_i, 
  input wire[31:0] wdata_EX_i, 
  
  output reg wreg_MEM_o, 
  output reg[4:0] waddr_MEM_o, 
  output reg[31:0] wdata_MEM_o 
);
  always @ (posedge dclk, posedge rst) begin 
    if (rst == `Enable) begin 
      wreg_MEM_o <= `Disable; 
      waddr_MEM_o <= `NopRegAddr;
      wdata_MEM_o <= `ZeroWord; 
    end else begin 
      wreg_MEM_o <= wreg_EX_i; 
      waddr_MEM_o <= waddr_EX_i; 
      wdata_MEM_o <= wdata_EX_i; 
    end 
  end   
endmodule 