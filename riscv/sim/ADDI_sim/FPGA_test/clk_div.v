// one-fourth clock divider. 
/**
  This clock divider has a inner edge detector, so that it's only reset upon the posedge of reset signal. 
  It assumes the ground truth that 'reset signal is always drived'! 
*/
module clk_div(
  input wire clk,
  input wire rst,  
  
  output wire dclk 
); 
  reg[2:0] cnt; 
  assign dclk = cnt[2]; 

  reg delay_rst; 
  wire edge_rst; // edge signal used to reset clock counter. 
  assign edge_rst = rst ^ delay_rst; 
  always @ (posedge clk) begin 
    delay_rst <= rst; 
  end 

  always @ (posedge clk) begin 
    if (edge_rst == 1'b1) begin 
      cnt <= 3'b0; 
    end else if (cnt == 3'b100) begin 
      cnt <= 3'b0; 
    end else begin 
      cnt <= cnt + 3'b1; 
    end 
  end

endmodule 