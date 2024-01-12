/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains RISC-V control/starus registers
 *
 ***********************************************************************************/

module riscv_csr 

	import riscv_csr_pkg::*;

(
	input 	logic 						clk_i,		// Core clock
	input 	logic 						rstn_i,		// Core reset

	// CSR R/W
	input 	logic [CSR_OP_WIDTH-1:0] 	opcode_i,	// Operation CSR
	input 	logic [CSR_ADDR_WIDTH-1:0] 	addr_i,		// CSR Register Address
	input 	logic [MXLEN-1:0] 			din_i,		// Data to be written to CSR
	output 	logic [MXLEN-1:0] 			dout_o,		// Read data from CSR

	// CSR reg's
	input 	logic [MXLEN-1:0] 			mcause_i,	// Interrupt Reason Register
	input 	logic [MXLEN-1:0] 			pc_i,		// Current PC Register
	output 	logic [MXLEN-1:0] 			mie_o,		// Current PC Register
	output 	logic [MXLEN-1:0] 			mtvec_o,	// Interrupt handler vector register
	output 	logic [MXLEN-1:0] 			mepc_o,		// Saved PC Register

	input 	logic 						trap_i		// trap
);	
	
	localparam int TIM_WIDTH = 64;

	logic [MXLEN-1:0] mscratch, mcause;
	logic [TIM_WIDTH-1:0] cycle;

	always_ff @(posedge clk_i)
		if (!rstn_i)
			cycle <= '0;
		else
			cycle <= cycle + 1'b1;

	always_ff @(posedge clk_i) begin
		if (addr_i == S_MIE)
			mie_o <= mrw(opcode_i, mie_o, din_i);

		if (addr_i == S_MTVEC)
			mtvec_o <= mrw(opcode_i, mtvec_o, din_i);

		if (addr_i == S_MSCRATCH)
			mscratch <= mrw(opcode_i, mscratch, din_i);

		if (addr_i == S_MEPC)
			mepc_o <= mrw(opcode_i, mepc_o, din_i);

		if (trap_i) begin
			mepc_o <= pc_i;
			mcause <= mcause_i;
		end
	end

	always_comb
		(*full_case, parallel_case*) case (addr_i)
			S_MIE: 		dout_o = mie_o;
			S_MTVEC: 	dout_o = mtvec_o;
			S_MSCRATCH: dout_o = mscratch;
			S_MEPC: 	dout_o = mepc_o;
			S_MCAUSE: 	dout_o = mcause;
			S_TIM_LOW: 	dout_o = cycle[31:0];
			S_TIM_HIGH: dout_o = cycle[63:32];
		endcase

	function logic [MXLEN-1:0] mrw(input logic [CSR_OP_WIDTH-1:0] opcode_i, input logic [MXLEN-1:0] curr, next);
		unique case (opcode_i)
			2'b00: mrw = curr;
			2'b01: mrw = next;
			2'b10: mrw = curr & ~next;
			2'b11: mrw = curr | next;
		endcase
	endfunction

endmodule
