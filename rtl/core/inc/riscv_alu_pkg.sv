/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains declarations for the ALU module
 *
 ***********************************************************************************/

package riscv_alu_pkg;
	
    parameter int ALU_OP_WIDTH = 4;						// 	Bit capacity of ALU operations during decoding
    parameter int ALU_MUX_OP_WIDTH = ALU_OP_WIDTH - 1;	// 	Bit capacity of ALU multiplexers when choosing a calculation result

    enum logic [ALU_MUX_OP_WIDTH-1:0] {
        ALU_ADD_SUB     = 3'h0,
        ALU_SLL         = 3'h1,
        ALU_SLTS        = 3'h2,
        ALU_SLTU        = 3'h3,
        ALU_XOR         = 3'h4,
        ALU_SRL_SRA     = 3'h5,
        ALU_OR          = 3'h6,
        ALU_AND         = 3'h7
    } alu_op_e;
        
    // Comparisons
    enum logic [ALU_MUX_OP_WIDTH-1:0] {
        ALU_EQ   = 3'h0,
        ALU_NE   = 3'h1,
        ALU_LTS  = 3'h4,
        ALU_GES  = 3'h5,
        ALU_LTU  = 3'h6,
        ALU_GEU  = 3'h7
    } alu_cmp_e;

endpackage : riscv_alu_pkg