`include "macro.vh"

// back up file
/**
  Although this module should be a combinational logic, since it is 
  driven by high-frequency clock, I make it a sequential FSM. 
  Follow the same 'word fetching' procedure in IF module.
  I suddenly find that I need six clock cycle. 
*/
module MEM(
  input wire rst, 
  input wire clk, 

  input wire[`AluOpBus] aluop_EXMEM_i, 
  input wire wreg_EXMEM_i, 
  input wire[4:0] waddr_EXMEM_i, 
  input wire[31:0] alurslt_EXMEM_i, 

  output reg re_RAM_o, // read enable 
  output reg[31:0] raddr_RAM_o, 
  input wire[7:0] rdata_RAM_i,
  output reg we_RAM_o,  // write enable
  output reg[31:0] waddr_RAM_o, 
  output reg[7:0] wdata_RAM_o, // assigned to cpu-ram port

  output reg wreg_MEMWB_o, 
  output reg[4:0] waddr_MEMWB_o, 
  output reg[31:0] wdata_MEMWB_o
); 
  // FSM control signals def  
  reg beg_flag; 
  reg end_flag; 
  wire ram_access; 
  reg[2:0] FSM; // FSM state.   
  assign ram_access = beg_flag ^ end_flag; 
  
  // wdata_MEMWB_o data selection implemented by 2-bit mux 
  reg mxram_sel;  // mux sel signal for wdata_MEMWB_o. 1 for ram-access, 0 for pass.  
  reg mxram_ext;  // mux sel signal for wdata_MEMWB_o's extension. 1 for having extension, 0 for wiring last byte.  
  reg[7:0] ram_bt_0; 
  reg[7:0] ram_bt_1; 
  reg[7:0] ram_bt_2; 
  reg[7:0] ram_bt_3; 

  always @ (*) begin 
    if (rst == `Enable) begin 
      wdata_MEMWB_o <= `ZeroWord; 
    end else if (mxram_sel == `Disable) begin // no ram access 
      assign wdata_MEMWB_o = alurslt_EXMEM_i; 
    end else if (mxram_ext == `Disable) begin 
      wdata_MEMWB_o <= {rdata_RAM_i, ram_bt_2, ram_bt_1, ram_bt_0}; 
    end else begin 
      wdata_MEMWB_o <= {ram_bt_3, ram_bt_2, ram_bt_1, ram_bt_0}; 
    end 
  end  
  

  // check if opcode or memory fetching address changes 
  reg[`AluOpBus] aluop_history; 
  reg[31:0] alurslt_history; 

  always @ (posedge clk or posedge rst) begin 
    if (rst == `Enable) begin 
      wreg_MEMWB_o <= `Disable; // disable all ram control. 
      waddr_MEMWB_o <= `NopRegAddr;
      re_RAM_o <= `Disable; 
      we_RAM_o <= `Disable; 
      beg_flag <= `Disable; // reset FSM state 
      end_flag <= `Disable; 
      FSM <= 3'b000; 
      aluop_history <= `ALU_NOP_OP; // reset instruction history
      alurslt_history <= `ZeroWord; 
      mxram_sel <= `Disable; 
      mxram_ext <= `Disable; 
    end 
    /**
      ONLY check whether memory-access should begin when it's not working. 
      Checking by comparing inputs with their historical values. 
    */
    else if (ram_access == `Disable) begin // check whether begin 
      if (aluop_history != aluop_EXMEM_i || 
          alurslt_history != alurslt_EXMEM_i) begin 
        aluop_history <= aluop_EXMEM_i; // update history
        alurslt_history <= alurslt_EXMEM_i; 
          case (aluop_EXMEM_i) // begin ram-access
          `ALU_LB_OP, `ALU_LH_OP, `ALU_LBU_OP, `ALU_LHU_OP: begin 
            re_RAM_o <= `Enable; 
            raddr_RAM_o <= alurslt_EXMEM_i; 
            beg_flag <= ~beg_flag; 
            FSM <= 3'b001; 
            mxram_sel <= `Enable; 
            mxram_ext <= `Enable; 
          end 
          `ALU_LW_OP: begin 
            re_RAM_o <= `Enable; 
            raddr_RAM_o <= alurslt_EXMEM_i; 
            beg_flag <= ~beg_flag; 
            FSM <= 3'b001; 
            mxram_sel <= `Enable; 
            mxram_ext <= `Disable;
          end 
          default: begin end // for 'case' completeness 
        endcase // case (aluop_EXMEM_i) 
      end else begin 
        mxram_sel <= `Disable; 
        mxram_ext <= `Disable; 
      end // if-else completeness 
    end 
    /**
      Follow different procedure for distinct fetching requirements. 
      Use aluop_history as a control signal, since it's stable. 
      I abandan using the same procedure together with masks, because of various signed/unsigned extension. 
    */
    else begin // ram_access == `Enable 
      case (FSM) 
        3'b001: begin // $(0) is on bus; 
          raddr_RAM_o <= raddr_RAM_o + 32'b1; 
          FSM <= 3'b010;
        end 
        3'b010: begin // fetch $(0); $(1) is on bus; 
          ram_bt_0 <= rdata_RAM_i; 
          // check whether finishes, extend wdata_MEMWB_o if necessary. 
          if (aluop_history == `ALU_LB_OP) begin 
          	{ram_bt_3, ram_bt_2, ram_bt_1} <= {24{ram_bt_0[7]}};
            re_RAM_o <= `Disable; 
            end_flag <= ~end_flag; 
            FSM <= 3'b000; 
          end else if (aluop_history == `ALU_LBU_OP) begin 
            {ram_bt_3, ram_bt_2, ram_bt_1} <= {24'b0};
            re_RAM_o <= `Disable; 
            end_flag <= ~end_flag; 
            FSM <= 3'b000; 
          end else begin 
            raddr_RAM_o <= raddr_RAM_o + 32'b1; 
            FSM <= 3'b011; 
          end 
        end 
        3'b011: begin // fetch $(1); $(2) is on bus;
          ram_bt_1 <= rdata_RAM_i; 
          if (aluop_history == `ALU_LH_OP) begin 
            {ram_bt_3, ram_bt_2} <= {16{ram_bt_1[7]}};
            re_RAM_o <= `Disable; 
            end_flag <= ~end_flag; 
            FSM <= 3'b000; 
          end else if (aluop_history == `ALU_LHU_OP) begin 
            {ram_bt_3, ram_bt_2} <= 16'b0;
            re_RAM_o <= `Disable; 
            end_flag <= ~end_flag; 
            FSM <= 3'b000; 
          end else begin 
            raddr_RAM_o <= raddr_RAM_o + 32'b1; 
            FSM <= 3'b100; 
          end 
        end 
        3'b100: begin // fetch $(2); $(3) is on bus;
          ram_bt_2 <= rdata_RAM_i; 
          raddr_RAM_o <= raddr_RAM_o + 32'b1; 
          FSM <= 3'b000; 
          end_flag <= ~end_flag; 
        end 
        default: begin // dangerous 
        end 
      endcase
    end 
  end 
  
endmodule 