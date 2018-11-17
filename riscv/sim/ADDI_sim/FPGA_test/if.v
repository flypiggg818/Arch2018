`include "macro.vh"

// module port naming convention: name_dstModule_i/o. 

/**
  IF module is a combinational logic to catch up to 4 cycles. 
  See README in sim/IF_sim for more instruction. 
*/
module IF(
  input wire clk, 
  input wire dclk, 
  input wire rst, 
  input wire rdy, 
  
  // ram ce is true when addr is valid (handled in cpu module). 
  output reg[31:0] addr_mem_o, 
  input wire[7:0] d_mem_i, 
  
  output wire[31:0] inst_IFID_o
); 
  
  reg[7:0] inst_bt_0; 
  reg[7:0] inst_bt_1; 
  reg[7:0] inst_bt_2; 

  assign inst_IFID_o[7:0] = inst_bt_0; 
  assign inst_IFID_o[15:8] = inst_bt_1; 
  assign inst_IFID_o[23:16] = inst_bt_2; 
  assign inst_IFID_o[31:24] = d_mem_i; // logic circuit. 
  
  reg beg_flag;
  reg end_flag;  
  reg[2:0] FSM; // FSM state. 

  always @ (posedge dclk) begin 
    if (rst == `Enable) begin 
      beg_flag <= `Disable; 
    end else if (rdy == `Disable) begin 
      // do nothing, avoid going into 'clk' always block
    end else begin 
      // new address is coming. Nothing to do for IF. 
      beg_flag <= ~beg_flag; 
    end 
  end 

  always @ (posedge clk or posedge rst) begin 
    if (rst == `Enable) begin 
      inst_bt_0 <= `ZeroByte; 
      inst_bt_1 <= `ZeroByte; 
      inst_bt_2 <= `ZeroByte; 
			addr_mem_o <= `ZeroWord; 
      FSM <= 3'b001; 
      end_flag <= `Disable; 
    end else if ((beg_flag ^ end_flag) == `Enable) begin // if begin and end flags are different 
      case (FSM) 
        3'b001: begin 
          // $(0) is out in posedge 
          addr_mem_o <= addr_mem_o + 32'b1; 
          FSM <= 3'b010; 
        end 
        3'b010: begin 
          // $(1) is out in posedge 
          inst_bt_0 <= d_mem_i; 
          addr_mem_o <= addr_mem_o + 32'b1; 
          FSM <= 3'b011; 
        end 
        3'b011: begin 
          // $(2) is out in posedge 
          inst_bt_1 <= d_mem_i; 
          addr_mem_o <= addr_mem_o + 32'b1; 
          FSM <= 3'b100; 
        end 
        3'b100: begin 
          inst_bt_2 <= d_mem_i; 
          addr_mem_o <= `ZeroWord; 
          FSM <= 3'b000; 
        end 
        3'b000: begin 
          // simultaneous state with dclk. 
          // note flags should be altered simultaneously, otherwise circuit won't check 'case' block. 
          end_flag <= ~end_flag; 
          FSM <= 3'b001; 
        end 
        default: begin 
          // avoid collision against 'dclk' block
        end 
      endcase
    end 
  end
endmodule 