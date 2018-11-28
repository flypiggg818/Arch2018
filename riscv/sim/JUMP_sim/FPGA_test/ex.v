`include "macro.vh"

module EX(
  input wire rst, 
  input wire[`AluOpBus] aluop_IDEX_i, 
  input wire[`AluSelBus] alusel_IDEX_i, 
  input wire[31:0] regdata1_IDEX_i, 
  input wire[31:0] regdata2_IDEX_i, 
  input wire wreg_IDEX_i, 
  input wire[4:0] waddr_IDEX_i,
  input wire[31:0] SdataBoffset_IDEX_i, 
  input wire[31:0] pc_IDEX_i, 
  output reg[31:0] JBtaraddr_IF_o_fromEX, // feedback to IF 
  output reg JBje_IF_o, // jump enable 

  output reg[`AluOpBus] aluop_EXMEM_o, // downstream signals
  output reg wreg_EXMEM_o, 
  output reg[4:0] waddr_EXMEM_o, 
  output reg[31:0] alurslt_EXMEM_o, 
  output reg[31:0] SdataBoffset_EXMEM_o, 
  // stall request to STALLER 
  output reg[1:0] rq_STALLER_o
);
  reg[31:0] arith_rslt; 
	initial begin 
    $monitor("arith_rslt: %b reg1: %b reg2: %b rd: %b", arith_rslt, regdata1_IDEX_i, regdata2_IDEX_i, waddr_IDEX_i); 
  end 
  
  // arithmetic calculation 
  always @ (*) begin 
    case (aluop_IDEX_i)
      `ALU_ADD_OP: begin 
        arith_rslt = regdata1_IDEX_i + regdata2_IDEX_i; 
      end 
      `ALU_LB_OP, `ALU_LH_OP, `ALU_LW_OP, `ALU_LBU_OP, `ALU_LHU_OP, 
      `ALU_SB_OP, `ALU_SH_OP, `ALU_SW_OP: begin // for LOAD class of instruction's 'base + offset' 
        arith_rslt = regdata1_IDEX_i + regdata2_IDEX_i; 
      end 
      `ALU_JAL_OP: begin // $(pc+4) -> rd; modify pc 
        arith_rslt = pc_IDEX_i + 32'h4; 
        JBtaraddr_IF_o_fromEX = pc_IDEX_i + regdata1_IDEX_i; // increment pc with offset
      end 
      `ALU_JALR_OP: begin // $(pc+4) -> rd; replace pc
        arith_rslt = pc_IDEX_i + 32'h4; 
        JBtaraddr_IF_o_fromEX = regdata1_IDEX_i + regdata2_IDEX_i; 
      end 
      `ALU_BEQ_OP, `ALU_BNE_OP, `ALU_BLT_OP, 
      `ALU_BLTU_OP, `ALU_BGE_OP, `ALU_BGEU_OP: begin 
        JBtaraddr_IF_o_fromEX = pc_IDEX_i + SdataBoffset_IDEX_i;
      end 
      default: begin 
      end 
    endcase 
  end 

  // jump 
  wire jump_indicator = (aluop_IDEX_i == `ALU_JAL_OP    || // unconditional jump 
                         aluop_IDEX_i == `ALU_JALR_OP   || 
                         ((aluop_IDEX_i == `ALU_BEQ_OP)   && (regdata1_IDEX_i == regdata2_IDEX_i))                      || 
                         ((aluop_IDEX_i == `ALU_BNE_OP)   && (regdata1_IDEX_i != regdata2_IDEX_i))                      || 
                         ((aluop_IDEX_i == `ALU_BLT_OP)   && ($signed(regdata1_IDEX_i)   < $signed(regdata2_IDEX_i)))   || 
                         ((aluop_IDEX_i == `ALU_BLTU_OP)  && ($unsigned(regdata1_IDEX_i) < $unsigned(regdata2_IDEX_i))) || 
                         ((aluop_IDEX_i == `ALU_BGE_OP)   && ($signed(regdata1_IDEX_i)   > $signed(regdata2_IDEX_i)))   || 
                         ((aluop_IDEX_i == `ALU_BGEU_OP)  && ($unsigned(regdata1_IDEX_i) > $unsigned(regdata2_IDEX_i)))); 
  always @ (*) begin 
    if (jump_indicator == `Enable) begin 
      JBje_IF_o = `Enable; 
      rq_STALLER_o = `REQ_FLUSH; 
    end else begin 
      JBje_IF_o = `Disable; 
      rq_STALLER_o = `REQ_NOP; 
    end 
  end 

  // assign results to output 
  always @ (*) begin 
    if (rst == `Enable) begin 
      aluop_EXMEM_o = `ALU_NOP_OP; 
      wreg_EXMEM_o = `Disable; 
      waddr_EXMEM_o = `NopRegAddr; 
      alurslt_EXMEM_o = `ZeroWord; 
      SdataBoffset_EXMEM_o = `ZeroWord; 
    end else begin 
      aluop_EXMEM_o = aluop_IDEX_i; 
      wreg_EXMEM_o = wreg_IDEX_i; 
      waddr_EXMEM_o = waddr_IDEX_i; 
      SdataBoffset_EXMEM_o = SdataBoffset_IDEX_i; 
      alurslt_EXMEM_o = `NopRegAddr; 	// avoid latch 
      case (alusel_IDEX_i) 
        `ALU_NOP_SEL: begin 
          alurslt_EXMEM_o = `ZeroWord; 
        end
        `ALU_ARITH_SEL: begin 
          alurslt_EXMEM_o = arith_rslt; 
        end 
        default: begin end 
      endcase 
    end
  end 
endmodule 