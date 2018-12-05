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
  reg[4:0] FSM; // FSM state.   

  wire load_byte = (aluop_EXMEM_i == `ALU_LB_OP || aluop_EXMEM_i == `ALU_LBU_OP); 
  wire load_halfword = (aluop_EXMEM_i == `ALU_LH_OP || aluop_EXMEM_i == `ALU_LHU_OP); 
  wire signed_ext = (aluop_EXMEM_i == `ALU_LH_OP || aluop_EXMEM_i == `ALU_LB_OP); 
  wire unsigned_ext = (aluop_EXMEM_i == `ALU_LHU_OP || aluop_EXMEM_i == `ALU_LBU_OP); 

  always @ (posedge dclk or posedge rst) begin
  	if (rst == `Enable) begin 
  		beg_flag = `Disable; 
  	end else begin 
    	beg_flag = ~beg_flag;  
  	end 
  end 

  always @ (posedge clk or posedge rst) begin 
    if (rst == `Enable) begin 
      wreg_MEMWB_o = `Disable; // disable all ram control. 
      waddr_MEMWB_o = `NopRegAddr;
      wdata_MEMWB_o = `ZeroWord; 
      re_RAM_o = `Disable; 
      we_RAM_o = `Disable;
      end_flag = `Disable;  
      FSM = 5'b00000; 
    end else begin
      wreg_MEMWB_o = wreg_EXMEM_i; // avoid strange mis-align in wave-plot
      waddr_MEMWB_o = waddr_EXMEM_i; 
      if ((beg_flag ^ end_flag) == `Enable) begin  
        case (FSM) 
          5'b00000: begin // decode 
            case (aluop_EXMEM_i) // begin ram-access 
              `ALU_LB_OP, `ALU_LH_OP, `ALU_LBU_OP, `ALU_LHU_OP, `ALU_LW_OP: begin 
                re_RAM_o = `Enable; 
                raddr_RAM_o = alurslt_EXMEM_i; 
                FSM = 5'b00001; 
              end 
              `ALU_SB_OP, `ALU_SH_OP, `ALU_SW_OP: begin 
                we_RAM_o = `Enable;
                waddr_RAM_o = alurslt_EXMEM_i; 
                wdata_RAM_o = SdataBoffset_EXMEM_i[7:0];  
                FSM = 5'b10001; 
              end 
              default: begin 
                wdata_MEMWB_o = alurslt_EXMEM_i;  
                end_flag = ~end_flag;
                FSM = 5'b00000; 
              end // for 'case' completeness 
            endcase // case (aluop_EXMEM_i) 
          end 
          5'b00001: begin // $(0) is being pushed onto bus 
            FSM = 5'b00010; 
          end 
          5'b00010: begin // $(1) is being pushed onto bus 
            wdata_MEMWB_o[7:0] = rdata_RAM_i; 
            if (load_byte == `Enable) begin 
              wdata_MEMWB_o[31:8] = (signed_ext == `Enable) ? {24{wdata_MEMWB_o[7]}} : 24'b0; 
              re_RAM_o = `Disable; 
              end_flag = ~end_flag;
              FSM = 5'b00000; 
            end else begin 
              raddr_RAM_o = raddr_RAM_o + 32'b1; 
              FSM = 5'b00011; 
            end 
          end 
          5'b00011: begin 
            FSM = 5'b00100; 
          end 
          5'b00100: begin 
            wdata_MEMWB_o[15:8] = rdata_RAM_i; 
            if (load_halfword == `Enable) begin 
              wdata_MEMWB_o[31:16] = (signed_ext == `Enable) ? {16{wdata_MEMWB_o[15]}} : 16'b0; 
              re_RAM_o = `Disable; 
              end_flag = ~end_flag;
              FSM = 5'b00000; 
            end else begin 
              raddr_RAM_o = raddr_RAM_o + 32'b1; 
              FSM = 5'b00101; 
            end 
          end 
          5'b00101: begin 
            FSM = 5'b00110; 
          end 
          5'b00110: begin 
            wdata_MEMWB_o[23:16] = rdata_RAM_i;
            raddr_RAM_o = raddr_RAM_o + 32'b1; 
            FSM = 5'b00111; 
          end   
          5'b00111: begin
            FSM = 5'b01000; 
          end 
          5'b01000: begin 
            wdata_MEMWB_o[31:24] = rdata_RAM_i;
            re_RAM_o = `Disable; 
            end_flag = ~end_flag;
            FSM = 5'b00000; 
          end 
          5'b10001: begin 
            if (aluop_EXMEM_i == `ALU_SB_OP) begin 
              we_RAM_o = `Disable; 
              end_flag = ~end_flag; 
              FSM = 5'b00000; 
            end else begin 
              waddr_RAM_o = waddr_RAM_o + 32'b1; 
              wdata_RAM_o = SdataBoffset_EXMEM_i[15:8]; 
              FSM = 5'b10010; 
            end 
          end 
          5'b10010: begin 
            if (aluop_EXMEM_i == `ALU_SH_OP) begin 
              we_RAM_o = `Disable; 
              end_flag = ~end_flag; 
              FSM = 5'b00000; 
            end else begin 
              waddr_RAM_o = waddr_RAM_o + 32'b1; 
              wdata_RAM_o = SdataBoffset_EXMEM_i[23:16]; 
              FSM = 5'b10011; 
            end
          end 
          5'b10011: begin 
            waddr_RAM_o = waddr_RAM_o + 32'b1; 
            wdata_RAM_o = SdataBoffset_EXMEM_i[31:24]; 
            FSM = 5'b10100; 
          end 
          5'b10100: begin 
            we_RAM_o = `Disable; 
            end_flag = ~end_flag; 
            FSM = 5'b00000; 
          end 
          default: begin 
          end 
        endcase 
      end else begin end 
    end 
  end 
endmodule 