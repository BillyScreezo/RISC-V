/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains signed divider module
 *
 ***********************************************************************************/

`timescale 1ns/1ps
module tb_s_divider ();

	import riscv_mdu_pkg::*;

	// clock
	logic clk_i;
	initial begin
		clk_i = '0;
		forever #(0.5) clk_i = ~clk_i;
	end


	localparam N = 32;
	localparam M = 2*N;

	logic         clk_i;
	logic         rstn_i;
	logic         req_i;
	logic         rdy_o;
	logic   [N:0] ai;
	logic   [N:0] bi;
	logic [N-1:0] quotient_o;
	logic [N-1:0] remainder_o;
	logic         rem_op_i;
	logic         a_is_zero_i;
	logic         b_is_zero_i;

	s_divider inst_s_divider
		(
			.clk_i       (clk_i),
			.rstn_i      (rstn_i),
			.req_i       ('1),
			.rdy_o       (rdy_o),
			.mdu_op_i	 (3'd6),
			.ai          (ai),
			.bi          (bi),
			.quotient_o  (quotient_o),
			.remainder_o (remainder_o),
			.rem_op_i    ('0),
			.a_is_zero_i ('0),
			.b_is_zero_i ('0)
		);

	

	initial begin

		rstn_i <= '0;

		repeat(10)@(posedge clk_i); #3;

		rstn_i <= '1;

		ai <= -52352;
		bi <= -52;
		

		repeat(10)@(posedge clk_i);
		$finish;
	end

endmodule
