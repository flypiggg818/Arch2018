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

  wire[`OpBus] opcode = inst_IFID_i[6:0]; 
  wire[4:0] rs1 = inst_IFID_i[19:15]; 
  wire[4:0] rs2 = inst_IFID_i[24:20]; 
  wire[4:0] rd = inst_IFID_i[11:7]; 
  wire[`Funct3Bus] funct3 = inst_IFID_i[14:12];
  wire[`Funct7Bus] funct7 = inst_IFID_i[31:25]; 
  reg[31:0] imm; 

    // 通过monitor来监视指令的各个部分
  initial begin 
    $monitor("inst: %b opcode: %b rs1: %b rs2: %b rd: %b", inst_IFID_i, opcode, rs1, rs2, rd); 
  end 

  always @ (*) begin 
    if (rst == `Enable) begin // no output, don't write back 
    	// reset all regs to avoid inferring latch. 
      aluop_IDEX_o <= `ALU_NOP_OP; 
      alusel_IDEX_o <= `ALU_NOP_SEL; 
      wreg_IDEX_o <= `Disable; 
    	re1_REGFILE_o <= `Disable; 
    	re2_REGFILE_o <= `Disable; 
    	raddr1_REGFILE_o <= `NopRegAddr; 	// avoid latch 
			raddr2_REGFILE_o <= `NopRegAddr; 	// avoid latch  
			imm <= `ZeroWord; 								// avoid latch  
			waddr_IDEX_o <= `NopRegAddr; 			// avoid latch  
    end else begin // set default decoding first, then switch to cases. 
      re1_REGFILE_o <= `Enable; 
      re2_REGFILE_o <= `Enable; 
      raddr1_REGFILE_o <= rs1; 
      raddr2_REGFILE_o <= rs2; 
      waddr_IDEX_o <= rd; 
      wreg_IDEX_o <= `Disable; // for safety issue 
      aluop_IDEX_o <= `ALU_NOP_OP; 
      alusel_IDEX_o <= `ALU_NOP_SEL; 
      case (opcode) 
        `LOGIC_IMM_OP: begin // rs1 arith with imm, store to dst
          wreg_IDEX_o <= `Enable; 
          re2_REGFILE_o <= `Disable; // replace rs2 with imm 
          imm <= {{20{inst_IFID_i[31]}}, inst_IFID_i[31:20]}; // immdiate with sign-extension
          case (funct3) 
            `ADDI_FNT3: begin 
              aluop_IDEX_o <= `ALU_ADD_OP; 
              alusel_IDEX_o <= `ALU_ARITH_SEL;
            end 
            default: begin end 
          endcase
        end 
        `LOAD_OP: begin // add imm(offset) upon to $(rs1)
          wreg_IDEX_o <= `Enable; 
          re2_REGFILE_o <= `Disable; 
          imm <= {{20{inst_IFID_i[31]}}, inst_IFID_i[31:20]}; // immdiate with sign-extension
          alusel_IDEX_o <= `ALU_ARITH_SEL; 
          case (funct3) // use aluop to distinguish different load data length
            `LB_FNT3: begin 
              aluop_IDEX_o <= `ALU_LB_OP; 
            end 
            `LH_FNT3: begin 
              aluop_IDEX_o <= `ALU_LH_OP; 
            end 
            `LW_FNT3: begin 
              aluop_IDEX_o <= `ALU_LW_OP; 
            end 
            `LBU_FNT3: begin 
              aluop_IDEX_o <= `ALU_LBU_OP; 
            end 
            `LHU_FNT3: begin 
              aluop_IDEX_o <= `ALU_LHU_OP; 
            end 
          default: begin end // dangerous 
          endcase 
        end 
        default: begin 
 					imm <= `ZeroWord; 		// avoid latch
				end
      endcase 
    end 
  end 

  // assign value for regdata controlled by above signals
  always @ (*) begin 
    if (rst == `Enable) begin 
      regdata1_IDEX_o <= `ZeroWord; 
    end else if (re1_REGFILE_o == `Enable) begin 
      regdata1_IDEX_o <= rdata1_REGFILE_i; 
    end else begin 
      regdata1_IDEX_o <= imm; 
    end 
  end 
  
  always @ (*) begin 
    if (rst == `Enable) begin 
      regdata2_IDEX_o <= `ZeroWord; 
    end else if (re2_REGFILE_o == `Enable) begin 
      regdata2_IDEX_o <= rdata2_REGFILE_i; 
    end else begin 
      regdata2_IDEX_o <= imm; 
    end 
  end 
endmodule 