/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains RISC-V dualport RAM
 *
 ***********************************************************************************/

module riscv_dualport_ram #(
	int WIDTH 			= 32,
	int RAMSZ			= 64,
	string INIT_FILE 	= "none"
)(
	input 	logic 					clk,

	// port A
	input 	logic 					ena,
	input 	logic 					wea,
	input 	logic [(WIDTH/8)-1:0] 	bea,
	input 	logic [WIDTH-1:0] 		addra,
	input 	logic [WIDTH-1:0] 		dina,
	output 	logic [WIDTH-1:0] 		douta,

	// port B
	input 	logic 					enb,
	input 	logic [WIDTH-1:0] 		addrb,
	output 	logic [WIDTH-1:0] 		doutb
);

//  ===============================================================================================
//  ==================== Defines
//  ===============================================================================================

	localparam int RAMSZ_CELLS = RAMSZ * 1024 / 4;
	localparam int BYTE_OP = 2;

	// (*ram_decomp = "power"*)
	logic [WIDTH-1:0] mem [0:RAMSZ_CELLS-1];

	logic [WIDTH-BYTE_OP-1:0] w_addra, w_addrb;

	assign w_addra = addra[WIDTH-1:2];
	assign w_addrb = addrb[WIDTH-1:2];

//  ===============================================================================================
//  ==================== A-B port logic
//  ===============================================================================================

    initial begin
    	if(INIT_FILE != "none")
    		$readmemh(INIT_FILE, mem);
    	else
    		$display("Not set the init mem file");
    end

	generate
		for (genvar i = 0; i < WIDTH / 8; ++i) begin : byte_write
			always_ff @(posedge clk)
				if (ena && wea && bea[i])
					mem[w_addra][i*8 +: 8] <= dina[i*8 +: 8];
		end
	endgenerate

	always_ff @(posedge clk) begin
		if (ena)
			douta <= mem[w_addra];

		if (enb)
			doutb <= mem[w_addrb];
	end

endmodule
