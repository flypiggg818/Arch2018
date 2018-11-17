// RISCV32I CPU top module
// port modification allowed for debugging purposes

// module port naming convention: name_dstModule_i/o. 
// wire naming convention: name_srcModule_i/o. 

module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
  input  wire			 		        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)

	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read takes 2 cycles, write takes 1 cycle
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17]==1)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

wire dclk; 
clk_div clk_div0(.clk(clk_in), 
                 .rst(rst_in), 
                 .dclk(dclk)); 

wire[31:0] inst_IF_o; 
wire re_IF_o; 
assign mem_wr = re_IF_o; 
IF IF0(.clk(clk_in), 
       .dclk(dclk), 
       .rst(rst_in),
       .rdy(rdy_in), 
       .addr_mem_o(mem_a), 
       .d_mem_i(mem_din), 
       .inst_IFID_o(inst_IF_o)); 

wire[31:0] inst_IFID_i; 
assign inst_IFID_i = inst_IF_o; 
wire[31:0] inst_IFID_o; 
IF_ID IF_ID0(.dclk(dclk), 
             .rst(rst_in), 
             .rdy(rdy_in), 
             .inst_IF_i(inst_IFID_i), 
             .inst_ID_o(inst_IFID_o)); 

assign dbgreg_dout = inst_IFID_o; // assign debug output. 

always @(posedge clk_in)
  begin
    if (rst_in)
      begin
      
      end
    else if (!rdy_in)
      begin
      
      end
    else
      begin
      
      end
  end

endmodule