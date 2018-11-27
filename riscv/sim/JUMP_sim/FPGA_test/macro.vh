`define Enable        1'b1
`define Disable       1'b0
`define ZeroWord      32'b0   // 默认的零信息
`define ZeroByte      8'b0 
`define NopRegAddr    5'b00000

`define Continue      2'b00
`define Stall         2'b01
`define Bubble        2'b10
`define REQ_STALL     2'b01   // request previous phases STALL, while current phase BUBBLE.
`define REQ_FLUSH     2'b10   // request FLUSH previous phases in JUMP instruction. 
`define REQ_NOP       2'b00

// 以下是自己定义的alu-op类型
`define AluOpBus                6:0
`define ALU_NOP_OP              7'b0000000
`define ALU_LUI_OP              7'b0000001
`define ALU_AND_OP              7'b0000010
`define ALU_OR_OP               7'b0000011
`define ALU_XOR_OP              7'b0000100
`define ALU_ADD_OP              7'b0000101
`define ALU_SUB_OP              7'b0000110
`define ALU_LSHIFT_OP           7'b0000111
`define ALU_RSHIFT_LOGIC_OP     7'b0001000
`define ALU_RSHIFT_ARITH_OP     7'b0001001
`define ALU_SLT_OP              7'b0001010
`define ALU_SLTU_OP             7'b0001011
`define ALU_LB_OP               7'b0001100 // LOAD and STORE instruction need extra OP other than ADD_OP for MEM control instead of naively for ALU operation
`define ALU_LH_OP               7'b0001101 // sign-extended
`define ALU_LW_OP               7'b0001110
`define ALU_LBU_OP              7'b0001111 // zero-extended
`define ALU_LHU_OP              7'b0010000
`define ALU_SB_OP               7'b0010001
`define ALU_SH_OP               7'b0010010
`define ALU_SW_OP               7'b0010011
`define ALU_JAL_OP              7'b0010100 
`define ALU_JALR_OP             7'b0010101 
`define ALU_BEQ_OP              7'b0010110 // use opcode for operation controlling 
`define ALU_BNE_OP              7'b0010111
`define ALU_BLT_OP              7'b0011000
`define ALU_BGE_OP              7'b0011001
`define ALU_BLTU_OP             7'b0011010
`define ALU_BGEU_OP             7'b0011011


// 以下是risc-v定义的alu-op类型
`define OpBus         6:0
`define NOP_OP        7'b0000000
`define LUI_OP        7'b0110111
`define AUIPC_OP      7'b0010111
`define LOGIC_IMM_OP  7'b0010011
`define LOGIC_REGS_OP 7'b0110011
`define LOAD_OP       7'b0000011
`define STORE_OP      7'b0100011
`define JAL_OP        7'b1101111
`define JALR_OP       7'b1100111
`define BRANCH_OP     7'b1100011

// 以下是funct3 code
`define Funct3Bus     2:0
`define ANDI_FNT3     3'b111
`define AND_FNT3      3'b111
`define XORI_FNT3     3'b100
`define XOR_FNT3      3'b100  
`define ORI_FNT3      3'b110
`define OR_FNT3       3'b110
`define ADDI_FNT3     3'b000
`define ADD_SUB_FNT3  3'b000
`define SLLI_FNT3     3'b001
`define SLL_FNT3      3'b001
`define SRLI_SRAI_FNT3 3'b101
`define SRL_SRA_FNT3  3'b101
`define SLTI_FNT3     3'b010
`define SLT_FNT3      3'b010
`define SLTIU_FNT3    3'b011
`define SLTU_FNT3     3'b011
`define LB_FNT3       3'b000 // funct3 to distinguish LOAD inst
`define LH_FNT3       3'b001
`define LW_FNT3       3'b010
`define LBU_FNT3      3'b100
`define LHU_FNT3      3'b101
`define SB_FNT3       3'b000 // funct3 to distinguish STORE inst
`define SH_FNT3       3'b001
`define SW_FNT3       3'b010
`define BEQ_FNT3      3'b000 // funct3 to distinguish BRANCH inst
`define BNE_FNT3      3'b001
`define BLT_FNT3      3'b100
`define BGE_FNT3      3'b101
`define BLTU_FNT3     3'b110
`define BGEU_FNT3     3'b111

// 以下是funct7 code
`define Funct7Bus     6:0
`define ADD_FNT7      7'b0000000
`define SUB_FNT7      7'b0100000
`define SRL_FNT7      7'b0000000
`define SRA_FNT7      7'b0100000
`define SRLI_FNT7     7'b0000000
`define SRAI_FNT7     7'b0100000

// 以下是自己定义的alu运算结果选择类型
`define AluSelBus     2:0
`define ALU_NOP_SEL     3'b000
`define ALU_LOGIC_SEL   3'b001
`define ALU_ARITH_SEL   3'b010
`define ALU_SHIFT_SEL   3'b011