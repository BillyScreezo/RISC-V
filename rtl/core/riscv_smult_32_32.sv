/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains RISC-V 32x32 wide signed multiplier
 *
 ***********************************************************************************/

module riscv_smult_32_32 (
		input 						clk_i,   // Clock
		input 						rstn_i,  // Asynchronous reset active low

		input 	logic 				req_i,
		output 	logic 				rdy_o,
		
		input 	logic signed [32:0] ai, 
		input 	logic signed [32:0] bi,

		output 	logic  		 [63:0] result_o,

		input 	logic 				zf_i
);

// ==============================================
// ===================== Defines
// ==============================================

	typedef enum {
		S_IDLE,
		S_MULT,
		S_PRE_SUMM,
		S_FULL_SUMM,
		S_SIGN_CORRECT,
		S_RESULT
	} smult_state_t;

	smult_state_t state;

	logic [63:0] hr, lr;			// Full/abbreviated multiplication result

	logic [32:0] ma, mb; 			// Negation of 'a' and 'b'
	logic [31:0] au, bu;			// Unsigned operands

	logic [35:0] a1_b1, a1_b1_lr;	// Intermediate works
	logic [31:0] a2_b1;
	logic [31:0] a1_b2;
	logic [27:0] a2_b2;

	logic [45:0] pre_summ_l; 
	logic [63:0] pre_summ_r, summ;

	logic [17:0] a1, b1;
	logic [13:0] a2, b2; 			// Trimmed parts of operands

	logic sign_a, sign_b;

	logic little_mult;				// Signal of readiness for multiplication of lower parts

	logic pre_rdy;

// ==============================================
// ===================== FSM
// ==============================================

	always_ff @(posedge clk_i)
		if(!rstn_i)
			state <= S_IDLE;
		else
			unique case (state)
				S_IDLE:	
					if(req_i)
						state <= zf_i ? S_RESULT : S_MULT;

				S_MULT: 			state <= little_mult ? S_SIGN_CORRECT : S_PRE_SUMM;

				S_PRE_SUMM: 		state <= S_FULL_SUMM;

				S_FULL_SUMM: 		state <= S_SIGN_CORRECT;

				S_SIGN_CORRECT: 	state <= S_RESULT;

				S_RESULT: 			state <= S_IDLE;

			endcase

// ==============================================
// ===================== Converting Input Operands
// ==============================================
// Operand Conversion
	assign sign_a = ai[32];
	assign sign_b = bi[32];

	assign ma = -ai;
	assign mb = -bi;

	assign au = sign_a ? ma[31:0] : ai[31:0];	// Received operand modules
	assign bu = sign_b ? mb[31:0] : bi[31:0];

// Dividing operands into parts
	always_ff @(posedge clk_i)
		if(req_i && !zf_i) begin
			a1 <= au[17:0];
			a2 <= au[31:18];

	 		b1 <= bu[17:0];
			b2 <= bu[31:18];
		end

// ==============================================
// ===================== Multiplication
// ==============================================
// Intermediate operations on DSP
	always_ff @(posedge clk_i)
		if(state == S_MULT) begin
			a1_b1 <= a1 * b1;
			a2_b1 <= a2 * b1;
			a1_b2 <= a1 * b2;
			a2_b2 <= a2 * b2;
		end

// ==============================================
// ===================== Summation
// ==============================================
// Summation of intermediate multiplications
	always_ff @(posedge clk_i)
		if(state == S_PRE_SUMM) begin
			pre_summ_l <= a1_b2 + a2_b1;
			pre_summ_r <= {a2_b2, a1_b1};
		end

	always_ff @(posedge clk_i)
		if(state == S_FULL_SUMM)
			summ <= {pre_summ_l + pre_summ_r[63:18], pre_summ_r[17:0]};

// Converting the result of a full multiplication
	assign hr = ((sign_a && sign_b) || (!sign_a && !sign_b)) ? summ : -summ;

// ==============================================
// ===================== Logic for issuing results
// ==============================================

	assign pre_rdy = (req_i & zf_i) | (state == S_SIGN_CORRECT);

// Ready signal logic
	always_ff @(posedge clk_i)
		if(!rstn_i)
			rdy_o <= '0;
		else
			if(rdy_o)
				rdy_o <= '0;
			else if(pre_rdy)
				rdy_o <= '1;
				
// ==============================================
// ===================== Abbreviated multiplication
// ==============================================

// If the high-order parts of the moduli of the operands do not contain ones, 
// then abbreviated multiplication is possible
	assign little_mult = ~((|au[31:18]) | (|bu[31:18]));

// Converting the result of abbreviated multiplication
	assign a1_b1_lr = ((sign_a && sign_b) || (!sign_a && !sign_b)) ? a1_b1 : -a1_b1;

// Abbreviated multiplication, sign expansion
	assign lr = {{28{a1_b1_lr[35]}}, a1_b1_lr};

	always_ff @(posedge clk_i)
		if(pre_rdy)
			unique casex ({zf_i, little_mult})
				2'b1? : result_o <= 64'h0;
				2'b01 : result_o <= lr;
				2'b00 : result_o <= hr;
			endcase

endmodule : riscv_smult_32_32