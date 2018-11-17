`include "macro.vh"

module MEM(
  input wire rst, 
  input wire wreg_EXMEM_i, 
  input wire[4:0] waddr_EXMEM_i, 
  input wire[31:0] wdata_EXMEM_i, 

  output reg wreg_MEMWB_o, 
  output reg[4:0] waddr_MEMWB_o, 
  output reg[31:0] wdata_MEMWB_o
); 
  always @ (*) begin 
    if (rst == `Enable) begin 
      wreg_MEMWB_o <= `Disable; 
      waddr_MEMWB_o <= `NopRegAddr;
      wdata_MEMWB_o <= `ZeroWord; 
    end else begin 
      wreg_MEMWB_o <= wreg_EXMEM_i; 
      waddr_MEMWB_o <= waddr_EXMEM_i; 
      wdata_MEMWB_o <= wdata_EXMEM_i; 
    end 
  end 
endmodule 