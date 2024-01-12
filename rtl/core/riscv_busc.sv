/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains slave selection and slave's data multiplexing
 *
 ***********************************************************************************/

module riscv_busc #(
	int XLEN = 32,
	int NSLAVES = 2
)(
	input 	logic 					clk,

	input 	logic [XLEN-1:0] 		addr_i,
	output 	logic [NSLAVES-1:0]		sel_o,
	input 	logic [XLEN-1:0] 		rdata_i 	[0:NSLAVES-1],
	output 	logic [XLEN-1:0] 		rdata_o
);
	
	localparam int SLV_START_IDX = 28;

	assign sel_o = (1 << addr_i[SLV_START_IDX +: $clog2(NSLAVES)]);		// slave select

	assign rdata_o = rdata_i[addr_i[SLV_START_IDX +: $clog2(NSLAVES)]];	// rdata mux

endmodule
