module edge_detector(
  input wire clk, 
  input wire dclk, 
  output wire posedg
);

  reg delayed; 
  assign posedg = dclk & (~delayed); 
  
  always @ (posedge clk) begin
    delayed <= dclk; 
  end 
  
endmodule 