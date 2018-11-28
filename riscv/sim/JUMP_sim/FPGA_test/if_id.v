`include "macro.vh"

// module port naming convention: name_dstModule_i/o. 

module IF_ID(
  input wire dclk, 
  input wire rst, 

  input wire[1:0] stl_STALLER_i, 
  input wire[31:0] inst_IF_i, 
  input wire[31:0] pc_IF_i, 
  output reg[31:0] inst_ID_o, 
  output reg[31:0] pc_ID_o  
); 
  always @ (posedge dclk or posedge rst) begin 
    if (rst == `Enable || stl_STALLER_i == `Bubble) begin 
      inst_ID_o <= `ZeroWord; 
      pc_ID_o <= `ZeroWord; 
    end else begin 
      if (stl_STALLER_i == `Stall) begin // hold by staller
      end else begin 
        inst_ID_o <= inst_IF_i; 
        pc_ID_o <= pc_IF_i;
      end 
    end 
  end 

endmodule
