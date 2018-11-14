`include "macro.vh"

// module port naming convention: name_dstModule_i/o. 

/**
  IF module is a combinational logic to catch up to 4 cycles. 
*/
module IF(
  input wire clk, 
  input wire dclk, 
  input wire rst, 
  input wire rdy, 
  
  // ram ce is true when addr is valid (handled in cpu module). 
  output reg[31:0] addr_mem_o, 
  output reg re_mem_o, 
  input wire[7:0] d_mem_i, 
  
  output wire[31:0] inst_IFID_o
); 
  
  reg[7:0] inst_bt_0; 
  reg[7:0] inst_bt_1; 
  reg[7:0] inst_bt_2; 
  reg[7:0] inst_blocker; // block instruction output when reset or paused. 

  assign inst_IFID_o[7:0] = inst_bt_0; 
  assign inst_IFID_o[15:8] = inst_bt_1; 
  assign inst_IFID_o[23:16] = inst_bt_2; 
  assign inst_IFID_o[31:24] = d_mem_i & inst_blocker; // logic circuit. 

  // it's basically a state counter in FSM. 
  reg[2:0] subInst_cnt; // record which part of the inst are we in. 
  
  // start read from mem every dclk, automatically without outer invoke. 
  // inst-fetching can only be triggered by dclk. 
  always @ (posedge dclk) begin 
    if(rdy == `Disable) begin 
      // pause
    end else begin 
      // state 3'b000, syncrhonized with dclk. Do hack to address, to goto next inst. 
      // addr_mem_o <= ((addr_mem_o + 32'b1) & ~(32'b11)); 
      addr_mem_o <= `ZeroWord; 
      re_mem_o <= `Enable;  // These signal should actually be controlled by read-write arbitrager. 
      subInst_cnt <= 3'b001; // starting state
      inst_blocker <= 8'b11111111; 
    end  
  end 

  always @ (posedge clk or rst) begin 
    // output all 0 instruction when reset. 
    if (rst == `Enable) begin 
      addr_mem_o <= `ZeroWord; 
      inst_bt_0 <= `ZeroByte; 
      inst_bt_1 <= `ZeroByte; 
      inst_bt_2 <= `ZeroByte; 
      inst_blocker <= `ZeroByte;
      re_mem_o <= `Disable;  
      subInst_cnt <= 3'b0;
    end else begin 
      // let rdy be synchronized by dclk
      case (subInst_cnt) 
        3'b001: begin // controlled by read signal "value" (not posedge), prepare to give data. 
          subInst_cnt <= 3'b010; 
        end 
        3'b010: begin // address 1, coming data 0. 
          inst_bt_0 <= d_mem_i; 
          addr_mem_o <= addr_mem_o + 32'b1; 
          subInst_cnt <= 3'b011;
        end 
        3'b011: begin // address 2, coming data 1. 
          inst_bt_1 <= d_mem_i; 
          addr_mem_o <= addr_mem_o + 32'b1; 
          subInst_cnt <= 3'b100; 
        end 
        3'b100: begin // address 3, coming data 2. 
          inst_bt_2 <= d_mem_i; 
          addr_mem_o <= addr_mem_o + 32'b1; 
          subInst_cnt <= 3'b000; 
        end 
        default: begin 
        end 
      endcase 
    end 
  end 
endmodule 