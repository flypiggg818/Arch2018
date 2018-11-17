`include "macro.vh"

// module port naming convention: name_dstModule_i/o. 

// 32 word registerfile, needn't be controlled by rdy signal
// should I make it faster? 
module REGFILE(
  input wire rst, 
  input wire dclk, 

  input wire re1_ID_i, // read enable
  input wire[4:0] raddr1_ID_i, // read addr 
  output reg[31:0] rdata1_ID_o, 

  input wire re2_ID_i, 
  input wire[4:0] raddr2_ID_i, 
  output reg[31:0] rdata2_ID_o, 

  input wire we_WB_i, 
  input wire[4:0] waddr_WB_i, 
  input wire[31:0] wdata_WB_i
); 
  integer i; // for initialize
  reg[31:0] regs[4:0]; 


  always @ (posedge dclk or posedge rst) begin 
    if (rst == `Enable) begin
      for(i = 0; i < 32; i = i+1) begin 
        regs[i] <= `ZeroWord; 
      end 
    end else begin 
    end 
  end 

  // 1st read 
  always @ (posedge dclk) begin 
    if (rst == `Disable && re1_ID_i == `Enable) begin 
      rdata1_ID_o <= regs[raddr1_ID_i]; 
    end else begin 
      rdata1_ID_o <= `ZeroWord; 
    end 
  end 

  // 2nd read 
  always @ (posedge dclk) begin 
    if (rst == `Disable && re2_ID_i == `Enable) begin 
      rdata2_ID_o <= regs[raddr2_ID_i]; 
    end else begin 
      rdata2_ID_o <= `ZeroWord; 
    end 
  end 

  // write
  always @ (posedge dclk) begin 
    if (rst == `Disable && we_WB_i == `Enable) begin 
      regs[waddr_WB_i] <= wdata_WB_i; 
    end else begin 
      // don't write. 
    end 
  end 

endmodule 