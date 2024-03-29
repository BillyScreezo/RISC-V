/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains declarations for the MDU module
 *
 ***********************************************************************************/

package  riscv_mdu_pkg;

  parameter MDU_OP_W   = 3;

  parameter MDU_MUL    = 3'd0; // MUL
  parameter MDU_MULH   = 3'd1; // MUL High
  parameter MDU_MULHSU = 3'd2; // MUL High (S) (U)
  parameter MDU_MULHU  = 3'd3; // MUL High (U)
  parameter MDU_DIV    = 3'd4; // DIV
  parameter MDU_DIVU   = 3'd5; // DIV (U)
  parameter MDU_REM    = 3'd6; // Remainder
  parameter MDU_REMU   = 3'd7; // Remainder (U)

endpackage :  riscv_mdu_pkg
