/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains declarations for the CSR module
 *
 ***********************************************************************************/

package riscv_csr_pkg;
	
	parameter int CSR_OP_WIDTH = 2;
	parameter int CSR_ADDR_WIDTH = 12;
	parameter int MXLEN = 32;

	enum logic [CSR_ADDR_WIDTH-1:0] {
		S_MIE 		= 12'h304,
		S_MTVEC 	= 12'h305,
		S_MSCRATCH 	= 12'h340,
		S_MEPC 		= 12'h341,
		S_MCAUSE 	= 12'h342,
		S_TIM_LOW 	= 12'hC00,
		S_TIM_HIGH 	= 12'hC80
	} addr_t;

endpackage : riscv_csr_pkg