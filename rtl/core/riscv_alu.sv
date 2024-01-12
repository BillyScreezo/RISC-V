/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains ALU module
 *
 ***********************************************************************************/

module riscv_alu 

    import riscv_alu_pkg::*;

#(
    int XLEN = 32
)(
    input   logic [ALU_OP_WIDTH-1:0]    opcode_i,           // ALU op code

    input   logic [XLEN-1:0]            op_a_i, op_b_i,     // Operands for ALU result
    input   logic [XLEN-1:0]            cmp_a_i, cmp_b_i,   // Operands for ALU result
    output  logic [XLEN-1:0]            res_o,              // ALU result
    output  logic [XLEN-1:0]            add_o,              // Result of the sum of op_a_i and op_b_i
    output  logic                       flag_o              // ALU flag
);

    always_comb begin
        add_o = $signed(op_a_i) + $signed(opcode_i[ALU_OP_WIDTH-1] ? ~op_b_i : op_b_i) + opcode_i[ALU_OP_WIDTH-1];

        unique case (opcode_i[ALU_MUX_OP_WIDTH-1:0])
            ALU_ADD_SUB:    res_o = add_o;
            ALU_SLL:        res_o = op_a_i << op_b_i[$clog2(XLEN)-1:0];
            ALU_SLTS:       res_o = $signed(op_a_i) < $signed(op_b_i);
            ALU_SLTU:       res_o = op_a_i < op_b_i;
            ALU_XOR:        res_o = op_a_i ^ op_b_i;
            ALU_SRL_SRA:    res_o = opcode_i[ALU_OP_WIDTH-1] ? op_a_i >>> op_b_i[$clog2(XLEN)-1:0] : op_a_i >> op_b_i[$clog2(XLEN)-1:0];
            ALU_OR:         res_o = op_a_i | op_b_i;
            ALU_AND:        res_o = op_a_i & op_b_i;
        endcase

        (*full_case, parallel_case*) case (opcode_i[ALU_MUX_OP_WIDTH-1:0])
            ALU_EQ:         flag_o = cmp_a_i == cmp_b_i;
            ALU_NE:         flag_o = cmp_a_i != cmp_b_i;
            ALU_LTS:        flag_o = $signed(cmp_a_i)  < $signed(cmp_b_i);
            ALU_GES:        flag_o = $signed(cmp_a_i) >= $signed(cmp_b_i);
            ALU_LTU:        flag_o = cmp_a_i  < cmp_b_i;
            ALU_GEU:        flag_o = cmp_a_i >= cmp_b_i;
        endcase
    end

endmodule
