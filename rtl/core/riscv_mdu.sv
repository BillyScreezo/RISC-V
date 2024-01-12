/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains RISC-V MDU module
 *
 ***********************************************************************************/

module riscv_mdu

    import riscv_mdu_pkg::*;

#(
    int XLEN = 32
)(
    // Clock, reset
    input   logic                   clk_i,
    input   logic                   rstn_i,

    // Core pipeline signals
    input   logic                   mdu_req_i,        // request for proceeding operation
    input   logic   [XLEN-1:0]      mdu_port_a_i,     // operand A
    input   logic   [XLEN-1:0]      mdu_port_b_i,     // operand B
    input   logic   [MDU_OP_W-1:0]  mdu_op_i,         // opcode
    input   logic                   mdu_kill_i,       // cancel a current multicycle operation
    input   logic                   mdu_keep_i,       // save the result and prevent repetition of computation
    output  logic   [XLEN-1:0]      mdu_result_o,     // computation result
    output  logic                   mdu_stall_req_o   // stall the pipeline during a multicycle operation
);

// ==============================================
// ===================== Defines
// ==============================================

    logic                     sign_a;
    logic                     sign_b;
    logic                     msb_a;
    logic                     msb_b;
    logic                     a_is_zero;
    logic                     b_is_zero;
    logic                     mult_op;

    logic        [XLEN-1:0]   div_result;
    logic signed [XLEN-1:0]   rem_result;
    logic                     div_req;
    logic                     div_rdy;
    logic                     div_stall;

    logic                     div_start;
    logic                     b_zero_flag_ff;

    logic        [2*XLEN-1:0] mult_result;
    logic                     mult_req;
    logic                     mult_rdy;
    logic                     mult_stall;

// ==============================================
// ===================== Operand conversion, flag evaluation, MDU operations
// ==============================================

    assign sign_a = mdu_port_a_i[XLEN-1];
    assign sign_b = mdu_port_b_i[XLEN-1];

    // used for both MUL and DIV
    assign a_is_zero = ~|mdu_port_a_i;
    assign b_is_zero = ~|mdu_port_b_i;

    always_comb
        unique case (mdu_op_i) inside
            MDU_MUL, MDU_MULH, MDU_MULHU, MDU_MULHSU:   mult_op = 1'b1;
            MDU_DIV, MDU_REM, MDU_DIVU, MDU_REMU:       mult_op = 1'b0;
        endcase

    always_comb
        unique case (mdu_op_i) inside
            MDU_MUL,
            MDU_MULH,
            MDU_DIV,
            MDU_REM: begin
                msb_a = sign_a;
                msb_b = sign_b;
            end
            MDU_MULHU,
            MDU_DIVU,
            MDU_REMU: begin
                msb_a = 1'b0;
                msb_b = 1'b0;
            end
            MDU_MULHSU: begin
                msb_a = sign_a;
                msb_b = 1'b0;
            end
        endcase

// ==============================================
// ===================== Multiplier
// ==============================================

    assign mult_req   = mult_op & mdu_req_i;
    assign mult_stall = mult_req & (~mult_rdy);

    riscv_smult_32_32 smult_32_32_inst (
        .clk_i              (clk_i),    // Clock
        .rstn_i             (rstn_i),   // Asynchronous reset active low

        .req_i              (mult_req),
        .rdy_o              (mult_rdy),

        .ai                 ({msb_a, mdu_port_a_i}), 
        .bi                 ({msb_b, mdu_port_b_i}),

        .result_o           (mult_result),

        .zf_i               (a_is_zero | b_is_zero)
    );


// ==============================================
// ===================== Divider
// ==============================================

    assign div_req = ~mult_op & mdu_req_i;
    assign div_stall = div_req & (~div_rdy);

    riscv_s_divider #(.N(XLEN))
        s_divider_inst (
            .clk_i          (clk_i),
            .rstn_i         (rstn_i),

            .req_i          (div_req),
            .rdy_o          (div_rdy),

            .mdu_op_i       (mdu_op_i),

            .ai             ({msb_a, mdu_port_a_i}),    // Dividend
            .bi             ({msb_b, mdu_port_b_i}),    // Divider

            .quotient_o     (div_result),               // division result
            .remainder_o    (rem_result),               // Remainder

            .a_is_zero_i    (a_is_zero),
            .b_is_zero_i    (b_is_zero)
    );

// ==============================================
// ===================== MDU output
// ==============================================

    assign mdu_stall_req_o = div_stall || mult_stall;

    always_comb
        unique case (mdu_op_i) inside
            MDU_MUL:    mdu_result_o = mult_result[XLEN-1:0];
            MDU_MULH,
            MDU_MULHSU,
            MDU_MULHU:  mdu_result_o = mult_result[2*XLEN-1:XLEN];
            MDU_DIV,
            MDU_DIVU:   mdu_result_o = div_result;
            MDU_REM,
            MDU_REMU:   mdu_result_o = rem_result;
        endcase

endmodule
