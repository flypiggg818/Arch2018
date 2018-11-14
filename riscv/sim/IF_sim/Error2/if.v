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
  reg[7:0] inst_blocker; 

  assign inst_IFID_o[7:0] = inst_bt_0; 
  assign inst_IFID_o[15:8] = inst_bt_1; 
  assign inst_IFID_o[23:16] = inst_bt_2; 
  assign inst_IFID_o[31:24] = d_mem_i & inst_blocker; // logic circuit. 
  
  reg[2:0] FSM; // FSM state. 

  always @ (posedge dclk or posedge rst) begin 
    if (rst == `Enable) begin 
      // initialize circuit
      addr_mem_o <= `ZeroWord; 
      inst_bt_0 <= `ZeroByte; 
      inst_bt_1 <= `ZeroByte; 
      inst_bt_2 <= `ZeroByte; 
      FSM <= 3'b000; 
      inst_blocker <= `ZeroByte; 
    end else if (rdy == `Disable) begin 
      // do nothing, avoid going into 'clk' always block
      // FSM <= 3'b000; // hold
    end else begin // addr 0 -> 1
      inst_blocker <= `ZeroWord; 
      addr_mem_o <= addr_mem_o + 32'b1; 
      FSM <= 3'b001;
    end 
  end 

  always @ (posedge clk) begin 
    case (FSM) 
			3'b001: begin // wait for data; addr 1 -> 2
				addr_mem_o <= addr_mem_o + 32'b1; 
				FSM <= 2'b010; 
			end 
			3'b010: begin // $(0) is out in posedge; addr 2 -> 3
				inst_bt_0 <= d_mem_i; 
				addr_mem_o <= addr_mem_o + 32'b1; 
				FSM <= 3'b011; 
			end 
			3'b011: begin // $(1) is out in posedge; addr 3 -> 4
				inst_bt_1 <= d_mem_i; 
				addr_mem_o <= addr_mem_o + 32'b1;
				FSM <= 3'b100;  
			end 
      3'b100: begin // $(2) is out in posedge; hold addr 
				inst_blocker <= 8'b11111111; // enable subInst_3 to be ANDED
        FSM <= 3'b000; 
      end 
			default: begin 
				// avoid collision against 'dclk' block
			end 
		endcase
  end
endmodule 