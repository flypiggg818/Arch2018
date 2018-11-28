`include "macro.vh"

/**
  working circuits(combinational logic) issue 'stall requests' to STALLER, while STALLER provides 'stall service' to sequential 
  buffer circuits before that working 'request client'. 
*/
module STALLER(
  input wire rq_ID_i, // input request signals
  input wire rq_EX_i, 
  input wire rq_MEM_i, 

  output reg[1:0] stl_IF_o, // output stall signals
  output reg[1:0] stl_IFID_o, 
  output reg[1:0] stl_IDEX_o, 
  output reg[1:0] stl_EXMEM_o 
);

  always @ (*) begin 
    if (rq_MEM_i == `Enable) begin // This may have some problem
      stl_IF_o    <= `Stall;  
      stl_IFID_o  <= `Stall; 
      stl_IDEX_o  <= `Stall; 
      stl_EXMEM_o <= `Stall; 
    end else if (rq_EX_i == `Enable) begin 
      stl_IF_o    <= `Stall; 
      stl_IFID_o  <= `Stall; 
      stl_IDEX_o  <= `Stall; 
      stl_EXMEM_o <= `Bubble;   
    end else if (rq_ID_i == `Enable) begin 
      stl_IF_o    <= `Stall; 
      stl_IFID_o  <= `Stall; 
      stl_IDEX_o  <= `Bubble;   
      stl_EXMEM_o <= `Continue;   
    end else begin 
      stl_IF_o    <= `Continue; 
      stl_IFID_o  <= `Continue; 
      stl_IDEX_o  <= `Continue;   
      stl_EXMEM_o <= `Continue;   
    end 
  end 

endmodule 