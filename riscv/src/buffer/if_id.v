`include "macro.vh"

// module port naming convention: name_dstModule_i/o. 

module IF_ID(
  input wire dclk, 
  input wire rst, 
  input wire rdy, 

  input wire[31:0] inst_IF_i, 
  output reg[31:0] inst_ID_o 
); 

  always @ (posedge dclk or posedge rst) begin 
    if (rst == `Enable) begin 
      inst_ID_o <= `ZeroWord; 
    end else begin 
      if(rdy == `Disable) begin 
        // hold inst value in buffer. 
      end else begin 
        inst_ID_o <= inst_IF_i; 
      end 
    end 
  end 

endmodule
