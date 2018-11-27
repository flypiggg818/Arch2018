`include "macro.vh"

/**
  working circuits(combinational logic) issue 'stall requests' to STALLER, while STALLER provides 'stall service' to sequential 
  buffer circuits before that working 'request client'. 
*/
module STALLER(
  input wire rdy, 

  input wire[1:0] rq_ID_i, // input request signals
  input wire[1:0] rq_EX_i, 
  input wire[1:0] rq_MEM_i, 

  output reg[1:0] stl_IF_o, // output stall signals
  output reg[1:0] stl_IFID_o, 
  output reg[1:0] stl_IDEX_o, 
  output reg[1:0] stl_EXMEM_o 
);

  always @ (*) begin 
    if (rdy == `Disable || rq_MEM_i == `REQ_STALL) begin // This may have some problem
      stl_IF_o    = `Stall;  
      stl_IFID_o  = `Stall; 
      stl_IDEX_o  = `Stall; 
      stl_EXMEM_o = `Stall; 
    end else if (rq_EX_i == `REQ_STALL) begin 
      stl_IF_o    = `Stall; 
      stl_IFID_o  = `Stall; 
      stl_IDEX_o  = `Stall; 
      stl_EXMEM_o = `Bubble;   
    end else if (rq_ID_i == `REQ_STALL) begin 
      stl_IF_o    = `Stall; 
      stl_IFID_o  = `Stall; 
      stl_IDEX_o  = `Bubble;   
      stl_EXMEM_o = `Continue;   
    end else if (rq_EX_i == `REQ_FLUSH) begin // Note that IF continues but fetch new instruction at targeted address. 
      /** 
          Question may arise when we continue stl_IFID_o, because we suppose everything between instruction-fetching and EX 
          be flushed. When we BUBBLE IDEX, we are actually preventing the previous instruction going from IFID through ID to 
          IDEX. The second wrong instrucion hasn't been fetched yet. Because FLUSH signals are combinational, we can control 
          IF module at the beginning of dclk, thus fetching a correct second instruction, making IFID's work meaningful after 
          fetching a 'jumped, valid instruction'. 
      */
      stl_IF_o    = `Continue; 
      stl_IFID_o  = `Continue; 
      stl_IDEX_o  = `Bubble; 
      stl_EXMEM_o = `Continue;
    end else begin 
      stl_IF_o    = `Continue; 
      stl_IFID_o  = `Continue; 
      stl_IDEX_o  = `Continue;   
      stl_EXMEM_o = `Continue;   
    end 
  end 

endmodule 