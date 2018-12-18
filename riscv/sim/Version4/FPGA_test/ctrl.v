`include "macro.vh"

/** ram access policy: atomic */
module CTRL(
  input wire rst, 

  // ram control 
  input wire re_CACHE_i, 
  input wire[31:0] addr_CACHE_i, 

  input wire re_MEM_i, 
	input wire[31:0] addr_MEM_i,
  input wire we_MEM_i, 
	input wire[7:0] wdata_MEM_i,

  output reg wr_RAM_o, // 1 for write 
  output reg[31:0] addr_RAM_o, 
  output reg[7:0] wdata_RAM_o, 

  // stalller 
  input wire rdy, 

  input wire[1:0] rq_ID_i, // input request signals
  input wire[1:0] rq_MEM_i, 

  output reg[1:0] stl_IF_o, // output stall signals
  output reg[1:0] stl_IFID_o, 
  output reg[1:0] stl_IDEX_o, 
  output reg[1:0] stl_EXMEM_o, 
  output reg[1:0] stl_MEM_o, 
  output reg[1:0] stl_CACHE_o
);

  localparam NOP_ACS = 2'h0; 
  localparam CACHE_ACS = 2'h1; 
  localparam MEM_ACS = 2'h2; 
  reg[1:0] accessor; 
  
  localparam NOP_HAZARD = 2'h0; 
  localparam CACHE_BLOCK_MEM = 2'h1; 
  localparam MEM_BLOCK_CACHE = 2'h2; 
  reg[1:0] ramctrl_hazard; 

  wire compete = re_CACHE_i && (re_MEM_i || we_MEM_i); // indicate whether two components are competing each other. 

  /** ram_ctrl always block */
  always @ (*) begin 
    if (rst == `Enable) begin 
      accessor = NOP_ACS; 
      ramctrl_hazard = NOP_HAZARD; 
    end else if (!compete) begin // if not competing, just assign accessors. assign data and address and enable 
      ramctrl_hazard = NOP_HAZARD; // no hazard when no competing
      if (we_MEM_i) begin 
        wr_RAM_o = 1'b1; 
        addr_RAM_o = addr_MEM_i; 
        wdata_RAM_o = wdata_MEM_i; 
        accessor = MEM_ACS; 
      end else if (re_MEM_i) begin 
        wr_RAM_o = 1'b0; 
        addr_RAM_o = addr_MEM_i; 
        wdata_RAM_o = 8'b0; 
        accessor = MEM_ACS; 
      end else if (re_CACHE_i) begin 
        wr_RAM_o = 1'b0; 
        addr_RAM_o = addr_CACHE_i; 
        wdata_RAM_o = 8'b0; 
        accessor = CACHE_ACS; 
      end else begin 
        wr_RAM_o = 1'b0; 
        addr_RAM_o = 32'b0; 
        wdata_RAM_o = 8'b0; 
        accessor = NOP_ACS; 
      end 
    end else begin // they are competing! god! 
      if (accessor == NOP_ACS) begin // assign accessor, and it will go around back here. 
        accessor = MEM_ACS; 
      end else if (accessor == MEM_ACS) begin 
        ramctrl_hazard = MEM_BLOCK_CACHE; 
        if (re_MEM_i) begin 
          wr_RAM_o = 1'b0; 
          addr_RAM_o = addr_MEM_i; 
          wdata_RAM_o = 8'b0; 
        end else begin // we_MEM_i
          wr_RAM_o = 1'b1; 
          addr_RAM_o = addr_MEM_i; 
          wdata_RAM_o = wdata_MEM_i; 
        end 
      end else begin // CACHE_ACS
        ramctrl_hazard = CACHE_BLOCK_MEM; 
        wr_RAM_o = 1'b0; 
        addr_RAM_o = addr_CACHE_i; 
        wdata_RAM_o = 8'b0; 
      end 
    end 
  end 

  /** staller always block */
  always @ (*) begin 
    if (rdy == `Disable) begin 
      stl_IF_o    = `STALL; 
      stl_CACHE_o = `STALL; 
      stl_IFID_o  = `STALL;  
      stl_IDEX_o  = `STALL;  
      stl_EXMEM_o = `STALL;  
      stl_MEM_o   = `STALL; 
    end else if (accessor == MEM_ACS || ramctrl_hazard == MEM_BLOCK_CACHE) begin 
      stl_IF_o    = `STALL; 
      stl_CACHE_o = `STALL; 
      stl_IFID_o  = `STALL; 
      stl_IDEX_o  = `STALL;   
      stl_EXMEM_o = `STALL; 
      stl_MEM_o   = `WORK;  
    end else if (ramctrl_hazard == CACHE_BLOCK_MEM) begin 
      stl_IF_o    = `STALL; 
      stl_CACHE_o = `WORK; 
      stl_IFID_o  = `STALL; 
      stl_IDEX_o  = `STALL;   
      stl_EXMEM_o = `STALL; 
      stl_MEM_o   = `STALL;  
    end else if (rq_ID_i == `CONTROL_HAZARD) begin 
      stl_IF_o    = `WORK; // let branch / jump signal from ID handle this dirty work
      stl_CACHE_o = `WORK; 
      stl_IFID_o  = `BUBBLE;  
      stl_IDEX_o  = `WORK;  
      stl_EXMEM_o = `WORK; 
      stl_MEM_o   = `WORK;  
    end else if (rq_ID_i == `DATA_HAZARD) begin 
      stl_IF_o    = `STALL; 
      stl_CACHE_o = `WORK; 
      stl_IFID_o  = `STALL; 
      stl_IDEX_o  = `BUBBLE; 
      stl_EXMEM_o = `WORK; 
      stl_MEM_o   = `WORK; 
    end else begin 
      stl_IF_o    = `WORK; 
      stl_CACHE_o = `WORK; 
      stl_IFID_o  = `WORK;  
      stl_IDEX_o  = `WORK;   
      stl_EXMEM_o = `WORK; 
      stl_MEM_o   = `WORK;   
    end 
  end

endmodule 