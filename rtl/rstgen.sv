/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains rst generator
 *
 ***********************************************************************************/

module rstgen #(
	parameter ACTIVE_HIGH = 0,
	parameter RESET_STAGES = 5,
	parameter SYNCREG = 0
) (
	input rstin,
	input clk,
	input clklock,
	output logic rstout = 1'b1,
	output rstoutraw
);

	logic rstin_sync, clklock_sync;
	wire rstin_active = (ACTIVE_HIGH == 1) ? rstin : ~rstin;
	
	assign rstoutraw = rstin_active;

	generate
		if (SYNCREG == 0) begin : resync

			syncreg #(.INIT(ACTIVE_HIGH))
				syncreg_rstin (.clk(clk), .async_in(rstin_active), .sync_out(rstin_sync));

			syncreg #(.INIT(1'b0))
				syncreg_lock (.clk(clk), .async_in(clklock), .sync_out(clklock_sync));

		end else begin : no_resync
			
			assign rstin_sync = rstin_active;
			assign clklock_sync = clklock;
		end
	endgenerate

	(* shreg_extract = "no" *) reg [RESET_STAGES-1:0] shreg_rst = {RESET_STAGES{1'b1}};

	always @(posedge clk) begin
		if (rstin_sync) begin
			shreg_rst <= {RESET_STAGES{1'b1}};
			rstout <= 1'b1;
		end else begin
			shreg_rst <= {shreg_rst[RESET_STAGES-2:0], ~clklock_sync};
			rstout <= |shreg_rst;
		end
	end

endmodule
