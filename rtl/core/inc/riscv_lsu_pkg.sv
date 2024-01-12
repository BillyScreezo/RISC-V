/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains declarations for the LSU module
 *
 ***********************************************************************************/
 
 package riscv_lsu_pkg;
	
    parameter int MSIZE_WIDTH = 3;

	typedef enum {
		LSU_IDLE,
		LSU_LOAD
	} lsu_state_t;

	
endpackage : riscv_lsu_pkg