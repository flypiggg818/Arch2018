`include "macro.vh"
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
 
wire[7:0] data_IF_i;
assign data_IF_i = mem_din;  
wire[1:0] stl_IF_i; 
wire[31:0] inst_IF_o; 
wire re_IF_o; 
wire[31:0] addr_IF_o;
wire stall_IF_i; 
IF IF0(.clk(clk_in), // common 
       .dclk(dclk), 
       .rst(rst_in),
       .rdy(rdy_in), 
       .stl_STALLER_i(stl_IF_i), 
       .addr_RAM_o(addr_IF_o), // ram access 
       .data_RAM_i(data_IF_i), 
       .stall_RAM_i(stall_IF_i), 
       .inst_IFID_o(inst_IF_o)); // down-stream 

wire[31:0] inst_IFID_i; 
wire[1:0] stl_IFID_i; 
assign inst_IFID_i = inst_IF_o; 
wire[31:0] inst_IFID_o; 
IF_ID IF_ID0(.dclk(dclk), // common 
             .rst(rst_in), 
             .rdy(rdy_in),
             .stl_STALLER_i(stl_IFID_i),  
             .inst_IF_i(inst_IFID_i), // down-stream 
             .inst_ID_o(inst_IFID_o)); 

wire[31:0] inst_ID_i; 
assign inst_ID_i = inst_IFID_o; 
wire re1_ID_o; 
wire[4:0] raddr1_ID_o; 
wire[31:0] rdata1_ID_i; 
wire re2_ID_o; 
wire[4:0] raddr2_ID_o; 
wire[31:0] rdata2_ID_i; 
wire[`AluOpBus] aluop_ID_o; 
wire[`AluSelBus] alusel_ID_o; 
wire[31:0] regdata1_ID_o; 
wire[31:0] regdata2_ID_o; 
wire wreg_ID_o; 
wire[4:0] waddr_ID_o; 
wire[31:0] storedata_ID_o; 
wire rq_ID_o; 
// predefine registerfile wires for assignment 
wire[31:0] rdata1_REGFILE_o; 
wire[31:0] rdata2_REGFILE_o;
assign rdata1_ID_i = rdata1_REGFILE_o; 
assign rdata2_ID_i = rdata2_REGFILE_o; 
// forwading signals definition, note that these siganls are assigned at EX and MEM
wire fwregEX_ID_i;
wire[4:0] fwaddrEX_ID_i;
wire[31:0] fwdataEX_ID_i;
wire fwregMEM_ID_i;
wire[4:0] fwaddrMEM_ID_i;
wire[31:0] fwdataMEM_ID_i;
wire[`AluOpBus] faluopEX_ID_i; 
ID ID0(.rst(rst_in), // common 
       .inst_IFID_i(inst_ID_i), // input
       .re1_REGFILE_o(re1_ID_o), // registerfile access 
       .raddr1_REGFILE_o(raddr1_ID_o), 
       .rdata1_REGFILE_i(rdata1_ID_i), 
       .re2_REGFILE_o(re2_ID_o), 
       .raddr2_REGFILE_o(raddr2_ID_o), 
       .rdata2_REGFILE_i(rdata2_ID_i), 
       .fwreg_EX_i(fwregEX_ID_i), // forwarding signals
       .fwaddr_EX_i(fwaddrEX_ID_i), 
       .fwdata_EX_i(fwdataEX_ID_i), 
       .fwreg_MEM_i(fwregMEM_ID_i),
       .fwaddr_MEM_i(fwaddrMEM_ID_i), 
       .fwdata_MEM_i(fwdataMEM_ID_i), 
       .faluop_EX_i(faluopEX_ID_i), 
       .aluop_IDEX_o(aluop_ID_o), // decode results
       .alusel_IDEX_o(alusel_ID_o), 
       .regdata1_IDEX_o(regdata1_ID_o), 
       .regdata2_IDEX_o(regdata2_ID_o), 
       .wreg_IDEX_o(wreg_ID_o), 
       .waddr_IDEX_o(waddr_ID_o), 
       .storedata_IDEX_o(storedata_ID_o), 
       .rq_STALLER_o(rq_ID_o)); 

wire[`AluOpBus] aluop_IDEX_i; 
wire[`AluSelBus] alusel_IDEX_i; 
wire[31:0] regdata1_IDEX_i; 
wire[31:0] regdata2_IDEX_i; 
wire wreg_IDEX_i; 
wire[4:0] waddr_IDEX_i;
wire[31:0] storedata_IDEX_i; 
wire[1:0] stl_IDEX_i; 
assign aluop_IDEX_i = aluop_ID_o; 
assign alusel_IDEX_i = alusel_ID_o; 
assign regdata1_IDEX_i = regdata1_ID_o; 
assign regdata2_IDEX_i = regdata2_ID_o; 
assign wreg_IDEX_i = wreg_ID_o; 
assign waddr_IDEX_i = waddr_ID_o; 
assign storedata_IDEX_i = storedata_ID_o; 

wire[`AluOpBus] aluop_IDEX_o; 
wire[`AluSelBus] alusel_IDEX_o; 
wire[31:0] regdata1_IDEX_o; 
wire[31:0] regdata2_IDEX_o; 
wire wreg_IDEX_o; 
wire[4:0] waddr_IDEX_o; 
wire[31:0] storedata_IDEX_o; 
ID_EX ID_EX0(.rst(rst_in), // common 
             .dclk(dclk), 
             .aluop_ID_i(aluop_IDEX_i), // inputs 
             .alusel_ID_i(alusel_IDEX_i),
             .regdata1_ID_i(regdata1_IDEX_i), 
             .regdata2_ID_i(regdata2_IDEX_i), 
             .wreg_ID_i(wreg_IDEX_i), 
             .waddr_ID_i(waddr_IDEX_i),
             .storedata_ID_i(storedata_IDEX_i),
             .stl_STALLER_i(stl_IDEX_i), 
             .aluop_EX_o(aluop_IDEX_o), // down-stream 
             .alusel_EX_o(alusel_IDEX_o), 
             .regdata1_EX_o(regdata1_IDEX_o), 
             .regdata2_EX_o(regdata2_IDEX_o), 
             .wreg_EX_o(wreg_IDEX_o), 
             .waddr_EX_o(waddr_IDEX_o), 
             .storedata_EX_o(storedata_IDEX_o));  

wire[`AluOpBus] aluop_EX_i;  
wire[`AluSelBus] alusel_EX_i;  
wire[31:0] regdata1_EX_i;  
wire[31:0] regdata2_EX_i; 
wire wreg_EX_i; 
wire[4:0] waddr_EX_i; 
wire[31:0] storedata_EX_i; 
assign aluop_EX_i = aluop_IDEX_o; 
assign alusel_EX_i = alusel_IDEX_o; 
assign regdata1_EX_i = regdata1_IDEX_o; 
assign regdata2_EX_i = regdata2_IDEX_o; 
assign wreg_EX_i = wreg_IDEX_o; 
assign waddr_EX_i = waddr_IDEX_o; 
assign storedata_EX_i = storedata_IDEX_o; 

wire wreg_EX_o; // downstream signals
wire[4:0] waddr_EX_o; 
wire[31:0] alurslt_EX_o; 
wire[31:0] storedata_EX_o; 
wire[`AluOpBus] aluop_EX_o; 
wire rq_EX_o; 
assign fwregEX_ID_i = wreg_EX_o; // assign forwarding signals, note that this forwarding is useless in terms of LD instruction
assign fwaddrEX_ID_i = waddr_EX_o;
assign fwdataEX_ID_i = alurslt_EX_o;
assign faluopEX_ID_i = aluop_EX_o; 
EX EX0(.rst(rst_in), // common
       .aluop_IDEX_i(aluop_EX_i), // inputs 
       .alusel_IDEX_i(alusel_EX_i), 
       .regdata1_IDEX_i(regdata1_EX_i), 
       .regdata2_IDEX_i(regdata2_EX_i), 
       .wreg_IDEX_i(wreg_EX_i),
       .waddr_IDEX_i(waddr_EX_i),
       .storedata_IDEX_i(storedata_EX_i),  
       .aluop_EXMEM_o(aluop_EX_o), // results 
       .wreg_EXMEM_o(wreg_EX_o),
       .waddr_EXMEM_o(waddr_EX_o), 
       .alurslt_EXMEM_o(alurslt_EX_o), 
       .storedata_EXMEM_o(storedata_EX_o), 
       .rq_STALLER_o(rq_EX_o)); 

wire[`AluOpBus] aluop_EXMEM_i; 
wire wreg_EXMEM_i; 
wire[4:0] waddr_EXMEM_i; 
wire[31:0] alurslt_EXMEM_i;
wire[31:0] storedata_EXMEM_i; 
wire[1:0] stl_EXMEM_i; 
assign aluop_EXMEM_i = aluop_EX_o; 
assign wreg_EXMEM_i = wreg_EX_o;  
assign waddr_EXMEM_i = waddr_EX_o; 
assign alurslt_EXMEM_i = alurslt_EX_o; 
assign storedata_EXMEM_i = storedata_EX_o; 

wire[`AluOpBus] aluop_EXMEM_o; 
wire wreg_EXMEM_o;
wire[4:0] waddr_EXMEM_o; 
wire[31:0] alurslt_EXMEM_o; 
wire[31:0] storedata_EXMEM_o; 
EX_MEM EX_MEM0(.rst(rst_in), // common
               .dclk(dclk), 
               .aluop_EX_i(aluop_EXMEM_i), 
               .wreg_EX_i(wreg_EXMEM_i), // inputs 
               .waddr_EX_i(waddr_EXMEM_i), 
               .alurslt_EX_i(alurslt_EXMEM_i),
               .storedata_EX_i(storedata_EXMEM_i), 
               .stl_STALLER_i(stl_EXMEM_i), 
               .aluop_MEM_o(aluop_EXMEM_o), // down-stream 
               .wreg_MEM_o(wreg_EXMEM_o), 
               .waddr_MEM_o(waddr_EXMEM_o), 
               .alurslt_MEM_o(alurslt_EXMEM_o), 
               .storedata_MEM_o(storedata_EXMEM_o)); 

wire[`AluOpBus] aluop_MEM_i; 
wire wreg_MEM_i; 
wire[4:0] waddr_MEM_i; 
wire[31:0] alurslt_MEM_i; 
wire[31:0] storedata_MEM_i; 
assign aluop_MEM_i = aluop_EXMEM_o; 
assign wreg_MEM_i = wreg_EXMEM_o; 
assign waddr_MEM_i = waddr_EXMEM_o; 
assign alurslt_MEM_i = alurslt_EXMEM_o; 
assign storedata_MEM_i = storedata_EXMEM_o; 

wire re_MEM_o; // signal for ram controlling
wire[31:0] raddr_MEM_o; 
wire[7:0] rdata_MEM_i; // input signal is waiting for ARBITRATOR's assignment 
assign rdata_MEM_i = mem_din; 
wire we_MEM_o; 
wire[31:0] waddr_MEM_o; 
wire[7:0] wdata_MEM_o; 

wire wreg_MEM_o; 
wire[4:0] wbaddr_MEM_o; 
wire[31:0] wbdata_MEM_o; 
assign fwregMEM_ID_i = wreg_MEM_o; 
assign fwaddrMEM_ID_i = wbaddr_MEM_o; 
assign fwdataMEM_ID_i = wbdata_MEM_o; 
MEM MEM0(.rst(rst_in), // common
         .clk(clk_in), 
         .dclk(dclk), 
         .aluop_EXMEM_i(aluop_MEM_i), // inputs
         .wreg_EXMEM_i(wreg_MEM_i), 
         .waddr_EXMEM_i(waddr_MEM_i), 
         .alurslt_EXMEM_i(alurslt_MEM_i), 
         .storedata_EXMEM_i(storedata_MEM_i), 
         .re_RAM_o(re_MEM_o), // ram access
         .raddr_RAM_o(raddr_MEM_o), 
         .rdata_RAM_i(rdata_MEM_i), 
         .we_RAM_o(we_MEM_o), 
         .waddr_RAM_o(waddr_MEM_o), 
         .wdata_RAM_o(wdata_MEM_o), 
         .wreg_MEMWB_o(wreg_MEM_o), // down-stream flow 
         .waddr_MEMWB_o(wbaddr_MEM_o), 
         .wdata_MEMWB_o(wbdata_MEM_o));

wire wreg_MEMWB_i; 
wire[4:0] waddr_MEMWB_i; 
wire[31:0] wdata_MEMWB_i; 
assign wreg_MEMWB_i = wreg_MEM_o; 
assign waddr_MEMWB_i = wbaddr_MEM_o; 
assign wdata_MEMWB_i = wbdata_MEM_o; 

wire wreg_MEMWB_o; 
wire[4:0] waddr_MEMWB_o; 
wire[31:0] wdata_MEMWB_o; 
MEM_WB MEM_WB0(.rst(rst_in), // common 
							 .dclk(dclk), 
               .wreg_MEM_i(wreg_MEMWB_i), // inputs 
               .waddr_MEM_i(waddr_MEMWB_i), 
               .wdata_MEM_i(wdata_MEMWB_i), 
               .wreg_REGFILE_o(wreg_MEMWB_o), // down-stream 
               .waddr_REGFILE_o(waddr_MEMWB_o), 
               .wdata_REGFILE_o(wdata_MEMWB_o));

// Note these two ports have been defined in ID phase. 
// wire[31:0] rdata1_REGFILE_o; 
// wire[31:0] rdata2_REGFILE_o;
// assign rdata1_ID_i = rdata1_REGFILE_o; 
// assign rdata2_ID_i = rdata2_REGFILE_o; 

wire re1_REGFILE_i; // read enable
wire[4:0] raddr1_REGFILE_i; // read addr 
wire re2_REGFILE_i;
wire[4:0] raddr2_REGFILE_i;
assign re1_REGFILE_i = re1_ID_o; 
assign raddr1_REGFILE_i = raddr1_ID_o; 
assign re2_REGFILE_i = re2_ID_o; 
assign raddr2_REGFILE_i = raddr2_ID_o; 

wire we_REGFILE_i; 
wire[4:0] waddr_REGFILE_i; 
wire[31:0] wdata_REGFILE_i; 
wire[31:0] dbg_REGFILE_o; // debug signal assigned in the bottom 
assign we_REGFILE_i = wreg_MEMWB_o; 
assign waddr_REGFILE_i = waddr_MEMWB_o; 
assign wdata_REGFILE_i = wdata_MEMWB_o; 
REGFILE REGFILE0(.rst(rst_in), // common 
                 .dclk(dclk), 
                 .re1_ID_i(re1_REGFILE_i), // read access 
                 .raddr1_ID_i(raddr1_REGFILE_i), 
                 .rdata1_ID_o(rdata1_REGFILE_o), 
                 .re2_ID_i(re2_REGFILE_i), 
                 .raddr2_ID_i(raddr2_REGFILE_i),
                 .rdata2_ID_o(rdata2_REGFILE_o), 
                 .we_WB_i(we_REGFILE_i), // write access 
                 .waddr_WB_i(waddr_REGFILE_i), 
                 .wdata_WB_i(wdata_REGFILE_i), 
                 .dbg_CPU_o(dbg_REGFILE_o)); 

wire[31:0] addrIF_ARB_i; 
wire reMEM_ARB_i;
wire[31:0] raddrMEM_ARB_i; 
wire weMEM_ARB_i; 
wire[31:0] waddrMEM_ARB_i; 
wire[7:0] wdataMEM_ARB_i; 
assign addrIF_ARB_i = addr_IF_o; 
assign reMEM_ARB_i = re_MEM_o; 
assign raddrMEM_ARB_i = raddr_MEM_o; 
assign weMEM_ARB_i = we_MEM_o; 
assign waddrMEM_ARB_i = waddr_MEM_o; 
assign wdataMEM_ARB_i = wdata_MEM_o; 

wire[31:0] addr_ARB_o; 
wire[7:0] wdata_ARB_o; 
wire wr_ARB_o; 
wire stall_ARB_o; // feedback given to IF, assign back to IF 
assign stall_IF_i = stall_ARB_o; 
assign mem_wr = wr_ARB_o; // assign ram control signal to cpu output ports
assign mem_dout = wdata_ARB_o; 
assign mem_a = addr_ARB_o; 

RAM_ARBITRATOR RAM_ARBITRATOR0(.rst(rst_in), // common 
                               .addr_IF_i(addrIF_ARB_i), // IF inputs 
                               .re_MEM_i(reMEM_ARB_i), // MEM inputs 
                               .raddr_MEM_i(raddrMEM_ARB_i), 
                               .we_MEM_i(weMEM_ARB_i), 
                               .waddr_MEM_i(waddrMEM_ARB_i), 
                               .wdata_MEM_i(wdataMEM_ARB_i), 
                               .addr_RAM_o(addr_ARB_o), // ram control signal 
                               .wdata_RAM_o(wdata_ARB_o), 
                               .wr_RAM_o(wr_ARB_o), 
                               .stall_IF_o(stall_ARB_o)); 

wire rqID_STALLER_i; 
wire rqEX_STALLER_i; 
wire rqMEM_STALLER_i; // temporarily abandoned
wire[1:0] stlIF_STALLER_o; 
wire[1:0] stlIFID_STALLER_o; 
wire[1:0] stlIDEX_STALLER_o; 
wire[1:0] stlEXMEM_STALLER_o; 
assign rqID_STALLER_i = rq_ID_o; 
assign rqEX_STALLER_i = rq_EX_o; 
assign stl_IF_i = stlIF_STALLER_o; 
assign stl_IFID_i = stlIFID_STALLER_o; 
assign stl_IDEX_i = stlIDEX_STALLER_o; 
assign stl_EXMEM_i = stlEXMEM_STALLER_o; 
STALLER STALLER0(.rq_ID_i(rqID_STALLER_i), 
                 .rq_EX_i(rqEX_STALLER_i), 
                 .rq_MEM_i(rqMEM_STALLER_i), 
                 .stl_IF_o(stlIF_STALLER_o), 
                 .stl_IFID_o(stlIFID_STALLER_o), 
                 .stl_IDEX_o(stlIDEX_STALLER_o), 
                 .stl_EXMEM_o(stlEXMEM_STALLER_o)); 

assign dbgreg_dout = dbg_REGFILE_o; // assign debug output. 

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