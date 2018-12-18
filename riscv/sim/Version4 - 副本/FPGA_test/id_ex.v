`include "macro.vh"

/**
  Everything about forwarding gathers here !
*/
module ID_EX(
  input wire rst, 
  input wire clk, 
  input wire[`AluOpBus] aluop_ID_i, 
  input wire[`AluSelBus] alusel_ID_i,
  input wire[31:0] regdata1_ID_i, 
  input wire[31:0] regdata2_ID_i, 
  input wire wreg_ID_i, 
  input wire[4:0] waddr_ID_i,
  input wire[31:0] SdataBoffset_ID_i, 
  input wire[1:0] stl_STALLER_i, 
  input wire[31:0] pc_ID_i, 

  output reg[`AluOpBus] aluop_EX_o, 
  output reg[`AluSelBus] alusel_EX_o,
  output reg[31:0] regdata1_EX_o, 
  output reg[31:0] regdata2_EX_o, 
  output reg wreg_EX_o, 
  output reg[4:0] waddr_EX_o, 
  output reg[31:0] SdataBoffset_EX_o, 
  output reg[31:0] pc_EX_o  
); 
  always @ (posedge clk, posedge rst) begin 
    if (rst == `Enable || stl_STALLER_i == `BUBBLE) begin 
      aluop_EX_o <= `ALU_NOP_OP;
      alusel_EX_o <= `ALU_NOP_SEL; 
      regdata1_EX_o <= `ZeroWord;
      regdata2_EX_o <= `ZeroWord;
      wreg_EX_o <= `Disable; 
      waddr_EX_o <= 5'b0; 
      SdataBoffset_EX_o <= `ZeroWord;
      pc_EX_o <= `ZeroWord;  
    end else if (stl_STALLER_i == `STALL) begin // hold by staller 
    end else begin
      aluop_EX_o <= aluop_ID_i;
      alusel_EX_o <= alusel_ID_i; 
      regdata1_EX_o <= regdata1_ID_i;
      regdata2_EX_o <= regdata2_ID_i;
      wreg_EX_o <= wreg_ID_i; 
      waddr_EX_o <= waddr_ID_i; 
      SdataBoffset_EX_o <= SdataBoffset_ID_i; 
      pc_EX_o <= pc_ID_i; 
    end 
  end 
endmodule 
