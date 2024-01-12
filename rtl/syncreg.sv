/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains asynchronous Input Synchronization
 *
 ***********************************************************************************/

module syncreg #(
	int SYNC_STAGES = 3,		// Integer value for number of synchronizing registers, must be 2 or higher
	int PIPELINE_STAGES = 0,	// Integer value for number of registers on the output of the
								// synchronizer for the purpose of improveing performance.
								// Particularly useful for high-fanout nets.
	bit INIT = 0				// Initial value of synchronizer registers upon startup, 1'b0 or 1'b1.
) (
	input logic clk,
	input logic async_in,
	output logic sync_out
);
 
	(* ASYNC_REG="TRUE" *) reg [SYNC_STAGES-1:0] sreg = {SYNC_STAGES{INIT}};
	
	always_ff @(posedge clk)
		sreg <= {sreg[SYNC_STAGES-2:0], async_in};
	
	generate if (PIPELINE_STAGES == 0) begin : no_pipeline
		
		assign sync_out = sreg[SYNC_STAGES-1];
	
	end else if (PIPELINE_STAGES == 1) begin : one_pipeline
	
		logic sreg_pipe = INIT;
	
		always_ff @(posedge clk)
			sreg_pipe <= sreg[SYNC_STAGES-1];
	
		assign sync_out = sreg_pipe;
	
	end else begin : multiple_pipeline
	
		(* shreg_extract = "no" *) logic [PIPELINE_STAGES-1:0] sreg_pipe = {PIPELINE_STAGES{INIT}};
	
		always_ff @(posedge clk)
			sreg_pipe <= {sreg_pipe[PIPELINE_STAGES-2:0], sreg[SYNC_STAGES-1]};
	
		assign sync_out = sreg_pipe[PIPELINE_STAGES-1];
	
	end endgenerate

endmodule


module syncreg_bus #(
	int WIDTH = 8,
	int SYNC_STAGES = 3,
	int PIPELINE_STAGES = 0
) (
	input logic clk,
	input logic [WIDTH-1:0] async_in,
	output logic [WIDTH-1:0] sync_out
);
 
	(* ASYNC_REG="TRUE" *) logic [SYNC_STAGES-1:0] sreg[WIDTH-1:0];

	always_ff @(posedge clk)
		for (int i = 0; i < WIDTH; i++)
			sreg[i] <= {sreg[i][SYNC_STAGES-2:0], async_in[i]};
	
	genvar i;

	generate if (PIPELINE_STAGES == 0) begin : no_pipeline

		for (i = 0; i < WIDTH; i++)
			assign sync_out[i] = sreg[i][SYNC_STAGES-1];
		
	end else if (PIPELINE_STAGES == 1) begin : one_pipeline

		logic [WIDTH-1:0] sreg_pipe;
	
		for (i = 0; i < WIDTH; i++)
			always_ff @(posedge clk)
				sreg_pipe[i] <= sreg[i][SYNC_STAGES-1];
	
		assign sync_out = sreg_pipe;

	end else begin : multiple_pipeline

		(* shreg_extract = "no" *) reg [PIPELINE_STAGES-1:0] sreg_pipe[WIDTH-1:0];

		for (i = 0; i < WIDTH; i++) begin
			always_ff @(posedge clk)
				sreg_pipe[i] <= {sreg_pipe[i][PIPELINE_STAGES-2:0], sreg[i][SYNC_STAGES-1]};
	
			assign sync_out[i] = sreg_pipe[i][PIPELINE_STAGES-1];
		end		

	end endgenerate

endmodule
