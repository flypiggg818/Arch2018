`include "macro.vh"

module EX(
  input wire rst, 
  input wire[`AluOpBus] aluop_IDEX_i, 
  input wire[`AluSelBus] alusel_IDEX_i, 
  input wire[31:0] regdata1_IDEX_i, 
  input wire[31:0] regdata2_IDEX_i, 
  input wire wreg_IDEX_i, 
  input wire[4:0] waddr_IDEX_i,
  
  output reg wreg_EXMEM_o, // downstream signals
  output reg[4:0] waddr_EXMEM_o, 
  output reg[31:0] wdata_EXMEM_o
);

  reg[31:0] arith_rslt; 
	initial begin 
    $monitor("arith_rslt: %b reg1: %b reg2: %b rd: %b", arith_rslt, regdata1_IDEX_i, regdata2_IDEX_i, waddr_IDEX_i); 
  end 
  
  always @ (*) begin 
    case (aluop_IDEX_i)
      `ALU_ADD_OP: begin 
        arith_rslt <= regdata1_IDEX_i + regdata2_IDEX_i; 
      end 
      default: begin 
				arith_rslt <= `ZeroWord; // avoid latch  
      end 
    endcase 
  end 

  // assign results to output 
  always @ (*) begin 
    if (rst == `Enable) begin 
      wreg_EXMEM_o <= `Disable; 
      waddr_EXMEM_o <= `NopRegAddr; 
      wdata_EXMEM_o <= `ZeroWord; 
    end else begin 
      wreg_EXMEM_o <= wreg_IDEX_i; 
      waddr_EXMEM_o <= waddr_IDEX_i; 
      wdata_EXMEM_o <= `NopRegAddr; 	// avoid latch 
      case (alusel_IDEX_i) 
        `ALU_NOP_SEL: begin 
          wdata_EXMEM_o <= `ZeroWord; 
        end
        `ALU_ARITH_SEL: begin 
          wdata_EXMEM_o <= arith_rslt; 
        end 
        default: begin end 
      endcase 
    end
  end 
endmodule 