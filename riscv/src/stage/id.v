`include "macro.vh"

module ID(
  input wire rst, 
  input wire[31:0] inst_IFID_i, 
  
  // decode from registerfile 
  output reg re1_REGFILE_o, 
  output reg[4:0] raddr1_REGFILE_o,
  input wire[31:0] rdata1_REGFILE_i, 

  output reg re2_REGFILE_o, 
  output reg[4:0] raddr2_REGFILE_o,
  input wire[31:0] rdata2_REGFILE_i, 

  // data flow down
  output reg[`AluOpBus] aluop_IDEX_o, // ALU operation code defined by myself 
  output reg[`AluSelBus] alusel_IDEX_o, // ALU operation result type defined by myself 
  output reg[31:0] regdata1_IDEX_o, // register data value 
  output reg[31:0] regdata2_IDEX_o, 
  output reg wreg_IDEX_o, // whether to write back 
  output reg[4:0] waddr_IDEX_o // write back destination addr 
); 

  
endmodule 