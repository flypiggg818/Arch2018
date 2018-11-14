module clk_div(
  input wire clk,
  input wire rst,  
  
  output wire dclk 
); 
  reg[2:0] cnt; 
  assign dclk = cnt[2];  

  always @ (posedge clk or rst) begin 
    if (rst == 1'b1) begin 
      cnt <= 3'b0; 
    end else begin 
      if (cnt == 3'b100) begin 
    	  cnt <= 3'b0; 
      end else begin 
        cnt <= cnt + 3'b1; 
      end 
    end 
  end

endmodule 
