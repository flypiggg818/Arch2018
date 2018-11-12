`include "macro.vh"
/**
    这个模块是一个�?�辑电路，除了它给出的指令地�??是由时序计数器控制增长的�??
*/
module pc(
  input wire rst, 
  input wire clk, 
  // signal to inst_rom
  output reg ce_o,
  output wire[`InstAddrBus] addr_instrom_o,
  input wire[`InstBus] inst_i, 
  // signal to if-id
  output wire[`InstBus] inst_o, 
  output wire[`InstAddrBus] addr_pcid_o
);
  reg[`InstAddrBus] inst_addr; initial inst_addr_o <= `ZeroWord; 
  assign inst_o = inst_i; 
  assign addr_instrom_o = inst_addr; 
  assign addr_pcid_o = inst_addr; 
  
  always @ (posedge clk, posedge rst) begin 
    if (rst == `Enable) begin 
      ce_o <= `Disable; 
      inst_addr_o <= `ZeroWord; 
    end else begin 
    	if (ce_o == `Disable) begin
        ce_o <= `Enable;
      end else begin 
        inst_addr_o = inst_addr_o + 32'h4;
      end 
    end 
  end 
	/*
  initial begin 
  	$monitor("inst: %b opcode: %b rs1: %b rs2: %b rd: %b LUI_OP in macro %b", 
  						inst_i, inst_i[6:0], inst_i[19:15], inst_i[24:20], inst_i[11:7], `LUI_OP); 
	end 
	*/
endmodule 
