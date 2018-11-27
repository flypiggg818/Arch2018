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
  input wire[31:0] SdataBoffset_EXMEM_i, // value stored in STORE inst, alurslt gives ram-address in this case. 

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
  reg[3:0] FSM; // FSM state.   

  always @ (posedge dclk) begin
  	if (rst == `Enable) begin 
  		beg_flag <= `Disable; 
  	end else begin 
    	beg_flag <= ~beg_flag;  
  	end 
  end 

  always @ (posedge clk or posedge rst) begin 
    if (rst == `Enable) begin 
      wreg_MEMWB_o <= `Disable; // disable all ram control. 
      waddr_MEMWB_o <= `NopRegAddr;
      wdata_MEMWB_o <= `ZeroWord; 
      re_RAM_o <= `Disable; 
      we_RAM_o <= `Disable;
      end_flag <= `Disable;  
      FSM <= 4'b0000; 
    end else begin
      if ((beg_flag ^ end_flag) == `Enable) begin  
        case (FSM) 
          4'b0000: begin // decode 
            wreg_MEMWB_o <= wreg_EXMEM_i; 
            waddr_MEMWB_o <= waddr_EXMEM_i; 
            case (aluop_EXMEM_i) // begin ram-access 
            `ALU_LB_OP, `ALU_LH_OP, `ALU_LBU_OP, `ALU_LHU_OP, `ALU_LW_OP: begin 
              re_RAM_o <= `Enable; 
              raddr_RAM_o <= alurslt_EXMEM_i; 
              FSM <= 4'b0001; 
            end 
            `ALU_SB_OP, `ALU_SH_OP, `ALU_SW_OP: begin 
              we_RAM_o <= `Enable;
              waddr_RAM_o <= alurslt_EXMEM_i; 
              wdata_RAM_o <= SdataBoffset_EXMEM_i[7:0];  
              FSM <= 4'b1001; 
            end 
            default: begin 
              wdata_MEMWB_o <= alurslt_EXMEM_i;  
              end_flag <= ~end_flag;
              FSM <= 4'b0000; 
            end // for 'case' completeness 
          endcase // case (aluop_EXMEM_i) 
          end 
          4'b0001: begin // $(0) is being pushed onto bus 
            raddr_RAM_o <= raddr_RAM_o + 32'b1; 
            FSM <= 4'b0010; 
          end 
          4'b0010: begin // $(1) is being pushed onto bus 
            wdata_MEMWB_o[7:0] <= rdata_RAM_i; 
            if (aluop_EXMEM_i == `ALU_LB_OP) begin 
              wdata_MEMWB_o[31:8] <= {24{wdata_MEMWB_o[7]}};
              re_RAM_o <= `Disable; 
              end_flag <= ~end_flag;
              FSM <= 4'b0000; 
            end else if (aluop_EXMEM_i == `ALU_LBU_OP) begin 
              wdata_MEMWB_o[31:8] <= 24'b0; 
              re_RAM_o <= `Disable; 
              end_flag <= ~end_flag;
              FSM <= 4'b0000; 
            end else begin 
              raddr_RAM_o <= raddr_RAM_o + 32'b1; 
              FSM <= 4'b0011; 
            end 
          end 
          4'b0011: begin // $(2) is being pushed onto bus 
            wdata_MEMWB_o[15:8] <= rdata_RAM_i; 
            if (aluop_EXMEM_i == `ALU_LH_OP) begin 
              wdata_MEMWB_o[31:16] <= {16{wdata_MEMWB_o[15]}};
              re_RAM_o <= `Disable; 
              end_flag <= ~end_flag;
              FSM <= 4'b0000; 
            end else if (aluop_EXMEM_i == `ALU_LHU_OP) begin 
              wdata_MEMWB_o[31:16] <= 16'b0; 
              re_RAM_o <= `Disable; 
              end_flag <= ~end_flag;
              FSM <= 4'b0000; 
            end else begin 
              raddr_RAM_o <= raddr_RAM_o + 32'b1; 
              FSM <= 4'b0100; 
            end 
          end 
          4'b0100: begin // $(3) is being pushed onto bus 
            wdata_MEMWB_o[23:16] <= rdata_RAM_i;
            FSM <= 4'b0101; 
          end 
          4'b0101: begin 
            wdata_MEMWB_o[31:24] <= rdata_RAM_i;
            re_RAM_o <= `Disable; 
            end_flag <= ~end_flag;
            FSM <= 4'b0000; 
          end 
          4'b1001: begin 
            if (aluop_EXMEM_i == `ALU_SB_OP) begin 
              we_RAM_o <= `Disable; 
              end_flag <= ~end_flag; 
              FSM <= 4'b0000; 
            end else begin 
              waddr_RAM_o <= waddr_RAM_o + 32'b1; 
              wdata_RAM_o <= SdataBoffset_EXMEM_i[15:8]; 
              FSM <= 4'b1010; 
            end 
          end 
          4'b1010: begin 
            if (aluop_EXMEM_i == `ALU_SH_OP) begin 
              we_RAM_o <= `Disable; 
              end_flag <= ~end_flag; 
              FSM <= 4'b0000; 
            end else begin 
              waddr_RAM_o <= waddr_RAM_o + 32'b1; 
              wdata_RAM_o <= SdataBoffset_EXMEM_i[23:16]; 
              FSM <= 4'b1011; 
            end
          end 
          4'b1011: begin 
            waddr_RAM_o <= waddr_RAM_o + 32'b1; 
            wdata_RAM_o <= SdataBoffset_EXMEM_i[31:24]; 
            FSM <= 4'b1100; 
          end 
          4'b1100: begin 
            we_RAM_o <= `Disable; 
            end_flag <= ~end_flag; 
            FSM <= 4'b0000; 
          end 
          default: begin 
          end 
        endcase 
      end 
    end 
  end 
endmodule 