`include "macro.vh"

// module port naming convention: name_dstModule_i/o. 
/**
  IF module is a combinational logic to catch up to 5 cycles. But considering more slower parts, we use 6 times divided clock here. 
  See README in sim/IF_sim for more instruction. 
*/
module IF(
  input wire clk, 
  input wire dclk, 
  input wire rst, 
  input wire rdy, 
  input wire[1:0] stl_STALLER_i,

  // ram ce is true when addr is valid (handled in cpu module). 
  output reg[31:0] addr_RAM_o, 
  input wire[7:0] data_RAM_i, 
  input wire stall_RAM_i, 

  output reg[31:0] inst_IFID_o
); 

  reg beg_flag; 
  reg end_flag;
  reg[2:0] FSM; // FSM state. 

  always @ (posedge dclk) begin 
    if (rst == `Enable) begin 
      beg_flag <= `Disable; 
    end else if (rdy == `Disable) begin 
      // do nothing, avoid going into 'clk' always block
    end else if (stl_STALLER_i == `Stall) begin // hold by staller 
    end else begin 
      // new address is coming. Nothing to do for IF. 
      beg_flag <= ~beg_flag; 
    end 
  end 

  always @ (posedge clk or posedge rst) begin 
    if (rst == `Enable) begin 
			addr_RAM_o <= `ZeroWord; 
      FSM <= 3'b001; 
      end_flag <= `Disable; 
      inst_IFID_o <= `ZeroWord; 
    end else if ((beg_flag ^ end_flag) == `Enable) begin // if begin and end flags are different 
      if (stall_RAM_i == `Enable) begin // ram is occupied, abandon this inst-fetching 
        FSM <= 3'b001; 
        end_flag <= ~end_flag; 
        inst_IFID_o <= `ZeroWord; 
        addr_RAM_o[1:0] <= 2'b0; // re-align pc address 
      end else begin 
        case (FSM) 
          3'b001: begin 
            // $(0) is on bus 
            addr_RAM_o <= addr_RAM_o + 32'b1; 
            FSM <= 3'b010; 
          end 
          3'b010: begin 
            // $(1) is on bus 
            inst_IFID_o[7:0] <= data_RAM_i; 
            addr_RAM_o <= addr_RAM_o + 32'b1; 
            FSM <= 3'b011; 
          end 
          3'b011: begin 
            // $(2) is on bus 
            inst_IFID_o[15:8] <= data_RAM_i; 
            addr_RAM_o <= addr_RAM_o + 32'b1; 
            FSM <= 3'b100; 
          end 
          3'b100: begin 
            // $(3) is on bus 
            inst_IFID_o[23:16] <= data_RAM_i; 
            addr_RAM_o <= addr_RAM_o + 32'b1; 
            FSM <= 3'b101; 
          end 
          3'b101: begin 
            inst_IFID_o[31:24] <= data_RAM_i; 
            end_flag <= ~end_flag; 
            FSM <= 3'b001; 
          end 
          default: begin 
            // avoid collision against 'dclk' block
          end 
        endcase 
      end 
		end else begin 
		end // for the completeness of 'if-else'. 
  end
endmodule 