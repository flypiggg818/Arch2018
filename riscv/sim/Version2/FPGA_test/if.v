`include "macro.vh"

// module port naming convention: name_dstModule_i/o. 
/**
  IF module is a combinational logic to catch up to 5 cycles. But considering more slower parts, we use 6 times divided clock here. 
  See README in sim/IF_sim for more instruction. 
*/
module IF(
  input wire clk, 
  input wire rst, 
  input wire[1:0] stl_STALLER_i,

  // ram ce is true when addr is valid (handled in cpu module). 
  output reg[31:0] addr_RAM_o,
  output wire[3:0] FSM_RAM_o,  
  input wire[7:0] data_RAM_i, 
  input wire JBje_ID_i, // jump enable provided by ID 
  input wire[31:0] JBtaraddr_ID_i, 
  
  output wire[31:0] inst_IFID_o, 
  output wire[31:0] pc_IFID_o // pass down pc value used by JUMP and BRANCH in ID. 
); 

  reg[3:0] FSM; // impl by state machine 
  assign FSM_RAM_o = FSM; 

  reg valid; // output only when instruction is valid 
  reg[31:0] inst_o; 
  reg[31:0] pc_o; 
  assign inst_IFID_o = (valid == `Enable) ? inst_o : 32'b0; 
  assign pc_IFID_o = (valid == `Enable) ? pc_o : 32'b0; 

  always @ (posedge clk or posedge rst) begin 
    if (rst == `Enable) begin 
			addr_RAM_o <= `ZeroWord; // init pc value
      FSM <= 4'b0000; 
      inst_o <= `ZeroWord; 
      pc_o <= `ZeroWord; 
      valid <= `Disable; 
    end else if (stl_STALLER_i == `IF_BACKALIGN) begin 
      // TODO: this implementation greatly affects performance, consider optimizing it later 
      /** note that now I will finish doing a whole instruction fetching before getting stored, thus 
          ending up as FSM 4'b0000, pc aligned by 4, and a valid state. 
      */
      FSM <= 4'b0000; 
      inst_o <= `ZeroWord; 
      pc_o <= `ZeroWord; 
      valid <= `Disable; 
      addr_RAM_o <= (FSM == 4'b0000) ? (addr_RAM_o - 32'h4) : {addr_RAM_o[31:2], 2'b0}; 
    end else if (stl_STALLER_i == `IF_STALL) begin 
      // do nothing 
    end else if (JBje_ID_i == `Enable) begin // branch signal can interrupt instruction fetching
      // work as FSM 4'b0000 state
      addr_RAM_o <= JBtaraddr_ID_i;
      pc_o <= JBtaraddr_ID_i; 
      valid <= `Disable;  
      FSM <= 4'b0001; 
    end else begin // without any control signal and hazard handling. 
      case (FSM) 
        4'b0000: begin // valid is disable 
          pc_o <= addr_RAM_o; // record current pc address. 
          valid <= `Disable;  
          FSM <= 4'b0001; 
        end 
        4'b0001: begin 
          FSM <= 4'b0010;
        end 
        4'b0010: begin 
          inst_o[7:0] <= data_RAM_i; 
          addr_RAM_o <= addr_RAM_o + 32'b1; 
          FSM <= 4'b0011; 
        end 
        4'b0011: begin 
          FSM <= 4'b0100; 
        end 
        4'b0100: begin 
          inst_o[15:8] <= data_RAM_i; 
          addr_RAM_o <= addr_RAM_o + 32'b1; 
          FSM <= 4'b0101; 
        end 
        4'b0101: begin 
          FSM <= 4'b0110; 
        end 
        4'b0110: begin 
          inst_o[23:16] <= data_RAM_i; 
          addr_RAM_o <= addr_RAM_o + 32'b1; 
          FSM <= 4'b0111; 
        end 
        4'b0111: begin 
          FSM <= 4'b1000; 
        end 
        4'b1000: begin 
          inst_o[31:24] <= data_RAM_i; 
          addr_RAM_o <= addr_RAM_o + 32'b1; 
          FSM <= 4'b0000; 
          valid <= `Enable; 
        end 
        default: begin end 
			endcase
    end 
  end
endmodule 