`include "macro.vh"

/**
  working circuits(combinational logic) issue 'stall requests' to STALLER, while STALLER provides 'stall service' to sequential 
  buffer circuits before that working 'request client'. 
*/
// note the STALL hierachy 
module STALLER(
  input wire rdy, 

  input wire[1:0] rq_ID_i, // input request signals
  input wire[1:0] rq_EX_i, 
  input wire[1:0] rq_MEM_i, 
  input wire[1:0] accessor_ARB_i, // current RAM accessor reported by ARBITRATOR

  output reg[1:0] stl_IF_o, // output stall signals
  output reg[1:0] stl_IFID_o, 
  output reg[1:0] stl_IDEX_o, 
  output reg[1:0] stl_EXMEM_o, 
  output reg[1:0] stl_MEM_o
);

	always @ (*) begin 
    if (rdy == `Disable) begin 
      stl_IF_o    = `IF_BACKALIGN;  
      stl_IFID_o  = `STALL;  
      stl_IDEX_o  = `STALL;  
      stl_EXMEM_o = `STALL;  
      stl_MEM_o   = `STALL; 
    end else if (accessor_ARB_i == `MEM_BLOCK_IF) begin // when memory access, stall everything except it. 
      stl_IF_o    = `IF_STALL;  
      stl_IFID_o  = `STALL;  
      stl_IDEX_o  = `STALL;  
      stl_EXMEM_o = `STALL;  
      stl_MEM_o   = `WORK; 
    end else if (accessor_ARB_i == `IF_BLOCK_MEM) begin // waiting for IF finish fetching one entire instruction. 
      stl_IF_o    = `WORK; // exclusive for IF instruction fetching, MEM is blocked. 
      stl_IFID_o  = `STALL; 
      stl_IDEX_o  = `STALL;  
      stl_EXMEM_o = `STALL; 
      stl_MEM_o   = `STALL; 
    end else if (rq_ID_i == `CONTROL_HAZARD) begin 
      stl_IF_o    = `WORK; // let branch / jump signal from ID handle this dirty work
      stl_IFID_o  = `BUBBLE;  
      stl_IDEX_o  = `WORK;  
      stl_EXMEM_o = `WORK; 
      stl_MEM_o   = `WORK;  
    end else if (rq_ID_i == `DATA_HAZARD) begin 
      stl_IF_o    = `WORK; 
      stl_IFID_o  = `BUBBLE; 
      stl_IDEX_o  = `WORK; 
      stl_EXMEM_o = `WORK; 
      stl_MEM_o   = `WORK; 
    end else begin 
      stl_IF_o    = `WORK; 
      stl_IFID_o  = `WORK; 
      stl_IDEX_o  = `WORK;   
      stl_EXMEM_o = `WORK; 
      stl_MEM_o   = `WORK;   
    end 
	end
endmodule 
