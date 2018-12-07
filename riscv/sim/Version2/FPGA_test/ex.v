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

  output reg[`AluOpBus] aluop_EXMEM_o, // downstream signals
  output reg wreg_EXMEM_o, 
  output reg[4:0] waddr_EXMEM_o, 
  output reg[31:0] alurslt_EXMEM_o, 
  output reg[31:0] SdataBoffset_EXMEM_o, 
  // stall request to STALLER 
  output reg[1:0] rq_STALLER_o
);
  reg[31:0] arith_rslt; 
  reg[31:0] logic_rslt; 
  reg[31:0] shift_rslt; 
	initial begin 
    // $monitor("arith_rslt: %b reg1: %b reg2: %b rd: %b", arith_rslt, regdata1_IDEX_i, regdata2_IDEX_i, waddr_IDEX_i); 
  end 
  
  // arithmetic calculation 
  always @ (*) begin 
    case (aluop_IDEX_i)
      `ALU_LUI_OP: begin 
        logic_rslt = regdata1_IDEX_i; 
      end 
      `ALU_AND_OP: begin 
        logic_rslt = regdata1_IDEX_i & regdata2_IDEX_i; 
      end 
      `ALU_OR_OP: begin
        logic_rslt = regdata1_IDEX_i | regdata2_IDEX_i; 
      end 
      `ALU_XOR_OP: begin 
        logic_rslt = regdata1_IDEX_i ^ regdata2_IDEX_i; 
      end 
      `ALU_ADD_OP: begin 
        arith_rslt = regdata1_IDEX_i + regdata2_IDEX_i; 
      end 
      `ALU_AUIPC_OP: begin 
        arith_rslt = regdata1_IDEX_i + pc_IDEX_i; 
      end 
      `ALU_SUB_OP: begin 
        arith_rslt = regdata1_IDEX_i - regdata2_IDEX_i;
      end 
      `ALU_LSHIFT_OP: begin 
        shift_rslt = regdata1_IDEX_i << regdata2_IDEX_i[4:0]; 
      end 
      `ALU_RSHIFT_LOGIC_OP: begin 
        shift_rslt = regdata1_IDEX_i >> regdata2_IDEX_i[4:0]; 
      end 
      `ALU_RSHIFT_ARITH_OP: begin 
        shift_rslt = ($signed(regdata1_IDEX_i)) >>> regdata2_IDEX_i[4:0]; 
      end 
      `ALU_SLT_OP: begin 
        if ($signed(regdata1_IDEX_i) < $signed(regdata2_IDEX_i)) begin 
          logic_rslt = 32'b1; 
        end else begin 
          logic_rslt = 32'b0; 
        end 
      end 
      `ALU_SLTU_OP: begin 
        if (regdata1_IDEX_i < regdata2_IDEX_i) begin 
          logic_rslt = 32'b1; 
        end else begin 
          logic_rslt = 32'b0; 
        end 
      end 
      `ALU_LB_OP, `ALU_LH_OP, `ALU_LW_OP, `ALU_LBU_OP, `ALU_LHU_OP, 
      `ALU_SB_OP, `ALU_SH_OP, `ALU_SW_OP: begin // for LOAD class of instruction's 'base + offset' 
        arith_rslt = regdata1_IDEX_i + regdata2_IDEX_i; 
      end 
      `ALU_JAL_OP: begin // $(pc+4) -> rd; modify pc 
        arith_rslt = pc_IDEX_i + 32'h4; 
      end 
      `ALU_JALR_OP: begin // $(pc+4) -> rd; replace pc
        arith_rslt = pc_IDEX_i + 32'h4; 
      end 
      `ALU_BEQ_OP, `ALU_BNE_OP, `ALU_BLT_OP, 
      `ALU_BLTU_OP, `ALU_BGE_OP, `ALU_BGEU_OP, 
      `ALU_NOP_OP: begin // do nothing 
      end 
      default: begin 
      end 
    endcase 
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
        `ALU_LOGIC_SEL: begin 
          alurslt_EXMEM_o = logic_rslt; 
        end 
        `ALU_SHIFT_SEL: begin 
          alurslt_EXMEM_o = shift_rslt; 
        end 
        default: begin end 
      endcase 
    end
  end 
endmodule 