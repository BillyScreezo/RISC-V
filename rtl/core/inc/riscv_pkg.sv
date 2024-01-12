/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains general purpose declarations for the RISC-V core module
 *
 ***********************************************************************************/
 

package riscv_pkg;

//  =============================================
//  ==================== RISC-V
//  =============================================

// Main RISC-V defines 
    parameter int     XLEN                = 32;           // addr and data width
    parameter int     RSTADDR             = 32'h0;
    parameter int     SYS_CLK             = 70;

//  =============================================
//  ==================== Periph
//  =============================================

    parameter int     BUS_SLAVES          = 3;            // number of bus slaves

// On-chip RAM
    parameter int     RAMSZ               = 64;           // RAM size in KBytes
    parameter string  ROM_INIT_FILE       = "rom.hex";    // rom init file name

// GPIO
   parameter  int     GPIO_WIDTH          = 16;           // width of io's on board (led, sw, etc.)

// BTN shift-register
    parameter int     SH_BTN_WIDTH        = 7;

// UART
    parameter int     UART_BAUDRATE       = 1000000;
    parameter int     UART_DBITS          = 8;
    parameter string  UART_PARITY         = "Even";
    parameter int     UART_NSTOP          = 1;


endpackage : riscv_pkg