// one-fourth clock divider. 
module clk_div(
  input wire clk,
  input wire rst,  
  
  output wire dclk 
); 
  reg[1:0] cnt; 
  assign dclk = cnt[1] & cnt[0]; 

  always @ (posedge clk or rst) begin 
    if (rst == 1'b1) begin 
      cnt <= 2'b0; 
    end else begin 
      cnt <= cnt + 2'b1; 
    end 
  end

endmodule 
