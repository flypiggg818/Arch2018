`include "macro.vh"

/**
  Although this module should be a combinational logic, since it is 
  driven by high-frequency clock, I make it a sequential FSM. 
  Follow the same 'word fetching' procedure in IF module.
  I suddenly find that I need EIGHT!!! clock cycle. 
  I give up in damn cycles. 
*/

/**
  An elegant combinational between combinational logic and sequential circuit. 
*/

/** 	Note that previously, the stall request is handled by arbitrator. 
		But now, when MEM is doing accessing, it issues STALL signal directly to STALLER. 
		Note that MEM can't be stalled, so a control line from STALLER is removed. 
*/
module MEMSHIT(
	input wire rst, 
	input wire clk, 
	
	input wire[`AluOpBus] aluop_EXMEM_i, 
	input wire wreg_EXMEM_i, 
	input wire[4:0] waddr_EXMEM_i, 
	input wire[31:0] alurslt_EXMEM_i, 
	input wire[31:0] SdataBoffset_EXMEM_i, // value stored in STORE inst, alurslt gives ram-address in this case. 
	// ram access signal 
	output reg[1:0] rw_RAMCTRL_o, // rw[1] for read, rw[0] for write. No read and write at the same time. 
	output reg[31:0] addr_RAMCTRL_o, // read / write address at the same time.  
	output reg[3:0] mask_RAMCTRL_o, 
	output reg[31:0] wdata_RAMCTRL_o, 
	input wire[31:0] rdata_RAMCTRL_i, 
	input wire[1:0] status_RAMCTRL_i,
	// signal requiring STALLER's pipeline stall control.  
	output wire reqstall_STALLER_o, 
	// downstream data flow signal 
	output reg wreg_MEMWB_o, 
	output reg[4:0] waddr_MEMWB_o, 
	output reg[31:0] wdata_MEMWB_o 
); 

	/*** signals related to ARBITRATOR ***/
	wire load = (aluop_EXMEM_i == `ALU_LB_OP)   || (aluop_EXMEM_i == `ALU_LH_OP)  || 
			  (aluop_EXMEM_i == `ALU_LBU_OP)  || (aluop_EXMEM_i == `ALU_LHU_OP) || 
			  (aluop_EXMEM_i == `ALU_LW_OP); 
	wire store = (aluop_EXMEM_i == `ALU_SB_OP)  || (aluop_EXMEM_i == `ALU_SH_OP) || 
			   (aluop_EXMEM_i == `ALU_SW_OP); 
	wire MEM_ACS = load || store; 
	reg finish; // indicator for exiting MEM phase. 

	// issue stall request immediately. 
	assign reqstall_STALLER_o = MEM_ACS && !finish; 
//	assign rw_RAMCTRL_o[1] = !rst && load && !finish; 
//	assign rw_RAMCTRL_o[0] = !rst && store && !finish; 

	// asynchronous non-blocking MEM phase access. No RAM IO involved.
	reg pending_wreg 				= 'b0; 
	reg[4:0] pending_waddr 	= 'b0; 
	reg[31:0] pending_wdata	= 'b0;
	
	/** block assign for wreg and waddr */
	always @ (*) begin 
		if (rst == `Enable || (MEM_ACS && !finish)) begin 
			wreg_MEMWB_o = pending_wreg; 
			waddr_MEMWB_o = pending_waddr; 
		end else begin 
			wreg_MEMWB_o = wreg_EXMEM_i; 
			waddr_MEMWB_o = waddr_EXMEM_i; 
		end 
	end 
	/** block assign for wdata, which is more complicated */
	// define load_buffer to avoid multiple-driver problem for wdata_MEMWB_o 
	reg[31:0] load_buffer; 
	always @ (*) begin 
		if (rst == `Enable || (MEM_ACS && !finish)) begin 
		  wdata_MEMWB_o = pending_wdata; 
		end else if (load && finish) 
		  wdata_MEMWB_o = load_buffer; 
		else if (store && finish) 
		  wdata_MEMWB_o = `ZeroWord;
		else 
		  wdata_MEMWB_o = alurslt_EXMEM_i; 
	end 
	/** block assign for mask */
	wire byte 			= (aluop_EXMEM_i == `ALU_LB_OP || aluop_EXMEM_i == `ALU_LBU_OP || aluop_EXMEM_i == `ALU_SB_OP);
	wire halfword 	= (aluop_EXMEM_i == `ALU_LH_OP || aluop_EXMEM_i == `ALU_LHU_OP || aluop_EXMEM_i == `ALU_SH_OP);   
	wire word 			= (aluop_EXMEM_i == `ALU_LW_OP || aluop_EXMEM_i == `ALU_SW_OP);
	always @ (*) begin 
		if (byte) 				mask_RAMCTRL_o = 4'b0001; 
		else if (halfword) 	mask_RAMCTRL_o = 4'b0011; 
		else if (word) 		mask_RAMCTRL_o = 4'b1111; 
		else 						mask_RAMCTRL_o = 4'b0000; 
	end 
	
	/*** After MEM_ACS is detected and stall request is issued, begin sequential RAM accessing ***/
	reg[4:0] FSM;
	localparam STATE_INIT = 5'h0; 
	localparam STATE_READ = 5'h1; 
	localparam  STATE_WRITE = 5'h2; 
	/** define extension control signal (for LOAD instruction) */
	wire signed_ext = (aluop_EXMEM_i == `ALU_LH_OP || aluop_EXMEM_i == `ALU_LB_OP); 
	wire unsigned_ext = (aluop_EXMEM_i == `ALU_LHU_OP || aluop_EXMEM_i == `ALU_LBU_OP);
	wire[4:0] signext_mask = {signed_ext, mask_RAMCTRL_o}; 
	always @ (posedge clk or posedge rst) begin 
		if (rst == `Enable) begin
			finish <= `Disable; 
			rw_RAMCTRL_o <= 2'b0; 
			addr_RAMCTRL_o <= 32'b0; 
			mask_RAMCTRL_o <= 4'b0; 
			wdata_RAMCTRL_o <= 32'b0;
			FSM <= STATE_INIT; 
		end else begin 
			case (FSM) 
				STATE_INIT: begin 
					/** Note that, when we have finished accessing memory, we will lift up finish signal. But 
						at the very next clock cycle, instruction remains unchanged because control signal needs one 
						extra clock cycle to reach, thus we should avoid do MEM access again. 
					*/
					finish <= `Disable; 
					if (load) begin 
						rw_RAMCTRL_o <= 2'b10;
						addr_RAMCTRL_o <= alurslt_EXMEM_i;  
						FSM <= STATE_READ; 
					end else if (store) begin 
						rw_RAMCTRL_o <= 2'b01; 
						addr_RAMCTRL_o <= alurslt_EXMEM_i;
						wdata_RAMCTRL_o <= SdataBoffset_EXMEM_i;   
						FSM <= STATE_WRITE; 
					end else begin 
						rw_RAMCTRL_o <= 2'b0; 
						addr_RAMCTRL_o <= `ZeroWord; 
						wdata_RAMCTRL_o <= `ZeroWord;
					end 
				end
				STATE_WRITE: begin
					// TODO: specify which statuses are needed. 
					FSM <= (status_RAMCTRL_i) ? STATE_INIT : STATE_WRITE; 
					finish <= (status_RAMCTRL_i) ? `Enable : `Disable; 
				end 
				STATE_READ: begin 
					FSM <= (status_RAMCTRL_i) ? STATE_INIT : STATE_WRITE; 
					finish <= (status_RAMCTRL_i) ? `Enable : `Disable; 
					// further do various extension modification. 
					case(signext_mask) 
						5'b10001: begin // one-byte signed extension 
							load_buffer[7:0] <= rdata_RAMCTRL_i[7:0]; 
							load_buffer[31:8] <= {24{rdata_RAMCTRL_i[7]}}; 
						end 
						5'b10011: begin // half-word signed extension 
							load_buffer[15:0] <= rdata_RAMCTRL_i[15:0]; 
							load_buffer[31:16] <= {16{rdata_RAMCTRL_i[15]}}; 
						end 
						default: begin
							load_buffer <= rdata_RAMCTRL_i; 
						end 
					endcase 
				end  
			endcase 
		end 
	end 
	
//  always @ (posedge clk or posedge rst) begin 
//    if (rst == `Enable || stl_STALLER_i == `STALL) begin
//      finish = `Disable; 
//      FSM = 5'b00000; 
//      load_buffer = `ZeroWord; 
//      raddr_RAM_o = `NopRegAddr; 
//      waddr_RAM_o = `NopRegAddr; 
//      wdata_RAM_o = 8'b0; 
//    end else begin
//      case (FSM) 
//        5'b00000: begin // have the right to do memory access. 
//          /** Note that, when we have finished accessing memory, we will lift up finish signal. But 
//              at the very next clock cycle, instruction remains unchanged because control signal needs one 
//              extra clock cycle to reach, thus we should avoid do MEM access again. 
//          */
//          if (load == `Enable && !finish) begin 
//            raddr_RAM_o = alurslt_EXMEM_i; 
//            FSM = 5'b00001; 
//          end else if (store == `Enable && !finish) begin 
//            waddr_RAM_o = alurslt_EXMEM_i; 
//            wdata_RAM_o = SdataBoffset_EXMEM_i[7:0];  
//            FSM = 5'b10001; 
//          end else begin 
//            raddr_RAM_o = `ZeroWord; 
//            waddr_RAM_o = `ZeroWord; 
//            wdata_RAM_o = `ZeroWord; 
//          end // if not store nor load, do nothing 
//          finish = `Disable; 
//          load_buffer = `ZeroWord; 
//        end 
//        5'b00001: begin // $(0) is being pushed onto bus 
//          FSM = 5'b00010; 
//        end 
//        5'b00010: begin // $(1) is being pushed onto bus 
//          load_buffer[7:0] = rdata_RAM_i; 
//          if (load_byte == `Enable) begin 
//            load_buffer[31:8] = (signed_ext == `Enable) ? {24{load_buffer[7]}} : 24'b0; 
//            finish = `Enable; 
//            FSM = 5'b00000; 
//          end else begin 
//            raddr_RAM_o = raddr_RAM_o + 32'b1; 
//            FSM = 5'b00011; 
//          end 
//        end 
//        5'b00011: begin 
//          FSM = 5'b00100; 
//        end 
//        5'b00100: begin 
//          load_buffer[15:8] = rdata_RAM_i; 
//          if (load_halfword == `Enable) begin 
//            load_buffer[31:16] = (signed_ext == `Enable) ? {16{load_buffer[15]}} : 16'b0; 
//            finish = `Enable; 
//            FSM = 5'b00000; 
//          end else begin 
//            raddr_RAM_o = raddr_RAM_o + 32'b1; 
//            FSM = 5'b00101; 
//          end 
//        end 
//        5'b00101: begin 
//          FSM = 5'b00110; 
//        end 
//        5'b00110: begin 
//          load_buffer[23:16] = rdata_RAM_i;
//          raddr_RAM_o = raddr_RAM_o + 32'b1; 
//          FSM = 5'b00111; 
//        end   
//        5'b00111: begin
//          FSM = 5'b01000; 
//        end 
//        5'b01000: begin 
//          load_buffer[31:24] = rdata_RAM_i;
//          finish = `Enable; 
//          raddr_RAM_o = `ZeroWord; 
//          FSM = 5'b00000; 
//        end 
//        5'b10001: begin 
//          if (aluop_EXMEM_i == `ALU_SB_OP) begin 
//            finish = `Enable; 
//            FSM = 5'b00000; 
//          end else begin 
//            waddr_RAM_o = waddr_RAM_o + 32'b1; 
//            wdata_RAM_o = SdataBoffset_EXMEM_i[15:8]; 
//            FSM = 5'b10010; 
//          end 
//        end 
//        5'b10010: begin 
//          if (aluop_EXMEM_i == `ALU_SH_OP) begin 
//            finish = `Enable; 
//            FSM = 5'b00000; 
//          end else begin 
//            waddr_RAM_o = waddr_RAM_o + 32'b1; 
//            wdata_RAM_o = SdataBoffset_EXMEM_i[23:16]; 
//            FSM = 5'b10011; 
//          end
//        end 
//        5'b10011: begin 
//          waddr_RAM_o = waddr_RAM_o + 32'b1; 
//          wdata_RAM_o = SdataBoffset_EXMEM_i[31:24]; 
//          FSM = 5'b10100; 
//        end 
//        5'b10100: begin 
//          finish = `Enable; 
//          waddr_RAM_o = `ZeroWord; 
//          wdata_MEMWB_o = `ZeroWord; 
//          FSM = 5'b00000; 
//        end 
//        default: begin 
//        end 
//      endcase 
//    end
//  end 
endmodule 