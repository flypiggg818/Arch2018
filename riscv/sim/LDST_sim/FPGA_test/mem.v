`include "macro.vh"

/**
  Although this module should be a combinational logic, since it is 
  driven by high-frequency clock, I make it a sequential FSM. 
  Follow the same 'word fetching' procedure in IF module.
  I suddenly find that I need EIGHT!!! clock cycle. 
  I give up in damn cycles. 
*/
module MEM(
  input wire rst, 
  input wire clk, 
  input wire dclk, 

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

  reg beg_flag; 
  reg end_flag; 
  reg[2:0] FSM; // FSM state.   

  always @ (posedge dclk) begin
    beg_flag <= ~beg_flag;  
  end 

  always @ (posedge clk or posedge rst) begin 
    if (rst == `Enable) begin 
      wreg_MEMWB_o <= `Disable; // disable all ram control. 
      waddr_MEMWB_o <= `NopRegAddr;
      wdata_MEMWB_o <= `ZeroWord; 
      re_RAM_o <= `Disable; 
      we_RAM_o <= `Disable;
      beg_flag <= `Disable; 
      end_flag <= `Disable;  
      FSM <= 3'b001; 
    end else begin
      if ((beg_flag ^ end_flag) == `Enable) begin  
        case (FSM) 
          3'b001: begin // decode 
            wreg_MEMWB_o <= wreg_EXMEM_i; 
            waddr_MEMWB_o <= waddr_EXMEM_i; 
            case (aluop_EXMEM_i) // begin ram-access 
            `ALU_LB_OP, `ALU_LH_OP, `ALU_LBU_OP, `ALU_LHU_OP, `ALU_LW_OP: begin 
              re_RAM_o <= `Enable; 
              raddr_RAM_o <= alurslt_EXMEM_i; 
              FSM <= 3'b010; 
            end 
            default: begin 
              re_RAM_o <= `Disable; 
              wdata_MEMWB_o <= alurslt_EXMEM_i; 
              end_flag <= ~end_flag;
              FSM <= 3'b001; 
            end // for 'case' completeness 
          endcase // case (aluop_EXMEM_i) 
          end 
          3'b010: begin // $(0) is being pushed onto bus 
            raddr_RAM_o <= raddr_RAM_o + 32'b1; 
            FSM <= 3'b011; 
          end 
          3'b011: begin // $(1) is being pushed onto bus 
            wdata_MEMWB_o[7:0] <= rdata_RAM_i; 
            if (aluop_EXMEM_i == `ALU_LB_OP) begin 
              wdata_MEMWB_o[31:8] <= {24{wdata_MEMWB_o[7]}};
              re_RAM_o <= `Disable; 
              end_flag <= ~end_flag;
              FSM <= 3'b001; 
            end else if (aluop_EXMEM_i == `ALU_LBU_OP) begin 
              wdata_MEMWB_o[31:8] <= 24'b0; 
              re_RAM_o <= `Disable; 
              end_flag <= ~end_flag;
              FSM <= 3'b001; 
            end else begin 
              raddr_RAM_o <= raddr_RAM_o + 32'b1; 
              FSM <= 3'b100; 
            end 
          end 
          3'b100: begin // $(2) is being pushed onto bus 
            wdata_MEMWB_o[15:8] <= rdata_RAM_i; 
            if (aluop_EXMEM_i == `ALU_LH_OP) begin 
              wdata_MEMWB_o[31:16] <= {16{wdata_MEMWB_o[15]}};
              re_RAM_o <= `Disable; 
              end_flag <= ~end_flag;
              FSM <= 3'b001; 
            end else if (aluop_EXMEM_i == `ALU_LHU_OP) begin 
              wdata_MEMWB_o[31:16] <= 16'b0; 
              re_RAM_o <= `Disable; 
              end_flag <= ~end_flag;
              FSM <= 3'b001; 
            end else begin 
              raddr_RAM_o <= raddr_RAM_o + 32'b1; 
              FSM <= 3'b101; 
            end 
          end 
          3'b101: begin // $(3) is being pushed onto bus 
            wdata_MEMWB_o[23:16] <= rdata_RAM_i;
            re_RAM_o <= `Disable; 
            FSM <= 3'b110; 
          end 
          3'b110: begin 
            wdata_MEMWB_o[31:24] <= rdata_RAM_i;
            end_flag <= ~end_flag;
            FSM <= 3'b001; 
          end 
          default: begin 
          end 
        endcase 
      end 
    end 
  end 
endmodule 