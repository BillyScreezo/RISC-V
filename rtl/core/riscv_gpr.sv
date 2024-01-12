/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains RISC-V register file
 *
 ***********************************************************************************/


module riscv_gpr #(
    int XLEN = 32
)(

    input   logic                       clk_i,          // Core clock
    
    input   logic [$clog2(XLEN)-1:0]    wa_i,           // Recording address in RF
    input   logic                       we_i,           // RF Write Permission
    input   logic [XLEN-1:0]            wd_i,           // Data to be recorded in RF

    input   logic [$clog2(XLEN)-1:0]    ra1_i, ra2_i,   // 2 address ports for reading from RF
    output  logic [XLEN-1:0]            rd1_o, rd2_o    // 2 data ports for reading from RF

);

    localparam int GPR_DEPTH = 32;

    logic [XLEN-1:0] gpr [0:GPR_DEPTH-1];

    initial begin
        gpr[0] = '0;
    end

    assign rd1_o = gpr[ra1_i];
    assign rd2_o = gpr[ra2_i];

    always_ff @(posedge clk_i)
        if (we_i && (wa_i != 0))
            gpr[wa_i] <= wd_i;

endmodule
