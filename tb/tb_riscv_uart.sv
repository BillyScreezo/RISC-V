/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains UART tb
 *
 ***********************************************************************************/

`timescale 1ns/1ps
module tb_riscv_uart ();

	localparam int CLK_PERIOD = 20;
	localparam int XLEN = 32;

	// clock
	logic clk;
	initial begin
		clk = '0;
		forever #(CLK_PERIOD/2) clk = ~clk;
	end

	logic            rstn;
	logic            sel;
	logic            enable;
	logic            write;
	logic [XLEN-1:0] addr;
	logic [XLEN-1:0] wdata;
	logic [XLEN-1:0] rdata;
	logic            txd;
	logic            rxd;

	riscv_uart #(.SCALER(2604))

	inst_riscv_uart
		(
			.clk    (clk),
			.rstn   (rstn),
			.sel    (sel),
			.enable (enable),
			.write  (write),
			.addr   (addr),
			.wdata  (wdata),
			.rdata  (rdata),
			.txd    (txd),
			.rxd    (rxd)
		);

	task init();
		rstn   <= '0;
		sel    <= '0;
		enable <= '0;
		write  <= '0;
		addr   <= '0;
		wdata  <= '0;
		rxd    <= '0;
	endtask

	initial begin

		init();
		repeat(10)@(posedge clk);

		rstn <= '1;

		sel 	<= '1;
		enable	<= '1;
		write 	<= '1;
		addr 	<= 12'h004;

		wdata 	<= 8'hA5;

		repeat(1)@(posedge clk);

		sel 	<= '0;
		enable	<= '0;
		write 	<= '0;

		// $finish;
	end
	
endmodule
