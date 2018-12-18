`include "macro.vh"
/**
  produce delayed reset signal for all modules other than clock-divider 
*/
module rst_dragger(
  input wire clk, 
  input wire rst,
  output wire drst
); 
  reg[2:0] delay_cnt;

  assign drst = rst | (|delay_cnt); // when all bits of delayed-counter are 0, drst is disabled. 
  always @ (posedge clk) begin 
    if (rst == `Enable) begin 
      delay_cnt <= 4'b1; 
    end else if (delay_cnt == 4'b0) begin 
      // hold 
    end else begin 
      delay_cnt <= delay_cnt + 4'b1; 
    end 
  end 
endmodule 