/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains RISC-V core RV32IM
 *
 ***********************************************************************************/

module riscv_core 

    import riscv_intc_pkg::NUMINT;
    import riscv_csr_pkg::CSR_OP_WIDTH;
    import riscv_lsu_pkg::MSIZE_WIDTH;
    import riscv_mdu_pkg::MDU_OP_W;
    
    import riscv_decoder_pkg::*;
    import riscv_alu_pkg::*;
    
#(
    int                 XLEN    = 32,
    bit [XLEN-1:0]      RSTADDR = 0
)(
    input   logic                   clk_i,
    input   logic                   rstn_i,

    // Instruction port
    output  logic                   instr_req_o,
    output  logic [XLEN-1:0]        instr_addr_o,
    input   logic [XLEN-1:0]        instr_data_i,

    // Data port
    output  logic [XLEN-1:0]        data_addr_o,
    output  logic [XLEN-1:0]        data_wdata_o,
    input   logic [XLEN-1:0]        data_rdata_i,
    output  logic                   data_we_o,
    output  logic                   data_req_o,
    output  logic [XLEN/8-1:0]      data_be_o,

    // Interrupt port
    input   logic [NUMINT-1:0]      ext_int_i
);        

//  ===============================================================================================
//  ==================== Defines
//  ===============================================================================================
//  ==================== Constants
    localparam int PC_INCR = 'h4;

//  ==================== Instruction
    logic [XLEN-1:0] f_instr;

//  ==================== PC
    logic [XLEN-1:0] f_curr_pc, f_next_pc, d_curr_pc, d_next_pc;

//  ==================== Branch and pc select logic
    pc_sel_t pc_sel;
    logic mem_valid, f_instr_valid;
    logic stall, kill;

//  ==================== Reg file
    logic gpr_we;
    wb_sel_t wb_src_sel;
    logic [XLEN-1:0] gpr_rd1, gpr_rd2, gpr_wd;

//  ==================== ALU + ALU select
    logic op_a_sel, op_b_sel;
    logic [XLEN-1:0] alu_op_a, alu_op_b;
    logic [ALU_OP_WIDTH-1:0] alu_opcode;
    logic [XLEN-1:0] alu_res, alu_add;
    logic alu_flag;

//  ==================== MDU
    logic mdu_req;
    logic [MDU_OP_W-1:0] mdu_op;
    logic mdu_stall_req;
    logic [XLEN-1:0] mdu_result;

//  ==================== Memory
    logic mem_req;
    logic mem_we;
    logic [MSIZE_WIDTH-1:0] mem_size;
    logic [XLEN-1:0] ram_dout;
    logic lsu_stall_req;

//  ==================== Exception's
    logic illegal_instr, misaligned_access, ecall;

//  ==================== Immediate
    logic [XLEN-1:0] immediate;
    
//  ==================== CSR  
    logic [XLEN-1:0] mie, mtvec, mepc, mcause;
    logic irq, trap;
    logic [CSR_OP_WIDTH-1:0] csr_op;
    logic [XLEN-1:0] csr_dout;
    
//  ===============================================================================================
//  ==================== Stage fetch
//  ===============================================================================================
    // Instruction Fetch (IF)
    assign f_next_pc = f_curr_pc + PC_INCR;

    always_ff @(posedge clk_i) begin
        if (!rstn_i) begin
            f_curr_pc <= RSTADDR;
            f_instr_valid <= '0;
        end else begin
            if (!stall) begin
                unique case (pc_sel)
                    PCS_NPC:    f_curr_pc <= f_next_pc;
                    PCS_SUMM:   f_curr_pc <= alu_add;
                    PCS_MEPC:   f_curr_pc <= mepc;
                    PCS_MTVEC:  f_curr_pc <= mtvec;
                endcase

                d_curr_pc <= f_curr_pc;
                d_next_pc <= f_next_pc;
            end

            if (!f_instr_valid)
                f_instr_valid <= '1;
            else if (pc_sel != PCS_NPC) // If there is a PC change,
                                        // it is necessary to make a bubble in subsequent stages
                f_instr_valid <= '0;

        end
    end

    assign instr_req_o = ~stall;
    assign instr_addr_o = f_curr_pc;
    assign f_instr = instr_data_i;

    // Instruction Decode, get Operands (Op)
    assign stall = lsu_stall_req | mdu_stall_req;
    assign kill  = (pc_sel != PCS_NPC);

//  ===============================================================================================
//  ==================== Include modules
//  ===============================================================================================
    riscv_decoder #(.XLEN(XLEN))
        decoder (
            .fetched_instr_i    (f_instr),

            .alu_flag_i         (alu_flag),
            .op_a_sel_o         (op_a_sel), 
            .op_b_sel_o         (op_b_sel),
            .alu_op_o           (alu_opcode), 

            .mdu_req_o          (mdu_req),
            .mdu_op_o           (mdu_op),

            .mem_req_o          (mem_req), 
            .mem_we_o           (mem_we), 
            .mem_size_o         (mem_size),

            .gpr_we_o           (gpr_we), 
            .wb_src_sel_o       (wb_src_sel),

            .int_i              (irq),
            .csr_op_o           (csr_op),

            .pc_sel_o           (pc_sel),

            .instr_valid_i      (f_instr_valid),
            .stall_i            (stall),
            .illegal_instr_o    (illegal_instr), 
            .ecall_o            (ecall),
            .trap_o             (trap)
        );

    riscv_csr
        csr (
            .clk_i              (clk_i), 
            .rstn_i             (rstn_i),

            .opcode_i           (csr_op), 
            .addr_i             (f_instr[31:20]), 
            .din_i              (gpr_rd1), 
            .dout_o             (csr_dout),

            .mcause_i           (mcause), 
            .pc_i               (d_curr_pc), 
            .mie_o              (mie), 
            .mtvec_o            (mtvec), 
            .mepc_o             (mepc),

            .trap_i             (trap)
        );

    riscv_gpr #(.XLEN(XLEN)) 
        rf (
            .clk_i              (clk_i), 

            .wa_i               (f_instr[11:7]),
            .we_i               (gpr_we), 
            .wd_i               (gpr_wd),

            .ra1_i              (f_instr[19:15]), 
            .ra2_i              (f_instr[24:20]),  
            .rd1_o              (gpr_rd1), 
            .rd2_o              (gpr_rd2)
        );

    riscv_intc 
        intc (
            .clk_i              (clk_i), 
            .rstn_i             (rstn_i),
            
            .irq_rst_i          (!stall && f_instr_valid),
            .irq_o              (irq), 
            .cause_o            (mcause), 

            .en_ext_i           (mie[0]),
            .ext_int_i          (ext_int_i),

            .illegal_instr_i    (illegal_instr), 
            .misalig_acc_i      (misaligned_access), 
            .ecall_i            (ecall)

        );

    riscv_alu #(.XLEN(XLEN)) 
        alu (
            .opcode_i           (alu_opcode), 

            .op_a_i             (alu_op_a), 
            .op_b_i             (alu_op_b),
            
            .cmp_a_i            (gpr_rd1), 
            .cmp_b_i            (gpr_rd2), 

            .res_o              (alu_res), 
            .add_o              (alu_add), 
            .flag_o             (alu_flag)
        );

    // Memory access (MA)
    riscv_lsu #(.XLEN(XLEN))
        lsu (
            .clk_i              (clk_i), 
            .rstn_i             (rstn_i),

            .core_addr_i        (alu_add), 
            .core_we_i          (mem_we), 
            .core_size_i        (mem_size), 
            .core_wdata_i       (gpr_rd2),
            .core_req_i         (mem_req), 
            .core_rvalid_o      (mem_valid), 
            .core_rdata_o       (ram_dout),
            
            .lsu_rdata_i        (data_rdata_i), 
            .lsu_req_o          (data_req_o), 
            .lsu_we_o           (data_we_o),
            .lsu_be_o           (data_be_o), 
            .lsu_addr_o         (data_addr_o), 
            .lsu_wdata_o        (data_wdata_o),

            .unaligned_access_o (misaligned_access),
            .lsu_stall_req_o    (lsu_stall_req)
        );

    riscv_imm #(.XLEN(XLEN))
        imm_block (
            .instr_i(f_instr), 
            .imm_o(immediate)
        );

    riscv_mdu #(.XLEN(XLEN)) 
        mdu_inst (
            .clk_i              (clk_i),
            .rstn_i             (rstn_i),

            .mdu_req_i          (mdu_req),
            .mdu_port_a_i       (gpr_rd1),
            .mdu_port_b_i       (gpr_rd2),
            .mdu_op_i           (mdu_op),
            .mdu_kill_i         (1'b0),
            .mdu_keep_i         (1'b0),
            .mdu_result_o       (mdu_result),
            .mdu_stall_req_o    (mdu_stall_req)
        );

//  ===============================================================================================
//  ==================== ALU Select
//  ===============================================================================================    
    // Execute (Ex)   
    assign alu_op_a = op_a_sel ? d_curr_pc : gpr_rd1;
    assign alu_op_b = op_b_sel ? immediate : gpr_rd2;

//  ===============================================================================================
//  ==================== WB select
//  ===============================================================================================    
    // Writeback (Wb)
    always_comb begin
        unique case (wb_src_sel)
            WBS_ALU: gpr_wd = alu_res;
            WBS_NPC: gpr_wd = d_next_pc;
            WBS_CSR: gpr_wd = csr_dout;
            WBS_RAM: gpr_wd = ram_dout;
            WBS_IMM: gpr_wd = immediate;
            WBS_MDU: gpr_wd = mdu_result;
        endcase
    end

endmodule
