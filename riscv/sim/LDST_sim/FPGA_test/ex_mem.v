`include "macro.vh"

module EX_MEM(
  input wire rst, 
  input wire dclk, 
  
  input wire[`AluOpBus] aluop_EX_i, 
  input wire wreg_EX_i, 
  input wire[4:0] waddr_EX_i, 
  input wire[31:0] alurslt_EX_i, 
  input wire[31:0] storedata_EX_i, 

  output reg[`AluOpBus] aluop_MEM_o, 
  output reg wreg_MEM_o, 
  output reg[4:0] waddr_MEM_o, 
  output reg[31:0] alurslt_MEM_o, 
  output reg[31:0] storedata_MEM_o
);
  always @ (posedge dclk, posedge rst) begin 
    if (rst == `Enable) begin 
      aluop_MEM_o <= `ALU_NOP_OP; 
      wreg_MEM_o <= `Disable; 
      waddr_MEM_o <= `NopRegAddr;
      alurslt_MEM_o <= `ZeroWord; 
      storedata_MEM_o <= `ZeroWord; 
    end else begin 
      aluop_MEM_o <= aluop_EX_i; 
      wreg_MEM_o <= wreg_EX_i; 
      waddr_MEM_o <= waddr_EX_i; 
      alurslt_MEM_o <= alurslt_EX_i; 
      storedata_MEM_o <= storedata_EX_i; 
    end 
  end   
endmodule 