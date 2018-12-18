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

wire[1:0] stl_IF_i; // common
wire re_IF_o;  
wire[31:0] addr_IF_o; // cache access 
wire[31:0] data_IF_i; 
wire miss_IF_i; 
wire JBjeID_IF_i; 
wire[31:0] JBtaraddrID_IF_i;
wire[31:0] inst_IF_o; 
wire[31:0] pc_IF_o; 
IF IF0(.clk(clk_in), // common 
       .rst(rst_in),
       .stl_STALLER_i(stl_IF_i),
       // cache_access 
       .re_CACHE_o(re_IF_o), 
       .addr_CACHE_o(addr_IF_o), 
       .data_CACHE_i(data_IF_i), 
       .miss_CACHE_i(miss_IF_i), 
       .JBje_ID_i(JBjeID_IF_i), 
       .JBtaraddr_ID_i(JBtaraddrID_IF_i), 
       .inst_IFID_o(inst_IF_o), 
       .pc_IFID_o(pc_IF_o)); // down-stream 

wire[31:0] inst_IFID_i; 
wire[1:0] stl_IFID_i; 
wire[31:0] pc_IFID_i; 
assign pc_IFID_i = pc_IF_o; 
assign inst_IFID_i = inst_IF_o; 
wire[31:0] inst_IFID_o; 
wire[31:0] pc_IFID_o; 
IF_ID IF_ID0(.clk(clk_in), // common 
             .rst(rst_in), 
             .stl_STALLER_i(stl_IFID_i),  
             .inst_IF_i(inst_IFID_i), 
             .pc_IF_i(pc_IFID_i), // pass pc for jump
             .inst_ID_o(inst_IFID_o), // down-stream
             .pc_ID_o(pc_IFID_o)); 

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
wire[31:0] SdataBoffset_ID_o; 
wire[1:0] rq_ID_o; 
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
wire[31:0] pc_ID_i; 

wire[31:0] JBtaraddr_ID_o; // branch signals 
wire JBje_ID_o; 
wire[31:0] pc_ID_o; 
assign JBjeID_IF_i = JBje_ID_o; 
assign JBtaraddrID_IF_i = JBtaraddr_ID_o; 
assign pc_ID_i = pc_IFID_o; // pc signal 
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
       .pc_IFID_i(pc_ID_i), 
       .JBje_IF_o(JBje_ID_o), 
       .JBtaraddr_IF_o(JBtaraddr_ID_o), // jump signals 
       .aluop_IDEX_o(aluop_ID_o), // decode results
       .alusel_IDEX_o(alusel_ID_o), 
       .regdata1_IDEX_o(regdata1_ID_o), 
       .regdata2_IDEX_o(regdata2_ID_o), 
       .wreg_IDEX_o(wreg_ID_o), 
       .waddr_IDEX_o(waddr_ID_o), 
       .SdataBoffset_IDEX_o(SdataBoffset_ID_o), 
       .rq_STALLER_o(rq_ID_o), 
       .pc_IDEX_o(pc_ID_o)); 


wire[`AluOpBus] aluop_IDEX_i; 
wire[`AluSelBus] alusel_IDEX_i; 
wire[31:0] regdata1_IDEX_i; 
wire[31:0] regdata2_IDEX_i; 
wire wreg_IDEX_i; 
wire[4:0] waddr_IDEX_i;
wire[31:0] SdataBoffset_IDEX_i; 
wire[1:0] stl_IDEX_i; 
wire[31:0] pc_IDEX_i;
assign pc_IDEX_i = pc_ID_o; 
assign aluop_IDEX_i = aluop_ID_o; 
assign alusel_IDEX_i = alusel_ID_o; 
assign regdata1_IDEX_i = regdata1_ID_o; 
assign regdata2_IDEX_i = regdata2_ID_o; 
assign wreg_IDEX_i = wreg_ID_o; 
assign waddr_IDEX_i = waddr_ID_o; 
assign SdataBoffset_IDEX_i = SdataBoffset_ID_o; 

wire[`AluOpBus] aluop_IDEX_o; 
wire[`AluSelBus] alusel_IDEX_o; 
wire[31:0] regdata1_IDEX_o; 
wire[31:0] regdata2_IDEX_o; 
wire wreg_IDEX_o; 
wire[4:0] waddr_IDEX_o; 
wire[31:0] SdataBoffset_IDEX_o; 
wire[31:0] pc_IDEX_o;  
ID_EX ID_EX0(.rst(rst_in), // common 
             .clk(clk_in), 
             .aluop_ID_i(aluop_IDEX_i), // inputs 
             .alusel_ID_i(alusel_IDEX_i),
             .regdata1_ID_i(regdata1_IDEX_i), 
             .regdata2_ID_i(regdata2_IDEX_i), 
             .wreg_ID_i(wreg_IDEX_i), 
             .waddr_ID_i(waddr_IDEX_i),
             .SdataBoffset_ID_i(SdataBoffset_IDEX_i),
             .stl_STALLER_i(stl_IDEX_i), 
             .pc_ID_i(pc_IDEX_i), 
             .aluop_EX_o(aluop_IDEX_o), // down-stream 
             .alusel_EX_o(alusel_IDEX_o), 
             .regdata1_EX_o(regdata1_IDEX_o), 
             .regdata2_EX_o(regdata2_IDEX_o), 
             .wreg_EX_o(wreg_IDEX_o), 
             .waddr_EX_o(waddr_IDEX_o), 
             .SdataBoffset_EX_o(SdataBoffset_IDEX_o), 
             .pc_EX_o(pc_IDEX_o)); 


wire[`AluOpBus] aluop_EX_i;  
wire[`AluSelBus] alusel_EX_i;  
wire[31:0] regdata1_EX_i;  
wire[31:0] regdata2_EX_i; 
wire wreg_EX_i; 
wire[4:0] waddr_EX_i; 
wire[31:0] SdataBoffset_EX_i; 
wire[31:0] pc_EX_i; 
assign pc_EX_i = pc_IDEX_o; 
assign aluop_EX_i = aluop_IDEX_o; 
assign alusel_EX_i = alusel_IDEX_o; 
assign regdata1_EX_i = regdata1_IDEX_o; 
assign regdata2_EX_i = regdata2_IDEX_o; 
assign wreg_EX_i = wreg_IDEX_o; 
assign waddr_EX_i = waddr_IDEX_o; 
assign SdataBoffset_EX_i = SdataBoffset_IDEX_o; 

wire wreg_EX_o; // downstream signals
wire[4:0] waddr_EX_o; 
wire[31:0] alurslt_EX_o; 
wire[31:0] SdataBoffset_EX_o; 
wire[`AluOpBus] aluop_EX_o; 
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
       .SdataBoffset_IDEX_i(SdataBoffset_EX_i),
       .pc_IDEX_i(pc_EX_i),   
       .aluop_EXMEM_o(aluop_EX_o), // results 
       .wreg_EXMEM_o(wreg_EX_o),
       .waddr_EXMEM_o(waddr_EX_o), 
       .alurslt_EXMEM_o(alurslt_EX_o), 
       .SdataBoffset_EXMEM_o(SdataBoffset_EX_o)); 


wire[`AluOpBus] aluop_EXMEM_i; 
wire wreg_EXMEM_i; 
wire[4:0] waddr_EXMEM_i; 
wire[31:0] alurslt_EXMEM_i;
wire[31:0] SdataBoffset_EXMEM_i; 
wire[1:0] stl_EXMEM_i; 
assign aluop_EXMEM_i = aluop_EX_o; 
assign wreg_EXMEM_i = wreg_EX_o;  
assign waddr_EXMEM_i = waddr_EX_o; 
assign alurslt_EXMEM_i = alurslt_EX_o; 
assign SdataBoffset_EXMEM_i = SdataBoffset_EX_o; 

wire[`AluOpBus] aluop_EXMEM_o; 
wire wreg_EXMEM_o;
wire[4:0] waddr_EXMEM_o; 
wire[31:0] alurslt_EXMEM_o; 
wire[31:0] SdataBoffset_EXMEM_o; 
EX_MEM EX_MEM0(.rst(rst_in), // common
               .clk(clk_in), 
               .aluop_EX_i(aluop_EXMEM_i), 
               .wreg_EX_i(wreg_EXMEM_i), // inputs 
               .waddr_EX_i(waddr_EXMEM_i), 
               .alurslt_EX_i(alurslt_EXMEM_i),
               .SdataBoffset_EX_i(SdataBoffset_EXMEM_i), 
               .stl_STALLER_i(stl_EXMEM_i), 
               .aluop_MEM_o(aluop_EXMEM_o), // down-stream 
               .wreg_MEM_o(wreg_EXMEM_o), 
               .waddr_MEM_o(waddr_EXMEM_o), 
               .alurslt_MEM_o(alurslt_EXMEM_o), 
               .SdataBoffset_MEM_o(SdataBoffset_EXMEM_o)); 

// assign MEM input 
wire[`AluOpBus] aluop_MEM_i; 
wire wreg_MEM_i; 
wire[4:0] waddr_MEM_i; 
wire[31:0] alurslt_MEM_i; 
wire[31:0] SdataBoffset_MEM_i; 
assign aluop_MEM_i = aluop_EXMEM_o; 
assign wreg_MEM_i = wreg_EXMEM_o; 
assign waddr_MEM_i = waddr_EXMEM_o; 
assign alurslt_MEM_i = alurslt_EXMEM_o; 
assign SdataBoffset_MEM_i = SdataBoffset_EXMEM_o; 

// ram access signal issued by MEM 
wire re_MEM_o; 
wire[31:0] addr_MEM_o; 
wire[7:0] raddr_MEM_i; 
wire we_MEM_o; 
wire[7:0] wdata_MEM_o; 
// downstream signal 
wire wreg_MEM_o; 
wire[4:0] wbaddr_MEM_o; 
wire[31:0] wbdata_MEM_o;
wire[1:0]  stl_MEM_i; 
// assign fwregMEM_ID_i = wreg_MEM_o; // wrong!!!
// assign fwaddrMEM_ID_i = wbaddr_MEM_o; // wrong!!!
assign fwregMEM_ID_i = wreg_EXMEM_o; 
assign fwaddrMEM_ID_i = waddr_EXMEM_o; 
assign fwdataMEM_ID_i = wbdata_MEM_o; 
MEM MEM0(.rst(rst_in), // common
         .clk(clk_in), 
         // consider rdy signal 
         .stl_CTRL_i(stl_MEM_i), 
         .aluop_EXMEM_i(aluop_MEM_i), // inputs
         .wreg_EXMEM_i(wreg_MEM_i), 
         .waddr_EXMEM_i(waddr_MEM_i), 
         .alurslt_EXMEM_i(alurslt_MEM_i), 
         .SdataBoffset_EXMEM_i(SdataBoffset_MEM_i), 
         // ram access signal 
         .re_CTRL_o(re_MEM_o), 
         .addr_CTRL_o(addr_MEM_o), 
         .rdata_RAM_i(mem_din), 
         .we_CTRL_o(we_MEM_o), 
         .wdata_CTRL_o(wdata_MEM_o), 
         // down-stream flow 
         .wreg_MEMWB_o(wreg_MEM_o), 
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
							 .clk(clk_in), 
               .wreg_MEM_i(wreg_MEMWB_i), // inputs 
               .waddr_MEM_i(waddr_MEMWB_i), 
               .wdata_MEM_i(wdata_MEMWB_i), 
               .wreg_REGFILE_o(wreg_MEMWB_o), // down-stream 
               .waddr_REGFILE_o(waddr_MEMWB_o), 
               .wdata_REGFILE_o(wdata_MEMWB_o));

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
                 .clk(clk_in), 
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

// signals from IF to CACHE 
wire re_CACHE_i; 
wire[31:0] addr_CACHE_i; 
wire[31:0] data_CACHE_o; 
wire miss_CACHE_o;
assign re_CACHE_i = re_IF_o; 
assign addr_CACHE_i = addr_IF_o; 
assign data_IF_i = data_CACHE_o; 
assign miss_IF_i = miss_CACHE_o; 
// signals with CTRL 
wire re_CACHE_o; 
wire[31:0] addr_CACHE_o; 
wire[1:0] stl_CACHE_i; 
ICACHE ICACHE0( // common
			 .clk(clk_in), 
			 .rst(rst_in), 
			 // signals with IF 
			 .re_IF_i(re_CACHE_i), 
			 .addr_IF_i(addr_CACHE_i), 
			 .data_IF_o(data_CACHE_o), 
			 .miss_IF_o(miss_CACHE_o), 
			 // signals with RAMCTRL 
			 .re_CTRL_o(re_CACHE_o), 
			 .addr_CTRL_o(addr_CACHE_o), 
			 .data_RAM_i(mem_din), 
       .stl_CTRL_i(stl_CACHE_i)
); 

// signals sent to cache 
wire re_cache_CTRL_i; 
wire[31:0] addr_cache_CTRL_i; 
assign re_cache_CTRL_i = re_CACHE_o; 
assign addr_cache_CTRL_i = addr_CACHE_o; 
// signals sent to mem
wire re_mem_CTRL_i; 
wire we_mem_CTRL_i; 
wire[31:0] addr_mem_CTRL_i; 
wire[7:0] wdata_mem_CTRL_i;
assign re_mem_CTRL_i = re_MEM_o; 
assign we_mem_CTRL_i = we_MEM_o; 
assign addr_mem_CTRL_i = addr_MEM_o; 
assign wdata_mem_CTRL_i = wdata_MEM_o; 
CTRL CTRL0(.rst(rst_in), 
           // ram control  
           .re_CACHE_i(re_cache_CTRL_i), // CACHE side
           .addr_CACHE_i(addr_cache_CTRL_i),
           .re_MEM_i(re_mem_CTRL_i), // MEM side 
           .addr_MEM_i(addr_mem_CTRL_i), 
           .we_MEM_i(we_mem_CTRL_i), 
           .wdata_MEM_i(wdata_mem_CTRL_i), 
           .wr_RAM_o(mem_wr), 
           .addr_RAM_o(mem_a), 
           .wdata_RAM_o(mem_dout), 
           // staller 
           .rdy(rdy_in), // break our naming convension
           .rq_ID_i(rq_ID_o), 
           .stl_IF_o(stl_IF_i), 
           .stl_IFID_o(stl_IFID_i), 
           .stl_IDEX_o(stl_IDEX_i), 
           .stl_EXMEM_o(stl_EXMEM_i), 
           .stl_MEM_o(stl_MEM_i), 
           .stl_CACHE_o(stl_CACHE_i)
); 

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
