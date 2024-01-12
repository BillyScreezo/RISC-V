/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains RISC-V N-bit wide signed divider 
 *
 ***********************************************************************************/

module riscv_s_divider 

import riscv_mdu_pkg::*;

#(int N = 32)
(
input   logic                   clk_i,
input   logic                   rstn_i,

input   logic                   req_i,
output  logic                   rdy_o,

input   logic   [MDU_OP_W-1:0]  mdu_op_i,    // opcode

input   logic   [N:0]           ai,              // Dividend
input   logic   [N:0]           bi,              // Divider

output  logic   [N-1:0]         quotient_o,      // division result
output  logic   [N-1:0]         remainder_o,     // Remainder

input   logic                   a_is_zero_i,
input   logic                   b_is_zero_i
);

    localparam M = 2*N;

    logic   signed  [N-1:0] r_quotient;

    logic   signed  [M-1:0] a_copy;
    logic   signed  [M-1:0] b_copy;

    logic   signed  [M-1:0] w_diff;
    logic                   w_sign;

    logic           [$clog2(N):0] cnt;

    logic [N:0]   ma, mb;    // Negation of 'a' and 'b'
    logic [N-1:0] au, bu;    // Unsigned operands

    logic sign_a, sign_b;

    logic sign_res;          // sign of result

    logic div_by_zero;

    typedef enum {
        S_IDLE,
        S_DIV,
        S_SIGN_CORRECT,
        S_RESULT
    } sdiv_state_t;

    sdiv_state_t state;

// ==============================================
// ===================== Converting Input Operands
// ==============================================

    assign div_by_zero = b_is_zero_i;

// Преобразование операндов
    assign sign_a = ai[N];
    assign sign_b = bi[N];

    assign ma = -ai;
    assign mb = -bi;

    assign au = sign_a ? ma[N-1:0] : ai[N-1:0];   // Received operand modules
    assign bu = sign_b ? mb[N-1:0] : bi[N-1:0];

// ==============================================
// ===================== FSM
// ==============================================

    always_ff @(posedge clk_i)
        if(!rstn_i)
            state <= S_IDLE;
        else unique case (state)

            S_IDLE:
                if(req_i) begin
                    if(div_by_zero)
                        state <= S_RESULT;
                    else begin
                        state <= S_DIV;

                        (*parallel_case*) case (mdu_op_i)
                            MDU_DIV: sign_res <= (sign_a ^ sign_b);
                            MDU_REM: sign_res <= sign_a;
                            default: sign_res <= 1'b0;
                        endcase
                    end
                end

            S_DIV:
                if(cnt == N - 1)         
                    state <= sign_res ? S_SIGN_CORRECT : S_RESULT;

            S_SIGN_CORRECT: state <= S_RESULT;

            S_RESULT:       state <= S_IDLE;
        endcase

    

// ==============================================
// ===================== Division operation
// ==============================================

    assign w_diff = a_copy - b_copy;
    assign w_sign = w_diff[M-1];

    always_ff @(posedge clk_i)
        if((state == S_IDLE) && req_i)
            cnt <= '0;
        else if (state == S_DIV)
            cnt <= cnt + 1'b1;

    always_ff @(posedge clk_i)
        unique0 case(state)
            S_IDLE: begin
                if(req_i) begin

                    r_quotient  <= div_by_zero ? '1 : '0;
                    a_copy      <= div_by_zero ? '0 : {{N{1'b0}}, au};

                    b_copy <= {1'b0, bu, {N-1{1'b0}}};

                end
            end

            S_DIV: begin
                b_copy <= b_copy >> 1;

                if(!w_sign) begin
                    a_copy      <= w_diff;
                    r_quotient  <= {r_quotient[N-2:0], 1'b1};
                end else
                    r_quotient  <= {r_quotient[N-2:0], 1'b0};
                end

            S_SIGN_CORRECT: begin
                r_quotient      <= -r_quotient;
                a_copy[N-1:0]   <= -a_copy[N-1:0];
            end
        endcase
       

// ==============================================
// ===================== Output of result
// ==============================================

    assign rdy_o = (state == S_RESULT);

    assign quotient_o  = r_quotient;
    assign remainder_o = a_copy[N-1:0];

endmodule
