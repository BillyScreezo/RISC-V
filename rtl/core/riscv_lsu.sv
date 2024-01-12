/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains RISC-V LSU module
 *
 ***********************************************************************************/

module riscv_lsu 

	import riscv_lsu_pkg::*;
	
#(
	int XLEN = 32
)(
	input 	logic 					clk_i,				// Core clock
	input 	logic 					rstn_i,				// Core reset

	// LSU port for interaction with the processor core
	input 	logic [XLEN-1:0] 		core_addr_i,		// Address of application to the PU
	input 	logic 					core_we_i,			// Permission to write to PU
	input 	logic [MSIZE_WIDTH-1:0] core_size_i,		// Data size when transferred between the core and the PU
	input 	logic [XLEN-1:0] 		core_wdata_i,		// Data to be recorded in PU
	input 	logic 					core_req_i,			// Request to PU
	output 	logic 					core_rvalid_o,		// Validity of data received from PU
	output 	logic [XLEN-1:0] 		core_rdata_o,		// Data from PU

	// LSU port for communication with peripheral devices
	input 	logic [XLEN-1:0] 		lsu_rdata_i,		// Data from PU
	output 	logic 					lsu_req_o,			// Request to PU
	output 	logic 					lsu_we_o,			// Permission to write to PU
	output 	logic [XLEN/8-1:0] 		lsu_be_o,			// Active bytes when writing/reading
	output 	logic [XLEN-1:0] 		lsu_addr_o,			// Address of application to the PU
	output 	logic [XLEN-1:0] 		lsu_wdata_o,		// Data to be recorded in PU

	output 	logic			 		unaligned_access_o,	// Unaligned memory access
	output 	logic 					lsu_stall_req_o
);

	lsu_state_t lsu_state;

  	always_ff @(posedge clk_i) begin
	    if(!rstn_i) begin
	      lsu_state <= LSU_IDLE;
	    end else begin
	       unique case (lsu_state)
	        LSU_IDLE: 
	          if(core_req_i && !core_we_i)
	            lsu_state <= LSU_LOAD;
	        LSU_LOAD:
	          if(core_rvalid_o)
	            lsu_state <= LSU_IDLE;
	       endcase
	    end
  	end

  	assign lsu_stall_req_o = (core_req_i && ~core_we_i) && ((lsu_state == LSU_IDLE) || ((lsu_state == LSU_LOAD) && ~core_rvalid_o));

	always_ff @(posedge clk_i) begin
		if (!rstn_i)
			core_rvalid_o <= '0;
		else if (core_rvalid_o)
			core_rvalid_o <= '0;
		else if (core_req_i && !core_we_i)
			core_rvalid_o <= '1;
	end

	always_comb begin
		lsu_addr_o 	= core_addr_i;
		lsu_req_o 	= core_req_i;
		lsu_we_o 	= core_we_i;

		(*full_case, parallel_case*) case (core_size_i[1:0])
			2'h0: begin
				lsu_wdata_o = {4{core_wdata_i[7:0]}};

				(*full_case, parallel_case*) case (core_addr_i[1:0])
					2'd0: begin
						core_rdata_o = { {24{lsu_rdata_i[7] & ~core_size_i[2]}}, lsu_rdata_i[7:0] };
						lsu_be_o = 4'b0001;
					end
					2'd1: begin
						core_rdata_o = { {24{lsu_rdata_i[15] & ~core_size_i[2]}}, lsu_rdata_i[15:8] };
						lsu_be_o = 4'b0010;
					end
					2'd2: begin
						core_rdata_o = { {24{lsu_rdata_i[23] & ~core_size_i[2]}}, lsu_rdata_i[23:16] };
						lsu_be_o = 4'b0100;
					end
					2'd3: begin
						core_rdata_o = { {24{lsu_rdata_i[31] & ~core_size_i[2]}}, lsu_rdata_i[31:24] };
						lsu_be_o = 4'b1000;
					end
				endcase
			end
			2'h1: begin
				lsu_wdata_o = {2{core_wdata_i[15:0]}};

				(*full_case, parallel_case*) case (core_addr_i[1:0])
					2'd0: begin
						core_rdata_o = { {16{lsu_rdata_i[15] & ~core_size_i[2]}}, lsu_rdata_i[15:0] };
						lsu_be_o = 4'b0011;
					end
					2'd2: begin
						core_rdata_o = { {16{lsu_rdata_i[31] & ~core_size_i[2]}}, lsu_rdata_i[31:16] };
						lsu_be_o = 4'b1100;
					end
				endcase
			end
			2'h2: begin
				lsu_wdata_o = core_wdata_i;
				core_rdata_o = lsu_rdata_i;
				lsu_be_o = 4'b1111;
			end
		endcase

		unaligned_access_o = 0;
	end

endmodule
