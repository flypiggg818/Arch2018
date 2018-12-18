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
  Note that READ/WRITE detection has to be combinational. 
*/
module MEM(
	input wire rst, 
	input wire clk, 
	
	// consider rdy signal... 
	input wire[1:0] stl_CTRL_i,
	
	input wire[`AluOpBus] aluop_EXMEM_i, 
	input wire wreg_EXMEM_i, 
	input wire[4:0] waddr_EXMEM_i, 
	input wire[31:0] alurslt_EXMEM_i, 
	input wire[31:0] SdataBoffset_EXMEM_i, // value stored in STORE inst, alurslt gives ram-address in this case. 
	
  output wire re_CTRL_o, 
	output reg[31:0] addr_CTRL_o, 
	input wire[7:0] rdata_RAM_i,
  output wire we_CTRL_o, 
	output reg[7:0] wdata_CTRL_o, 
	
	output wire wreg_MEMWB_o, 
	output wire[4:0] waddr_MEMWB_o, 
	output reg[31:0] wdata_MEMWB_o 
); 
	
  /*** load store indicators ***/
  wire load = (aluop_EXMEM_i == `ALU_LB_OP)   || (aluop_EXMEM_i == `ALU_LH_OP)  || 
              (aluop_EXMEM_i == `ALU_LBU_OP)  || (aluop_EXMEM_i == `ALU_LHU_OP) || 
              (aluop_EXMEM_i == `ALU_LW_OP); 
  wire store = (aluop_EXMEM_i == `ALU_SB_OP)  || (aluop_EXMEM_i == `ALU_SH_OP) || 
               (aluop_EXMEM_i == `ALU_SW_OP); 
  wire MEM_ACS = load || store; 
  
  /** all signals have to be passed simultaenously */
  reg finish; // indicator for exiting MEM phase. 


  /** assign downstream data passing */
  /*** block for output signal assignment ***/
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
  assign wreg_MEMWB_o = (!rst && (!MEM_ACS || (MEM_ACS && finish))) ? wreg_EXMEM_i : `Disable; 
  assign waddr_MEMWB_o = (!rst && (!MEM_ACS || (MEM_ACS && finish))) ? waddr_EXMEM_i : `Disable; 
  
  /** assign read and write enable to CTRL*/
  assign re_CTRL_o = (load && !finish); 
  assign we_CTRL_o = (store && !finish); 
  reg[31:0] load_buffer; // buffer for LOADED data placement 

  /** assign address and data logically */
  reg[1:0] btsel_flag; // use this flag to select byte 
  always @ (*) begin 
    if (!finish && MEM_ACS) begin 
      case (btsel_flag)
        2'h0: begin 
          addr_CTRL_o = alurslt_EXMEM_i; 
          wdata_CTRL_o = SdataBoffset_EXMEM_i[7:0];  
        end 
        2'h1: begin 
          addr_CTRL_o = alurslt_EXMEM_i + 32'h1; 
          wdata_CTRL_o = SdataBoffset_EXMEM_i[15:8];  
        end 
        2'h2: begin 
          addr_CTRL_o = alurslt_EXMEM_i + 32'h2; 
          wdata_CTRL_o = SdataBoffset_EXMEM_i[23:16];  
        end 
        2'h3: begin 
          addr_CTRL_o = alurslt_EXMEM_i + 32'h3; 
          wdata_CTRL_o = SdataBoffset_EXMEM_i[31:24];  
        end 
        default: begin 
          addr_CTRL_o = `ZeroWord; 
          wdata_CTRL_o = 8'b0; 
        end 
      endcase 
    end else begin 
      addr_CTRL_o = `ZeroWord; 
      wdata_CTRL_o = 8'b0; 
    end 
  end 

  /*** STORE LOAD classification control signal ***/
  wire load_byte = (aluop_EXMEM_i == `ALU_LB_OP || aluop_EXMEM_i == `ALU_LBU_OP); 
  wire load_halfword = (aluop_EXMEM_i == `ALU_LH_OP || aluop_EXMEM_i == `ALU_LHU_OP); 
  wire signed_ext = (aluop_EXMEM_i == `ALU_LH_OP || aluop_EXMEM_i == `ALU_LB_OP); 
  wire unsigned_ext = (aluop_EXMEM_i == `ALU_LHU_OP || aluop_EXMEM_i == `ALU_LBU_OP); 

  /*** FSM state ***/
  reg[4:0] FSM; 
  always @ (posedge clk or posedge rst) begin 
    if (rst == `Enable) begin
      finish = `Disable; 
      FSM = 5'b00000; 
      load_buffer = `ZeroWord; 
      btsel_flag = 2'h0; 
    end else if (stl_CTRL_i == `STALL) begin 
    end else begin // if control is busy, we wait forever. 
      case (FSM) 
        5'b00000: begin // have the right to do memory access. 
          /** Note that, when we have finished accessing memory, we will lift up finish signal. But 
              at the very next clock cycle, instruction remains unchanged because control signal needs one 
              extra clock cycle to reach, thus we should avoid do MEM access again. 
          */
          if (load == `Enable && !finish) begin 
            // addr_CTRL_o = alurslt_EXMEM_i; 
            FSM = 5'b00001; // start reading 
          end else if (store == `Enable && !finish) begin 
            // addr_CTRL_o = alurslt_EXMEM_i; 
            // wdata_CTRL_o = SdataBoffset_EXMEM_i[7:0];  
            FSM = 5'b10001; 
          end else begin // if not store nor load, do nothing 
            // addr_CTRL_o = `ZeroWord; 
            // wdata_CTRL_o = 8'b0; 
          end 
          finish = `Disable; 
          load_buffer = `ZeroWord; 
          btsel_flag = 2'h0; 
        end 
        5'b00001: begin // $(0) is being pushed onto bus 
          FSM = 5'b00010; 
        end 
        5'b00010: begin // $(1) is being pushed onto bus 
          load_buffer[7:0] = rdata_RAM_i; 
          if (load_byte == `Enable) begin 
            load_buffer[31:8] = (signed_ext == `Enable) ? {24{load_buffer[7]}} : 24'b0; 
            finish = `Enable; 
            btsel_flag = 2'h0; 
            FSM = 5'b00000; 
          end else begin 
            btsel_flag = 2'h1; 
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
            btsel_flag = 2'h0; 
            FSM = 5'b00000; 
          end else begin 
            btsel_flag = 2'h2; 
            FSM = 5'b00101; 
          end 
        end 
        5'b00101: begin 
          FSM = 5'b00110; 
        end 
        5'b00110: begin 
          load_buffer[23:16] = rdata_RAM_i;
          btsel_flag = 2'h3; 
          FSM = 5'b00111; 
        end   
        5'b00111: begin
          FSM = 5'b01000; 
        end 
        5'b01000: begin 
          load_buffer[31:24] = rdata_RAM_i;
          finish = `Enable; 
          btsel_flag = 2'h0; 
          FSM = 5'b00000; 
        end 
        5'b10001: begin 
          if (aluop_EXMEM_i == `ALU_SB_OP) begin 
            finish = `Enable;
            btsel_flag = 2'h0; 
            FSM = 5'b00000; 
          end else begin 
            btsel_flag = 2'h1; 
            FSM = 5'b10010; 
          end 
        end 
        5'b10010: begin 
          if (aluop_EXMEM_i == `ALU_SH_OP) begin 
            finish = `Enable; 
            btsel_flag = 2'h0; 
            FSM = 5'b00000; 
          end else begin 
            btsel_flag = 2'h2; 
            FSM = 5'b10011; 
          end
        end 
        5'b10011: begin 
          btsel_flag = 2'h3; 
          FSM = 5'b10100; 
        end 
        5'b10100: begin 
          finish = `Enable; 
          btsel_flag = 2'h0; 
          FSM = 5'b00000; 
        end 
        default: begin 
        end 
      endcase 
    end
  end 
endmodule 