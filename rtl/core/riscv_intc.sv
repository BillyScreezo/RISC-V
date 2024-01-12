/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains RISC-V interrupt's controller block
 *
 ***********************************************************************************/

module riscv_intc 

	import riscv_csr_pkg::MXLEN;
	import riscv_intc_pkg::NUMINT;
	
(
	input 	logic 				clk_i,					// Core clock
	input 	logic 				rstn_i,					// Core reset

	input 	logic 				irq_rst_i,				// Resetting an interrupt request to the kernel
	output 	logic 				irq_o,					// Generating a kernel interrupt
	output 	logic [MXLEN-1:0] 	cause_o,				// Reason for interruption

	input 	logic 				en_ext_i,				// Enable external interrupts (not from the kernel)
	input 	logic [NUMINT-1:0] 	ext_int_i,				// External interrupt requests (not from the kernel)

	input 	logic 				illegal_instr_i,		// Unsupported instruction flag
	input 	logic 				misalig_acc_i,			// Unaligned Memory Access Flag
	input 	logic 				ecall_i					// Flag env call
);

	logic pre_irq;

	always_comb begin
		pre_irq = '0;
		cause_o = '0;

		if (illegal_instr_i) begin
			cause_o = 'd2;
		end else if (misalig_acc_i) begin
			cause_o = 'd4;
		end else if (ecall_i) begin
			cause_o = 'd11;
		end else if (en_ext_i && |ext_int_i) begin
			cause_o = 32'h80000010 + priority_encode(ext_int_i);
			pre_irq = '1;
		end
	end


	always_ff @(posedge clk_i)
        if (!rstn_i)
            irq_o <= '0;
        else if (pre_irq)
            irq_o <= '1;
        else if (irq_rst_i)
            irq_o <= '0;


	function logic [$clog2(NUMINT)-1:0] priority_encode(input logic [NUMINT-1:0] value);
		priority_encode = '0;

		for (int i = NUMINT-1; i >= 0; --i)
			if (value[i])
				priority_encode = i;
	endfunction

endmodule
