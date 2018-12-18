`include "macro.vh"
// one-fourth clock divider. 
/**
  This clock divider has a inner edge detector, so that it's only reset upon the posedge of reset signal. 
  It assumes the ground truth that 'reset signal is always drived'! 
*/
module clk_div(
  input wire clk,
  input wire rst,  
  
//  output wire dclk 
	output reg dclk
); 
//  reg[2:0] cnt; 
	always @ (posedge clk) begin 
		if (rst == 1'b1) begin 
			dclk <= 1'b1;  
		end else begin 
			dclk <= ~dclk; 
		end 
	end 

endmodule 