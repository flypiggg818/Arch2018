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

  // forwarding from EX and MEM
  input wire fwreg_EX_i,
  input wire[4:0] fwaddr_EX_i, 
  input wire[31:0] fwdata_EX_i, 
  input wire fwreg_MEM_i,
  input wire[4:0] fwaddr_MEM_i, 
  input wire[31:0] fwdata_MEM_i, 
  input wire[`AluOpBus] faluop_EX_i, // memory-access data hazard, no extra port in EX is needed. 

  // pc signal passed from IF phase
  input wire[31:0] pc_IFID_i, 
  // jump target address back to IF
  output reg[31:0] JBtaraddr_IF_o_fromID, 
  // data flow down
  output reg[`AluOpBus] aluop_IDEX_o, // ALU operation code defined by myself 
  output reg[`AluSelBus] alusel_IDEX_o, // ALU operation result type defined by myself 
  output reg[31:0] regdata1_IDEX_o, // register data value 
  output reg[31:0] regdata2_IDEX_o, 
  output reg wreg_IDEX_o, // whether to write back 
  output reg[4:0] waddr_IDEX_o, // write back destination addr 
  output reg[31:0] SdataBoffset_IDEX_o, // used only by STORE inst
  // stall request to STALLER 
  output reg[1:0] rq_STALLER_o, 
  output reg[31:0] pc_IDEX_o 
); 

  wire[`OpBus] opcode = inst_IFID_i[6:0]; 
  wire[4:0] rs1 = inst_IFID_i[19:15]; 
  wire[4:0] rs2 = inst_IFID_i[24:20]; 
  wire[4:0] rd = inst_IFID_i[11:7]; 
  wire[`Funct3Bus] funct3 = inst_IFID_i[14:12];
  wire[`Funct7Bus] funct7 = inst_IFID_i[31:25]; 
  // immediate for different types of inst
  wire[31:0] I_imm = {{20{inst_IFID_i[31]}}, inst_IFID_i[31:20]};
  wire[31:0] S_imm = {{20{inst_IFID_i[31]}}, inst_IFID_i[31:25], inst_IFID_i[11:7]};
  wire[31:0] B_imm = {{20{inst_IFID_i[31]}}, inst_IFID_i[7], inst_IFID_i[30:25], inst_IFID_i[11:8], 1'b0};
  wire[31:0] U_imm = {inst_IFID_i[31:12], {12{inst_IFID_i[31]}}};
  wire[31:0] J_imm = {{12{inst_IFID_i[31]}}, inst_IFID_i[19:12], inst_IFID_i[20], inst_IFID_i[30:21], 1'b0};
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
      JBtaraddr_IF_o_fromID <= `ZeroWord;
      pc_IDEX_o <= `ZeroWord;  
    end else begin // set default decoding first, then switch to cases. 
      re1_REGFILE_o <= `Enable; 
      re2_REGFILE_o <= `Enable; 
      raddr1_REGFILE_o <= rs1; 
      raddr2_REGFILE_o <= rs2; 
      waddr_IDEX_o <= rd; 
      wreg_IDEX_o <= `Disable; // for safety issue 
      aluop_IDEX_o <= `ALU_NOP_OP; 
      alusel_IDEX_o <= `ALU_NOP_SEL; 
      JBtaraddr_IF_o_fromID <= `ZeroWord; 
      pc_IDEX_o <= pc_IFID_i;  
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
        `STORE_OP: begin // fetch rs1 and rs2, operate in below always block; SdataBoffset in rs2, base in rs1. 
          wreg_IDEX_o <= `Disable; 
          imm <= {{20{inst_IFID_i[31]}}, inst_IFID_i[31:25], inst_IFID_i[11:7]}; // sign-extended offset 
          alusel_IDEX_o <= `ALU_ARITH_SEL; 
          case (funct3) // use aluop to distinguish different load data length
            `SB_FNT3: begin 
              aluop_IDEX_o <= `ALU_SB_OP; 
            end 
            `SH_FNT3: begin 
              aluop_IDEX_o <= `ALU_SH_OP; 
            end 
            `SW_FNT3: begin 
              aluop_IDEX_o <= `ALU_SW_OP; 
            end 
            default: begin end // dangerous 
          endcase 
        end 
        `JAL_OP: begin // add offset(imm) to pc
          aluop_IDEX_o <= `ALU_JAL_OP; 
          wreg_IDEX_o <= `Enable; 
          alusel_IDEX_o <= `ALU_ARITH_SEL; 
          imm <= {{12{inst_IFID_i[31]}}, inst_IFID_i[19:12], inst_IFID_i[20], inst_IFID_i[30:21], 1'b0}; // put offset into immediate 
          re1_REGFILE_o <= `Disable; 
          re2_REGFILE_o <= `Disable;        
        end 
        `JALR_OP: begin // add $(rs1) by offset, replace pc. 
          aluop_IDEX_o <= `ALU_JALR_OP; 
          wreg_IDEX_o <= `Enable; 
          alusel_IDEX_o <= `ALU_ARITH_SEL; 
          imm <= I_imm; 
          re2_REGFILE_o <= `Disable; 
        end 
        `BRANCH_OP: begin
          alusel_IDEX_o <= `ALU_NOP_SEL; 
          // wreg_IDEX_o <= `Disable; 
          imm <= B_imm; 
          case (funct3) 
            `BEQ_FNT3: begin 
              aluop_IDEX_o <= `ALU_BEQ_OP; 
            end 
            `BNE_FNT3: begin 
              aluop_IDEX_o <= `ALU_BNE_OP; 
            end 
            `BLT_FNT3: begin 
              aluop_IDEX_o <= `ALU_BLT_OP; 
            end 
            `BGE_FNT3: begin 
              aluop_IDEX_o <= `ALU_BGE_OP; 
            end 
            `BLTU_FNT3: begin 
              aluop_IDEX_o <= `ALU_BLTU_OP; 
            end 
            `BGEU_FNT3: begin 
              aluop_IDEX_o <= `ALU_BGEU_OP; 
            end 
            default: begin // shitty case
            end 
          endcase
        end 
        default: begin 
 					imm <= `ZeroWord; 		// avoid latch
				end
      endcase 
    end 
  end 

  wire pre_inst_is_load; 
  assign pre_inst_is_load = (faluop_EX_i == `ALU_LB_OP || 
                             faluop_EX_i == `ALU_LH_OP || 
                             faluop_EX_i == `ALU_LW_OP || 
                             faluop_EX_i == `ALU_LBU_OP || 
                             faluop_EX_i == `ALU_LHU_OP); 
  // deal with forwarding separately 
  reg[31:0] regdata1_fwrded; 
  reg[31:0] regdata2_fwrded; 
  always @ (*) begin // fetch reg1's forwarded data 
  	if (re1_REGFILE_o == `Enable) begin 
			if (fwreg_EX_i == `Enable && raddr1_REGFILE_o == fwaddr_EX_i) begin // 1-pre hazard
				regdata1_fwrded <= fwdata_EX_i; 
			end else if (fwreg_MEM_i == `Enable && raddr1_REGFILE_o == fwaddr_MEM_i) begin // 2-pre hazard
				regdata1_fwrded <= fwdata_MEM_i; 
			end else begin // no hazard
				regdata1_fwrded <= rdata1_REGFILE_i;
			end 
		end else begin end 
  end 
  always @ (*) begin // reg2's forwarded data 
		if (re2_REGFILE_o == `Enable) begin 
			if (fwreg_EX_i == `Enable && raddr2_REGFILE_o == fwaddr_EX_i) begin // 1-pre hazard
				regdata2_fwrded <= fwdata_EX_i; 
			end else if (fwreg_MEM_i == `Enable && raddr2_REGFILE_o == fwaddr_MEM_i) begin // 2-pre hazard
				regdata2_fwrded <= fwdata_MEM_i; 
			end else begin // no hazard
				regdata2_fwrded <= rdata2_REGFILE_i;
			end 
		end else begin end 
  end 

  // reg1data_output. LOAD can cause pipeline stall, and STORE_INST is dealt separately. 
  // the STALL signal is handled ugly
  always @ (*) begin 
    if (rst == `Enable) begin // reset
      regdata1_IDEX_o <= `ZeroWord; 
    end else if (re1_REGFILE_o == `Enable) begin // read enable
      if (opcode == `STORE_OP) begin 
        regdata1_IDEX_o <= regdata1_fwrded;
        SdataBoffset_IDEX_o <= regdata2_fwrded;  
      end else if (opcode == `BRANCH_OP) begin
        SdataBoffset_IDEX_o <= imm; 
      end else begin  
        regdata1_IDEX_o <= regdata1_fwrded;
      end 
    end else begin // read disable
      regdata1_IDEX_o <= imm; 
    end 
  end 
  // reg2data_output 
  always @ (*) begin 
    if (rst == `Enable) begin // reset
      regdata2_IDEX_o <= `ZeroWord; 
    end else if (re2_REGFILE_o == `Enable) begin // read enable
      if (opcode == `STORE_OP) begin 
        regdata2_IDEX_o <= imm; 
      end else begin 
        regdata2_IDEX_o <= regdata2_fwrded;
      end 
    end else begin // read disable
      regdata2_IDEX_o <= imm; 
    end 
  end 

  // detect MEM hazard 
  always @ (*) begin 
    if (pre_inst_is_load == `Enable && (raddr1_REGFILE_o == fwaddr_EX_i || raddr2_REGFILE_o == fwaddr_EX_i)) begin 
      rq_STALLER_o <= `REQ_STALL; 
    end else begin 
      rq_STALLER_o <= `REQ_NOP; 
    end 
  end 
endmodule 
