/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains RISC-V imm module
 *
 ***********************************************************************************/

module riscv_imm #(
	int XLEN = 32
)(
	input 	logic [XLEN-1:0] 	instr_i,
	output 	logic [XLEN-1:0] 	imm_o
);

	import riscv_decoder_pkg::*;

    always_comb
		(*parallel_case*) case (instr_i[6:2]) inside
			OP_IMM, LOAD, JALR:
						imm_o[0] = instr_i[20];
			STORE:
						imm_o[0] = instr_i[7];
			default: 	imm_o[0] = 1'b0;
		endcase

	always_comb 
		(*parallel_case*) case (instr_i[6:2]) inside
			STORE, BRANCH:
						imm_o[1] = instr_i[8];
			LUI, AUIPC:
						imm_o[1] = 1'b0;
			default: 	imm_o[1] = instr_i[21];
		endcase

	always_comb
		(*parallel_case*) case (instr_i[6:2]) inside
			STORE, BRANCH:
						imm_o[2] = instr_i[9];
			LUI, AUIPC:
						imm_o[2] = 1'b0;
			default: 	imm_o[2] = instr_i[22];
		endcase

	always_comb
		(*parallel_case*) case (instr_i[6:2]) inside
			STORE, BRANCH:
						imm_o[3] = instr_i[10];
			LUI, AUIPC:
						imm_o[3] = 1'b0;
			default: 	imm_o[3] = instr_i[23];
		endcase

	always_comb
		(*parallel_case*) case (instr_i[6:2]) inside
			STORE, BRANCH:
						imm_o[4] = instr_i[11];
			LUI, AUIPC:
						imm_o[4] = 1'b0;
			default: 	imm_o[4] = instr_i[24];
		endcase

	assign imm_o[5]  = (instr_i[6:2] == LUI || instr_i[6:2] == AUIPC) ? 1'b0 : instr_i[25];

	assign imm_o[6]  = (instr_i[6:2] == LUI || instr_i[6:2] == AUIPC) ? 1'b0 : instr_i[26];

	assign imm_o[7]  = (instr_i[6:2] == LUI || instr_i[6:2] == AUIPC) ? 1'b0 : instr_i[27];

	assign imm_o[8]  = (instr_i[6:2] == LUI || instr_i[6:2] == AUIPC) ? 1'b0 : instr_i[28];

	assign imm_o[9]  = (instr_i[6:2] == LUI || instr_i[6:2] == AUIPC) ? 1'b0 : instr_i[29];

	assign imm_o[10] = (instr_i[6:2] == LUI || instr_i[6:2] == AUIPC) ? 1'b0 : instr_i[30];

	always_comb
		(*parallel_case*) case (instr_i[6:2]) inside
			BRANCH:
						imm_o[11] = instr_i[7];
			LUI, AUIPC:
						imm_o[11] = 1'b0;
			JAL:
						imm_o[11] = instr_i[20];
			default: 	imm_o[11] = instr_i[31];
		endcase

	assign imm_o[12] = (instr_i[6:2] == LUI || instr_i[6:2] == AUIPC || instr_i[6:2] == JAL) ? instr_i[12] : instr_i[31];

	assign imm_o[13] = (instr_i[6:2] == LUI || instr_i[6:2] == AUIPC || instr_i[6:2] == JAL) ? instr_i[13] : instr_i[31];

	assign imm_o[14] = (instr_i[6:2] == LUI || instr_i[6:2] == AUIPC || instr_i[6:2] == JAL) ? instr_i[14] : instr_i[31];

	assign imm_o[15] = (instr_i[6:2] == LUI || instr_i[6:2] == AUIPC || instr_i[6:2] == JAL) ? instr_i[15] : instr_i[31];

	assign imm_o[16] = (instr_i[6:2] == LUI || instr_i[6:2] == AUIPC || instr_i[6:2] == JAL) ? instr_i[16] : instr_i[31];

	assign imm_o[17] = (instr_i[6:2] == LUI || instr_i[6:2] == AUIPC || instr_i[6:2] == JAL) ? instr_i[17] : instr_i[31];

	assign imm_o[18] = (instr_i[6:2] == LUI || instr_i[6:2] == AUIPC || instr_i[6:2] == JAL) ? instr_i[18] : instr_i[31];

	assign imm_o[19] = (instr_i[6:2] == LUI || instr_i[6:2] == AUIPC || instr_i[6:2] == JAL) ? instr_i[19] : instr_i[31];

	assign imm_o[20] = (instr_i[6:2] == LUI || instr_i[6:2] == AUIPC) ? instr_i[20] : instr_i[31];

	assign imm_o[21] = (instr_i[6:2] == LUI || instr_i[6:2] == AUIPC) ? instr_i[21] : instr_i[31];

	assign imm_o[22] = (instr_i[6:2] == LUI || instr_i[6:2] == AUIPC) ? instr_i[22] : instr_i[31];

	assign imm_o[23] = (instr_i[6:2] == LUI || instr_i[6:2] == AUIPC) ? instr_i[23] : instr_i[31];

	assign imm_o[24] = (instr_i[6:2] == LUI || instr_i[6:2] == AUIPC) ? instr_i[24] : instr_i[31];

	assign imm_o[25] = (instr_i[6:2] == LUI || instr_i[6:2] == AUIPC) ? instr_i[25] : instr_i[31];

	assign imm_o[26] = (instr_i[6:2] == LUI || instr_i[6:2] == AUIPC) ? instr_i[26] : instr_i[31];

	assign imm_o[27] = (instr_i[6:2] == LUI || instr_i[6:2] == AUIPC) ? instr_i[27] : instr_i[31];

	assign imm_o[28] = (instr_i[6:2] == LUI || instr_i[6:2] == AUIPC) ? instr_i[28] : instr_i[31];

	assign imm_o[29] = (instr_i[6:2] == LUI || instr_i[6:2] == AUIPC) ? instr_i[29] : instr_i[31];

	assign imm_o[30] = (instr_i[6:2] == LUI || instr_i[6:2] == AUIPC) ? instr_i[30] : instr_i[31];

	assign imm_o[31] = instr_i[31];

endmodule
