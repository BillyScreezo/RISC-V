/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains GPIO module
 *
 ***********************************************************************************/

module riscv_gpio #(
	int XLEN 	= 32,
	int WIDTH 	= 32
) (
	input 	logic 				clk,
	input 	logic 				rstn,

	input 	logic 				sel,
	input 	logic 				enable,
	input 	logic 				write,
	input 	logic [XLEN-1:0] 	addr,
	input 	logic [XLEN-1:0] 	wdata,
	output 	logic [XLEN-1:0] 	rdata,

	output 	logic [WIDTH-1:0] 	gpio_o,
	input 	logic [WIDTH-1:0] 	gpio_i
);

//  ===============================================================================================
//  ==================== Defines
//  ===============================================================================================

	localparam int ADDR_LOW_WIDTH = 12;
	localparam bit [ADDR_LOW_WIDTH-1:0] ADDR_WR = 12'h000;

//  ===============================================================================================
//  ==================== R/W logic
//  ===============================================================================================
	always_ff @(posedge clk)
		if (!rstn)
			gpio_o <= '0;
		else if (sel && enable && write && addr[ADDR_LOW_WIDTH-1:0] == ADDR_WR)
			gpio_o <= wdata;

	assign rdata = gpio_i;

endmodule
