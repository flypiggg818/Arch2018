`include "macro.vh"

/**
  Although this module should be a combinational logic, since it is 
  driven by high-frequency clock, I make it a sequential FSM. 
  Follow the same 'word fetching' procedure in IF module.
  I suddenly find that I need EIGHT!!! clock cycle. 
  I give up in damn cycles. 
*/

/**
  An elegant combinational between combinational logic and sequential circuit. 
*/
module MEM(
  input wire rst, 
  input wire clk, 

  input wire[`AluOpBus] aluop_EXMEM_i, 
  input wire wreg_EXMEM_i, 
  input wire[4:0] waddr_EXMEM_i, 
  input wire[31:0] alurslt_EXMEM_i, 
  input wire[31:0] SdataBoffset_EXMEM_i, // value stored in STORE inst, alurslt gives ram-address in this case. 
  input wire[1:0] stl_STALLER_i, 

  output wire re_RAM_o, // read enable 
  output reg[31:0] raddr_RAM_o, 
  input wire[7:0] rdata_RAM_i,
  output wire we_RAM_o,  // write enable
  output reg[31:0] waddr_RAM_o, 
  output reg[7:0] wdata_RAM_o, // assigned to cpu-ram port

  output wire wreg_MEMWB_o, 
  output wire[4:0] waddr_MEMWB_o, 
  output reg[31:0] wdata_MEMWB_o 
); 
  /*** FSM state ***/
  reg[4:0] FSM; 

  /*** signals related to ARBITRATOR ***/
  wire load = (aluop_EXMEM_i == `ALU_LB_OP)   || (aluop_EXMEM_i == `ALU_LH_OP)  || 
              (aluop_EXMEM_i == `ALU_LBU_OP)  || (aluop_EXMEM_i == `ALU_LHU_OP) || 
              (aluop_EXMEM_i == `ALU_LW_OP); 
  wire store = (aluop_EXMEM_i == `ALU_SB_OP)  || (aluop_EXMEM_i == `ALU_SH_OP) || 
               (aluop_EXMEM_i == `ALU_SW_OP); 
  wire MEM_ACS = load || store; 
  reg finish; // indicator for exiting MEM phase. 
  reg[31:0] load_buffer; // buffer for LOADED data placement 

  /*** STORE LOAD classification control signal ***/
  wire load_byte = (aluop_EXMEM_i == `ALU_LB_OP || aluop_EXMEM_i == `ALU_LBU_OP); 
  wire load_halfword = (aluop_EXMEM_i == `ALU_LH_OP || aluop_EXMEM_i == `ALU_LHU_OP); 
  wire signed_ext = (aluop_EXMEM_i == `ALU_LH_OP || aluop_EXMEM_i == `ALU_LB_OP); 
  wire unsigned_ext = (aluop_EXMEM_i == `ALU_LHU_OP || aluop_EXMEM_i == `ALU_LBU_OP); 

  assign re_RAM_o = !rst && load && !finish; 
  assign we_RAM_o = !rst && store && !finish; 

  /*** block for output signal assignment ***/
  assign wreg_MEMWB_o = (!rst && (!MEM_ACS || (MEM_ACS && finish))) ? wreg_EXMEM_i : `Disable; 
  assign waddr_MEMWB_o = (!rst && (!MEM_ACS || (MEM_ACS && finish))) ? waddr_EXMEM_i : `Disable; 
  
  always @ (*) begin 
    if (rst == `Enable || (MEM_ACS && !finish)) begin 
      wdata_MEMWB_o = `ZeroWord; 
    end else if (load && finish) begin 
      wdata_MEMWB_o = load_buffer; 
    end else if (store && finish) begin 
      wdata_MEMWB_o = `ZeroWord;
    end else begin 
      wdata_MEMWB_o = alurslt_EXMEM_i; 
    end 
  end 

  always @ (posedge clk or posedge rst) begin 
    if (rst == `Enable || stl_STALLER_i == `STALL) begin
      finish = `Disable; 
      FSM = 5'b00000; 
      load_buffer = `ZeroWord; 
      raddr_RAM_o = `NopRegAddr; 
      waddr_RAM_o = `NopRegAddr; 
      wdata_RAM_o = 8'b0; 
    end else begin
      case (FSM) 
        5'b00000: begin // have the right to do memory access. 
          /** Note that, when we have finished accessing memory, we will lift up finish signal. But 
              at the very next clock cycle, instruction remains unchanged because control signal needs one 
              extra clock cycle to reach, thus we should avoid do MEM access again. 
          */
          if (load == `Enable && !finish) begin 
            raddr_RAM_o = alurslt_EXMEM_i; 
            FSM = 5'b00001; 
          end else if (store == `Enable && !finish) begin 
            waddr_RAM_o = alurslt_EXMEM_i; 
            wdata_RAM_o = SdataBoffset_EXMEM_i[7:0];  
            FSM = 5'b10001; 
          end else begin 
            raddr_RAM_o = `ZeroWord; 
            waddr_RAM_o = `ZeroWord; 
            wdata_RAM_o = `ZeroWord; 
          end // if not store nor load, do nothing 
          finish = `Disable; 
          load_buffer = `ZeroWord; 
        end 
        5'b00001: begin // $(0) is being pushed onto bus 
          FSM = 5'b00010; 
        end 
        5'b00010: begin // $(1) is being pushed onto bus 
          load_buffer[7:0] = rdata_RAM_i; 
          if (load_byte == `Enable) begin 
            load_buffer[31:8] = (signed_ext == `Enable) ? {24{load_buffer[7]}} : 24'b0; 
            finish = `Enable; 
            FSM = 5'b00000; 
          end else begin 
            raddr_RAM_o = raddr_RAM_o + 32'b1; 
            FSM = 5'b00011; 
          end 
        end 
        5'b00011: begin 
          FSM = 5'b00100; 
        end 
        5'b00100: begin 
          load_buffer[15:8] = rdata_RAM_i; 
          if (load_halfword == `Enable) begin 
            load_buffer[31:16] = (signed_ext == `Enable) ? {16{load_buffer[15]}} : 16'b0; 
            finish = `Enable; 
            FSM = 5'b00000; 
          end else begin 
            raddr_RAM_o = raddr_RAM_o + 32'b1; 
            FSM = 5'b00101; 
          end 
        end 
        5'b00101: begin 
          FSM = 5'b00110; 
        end 
        5'b00110: begin 
          load_buffer[23:16] = rdata_RAM_i;
          raddr_RAM_o = raddr_RAM_o + 32'b1; 
          FSM = 5'b00111; 
        end   
        5'b00111: begin
          FSM = 5'b01000; 
        end 
        5'b01000: begin 
          load_buffer[31:24] = rdata_RAM_i;
          finish = `Enable; 
          raddr_RAM_o = `ZeroWord; 
          FSM = 5'b00000; 
        end 
        5'b10001: begin 
          if (aluop_EXMEM_i == `ALU_SB_OP) begin 
            finish = `Enable; 
            FSM = 5'b00000; 
          end else begin 
            waddr_RAM_o = waddr_RAM_o + 32'b1; 
            wdata_RAM_o = SdataBoffset_EXMEM_i[15:8]; 
            FSM = 5'b10010; 
          end 
        end 
        5'b10010: begin 
          if (aluop_EXMEM_i == `ALU_SH_OP) begin 
            finish = `Enable; 
            FSM = 5'b00000; 
          end else begin 
            waddr_RAM_o = waddr_RAM_o + 32'b1; 
            wdata_RAM_o = SdataBoffset_EXMEM_i[23:16]; 
            FSM = 5'b10011; 
          end
        end 
        5'b10011: begin 
          waddr_RAM_o = waddr_RAM_o + 32'b1; 
          wdata_RAM_o = SdataBoffset_EXMEM_i[31:24]; 
          FSM = 5'b10100; 
        end 
        5'b10100: begin 
          finish = `Enable; 
          waddr_RAM_o = `ZeroWord; 
          wdata_MEMWB_o = `ZeroWord; 
          FSM = 5'b00000; 
        end 
        default: begin 
        end 
      endcase 
    end
  end 
endmodule 