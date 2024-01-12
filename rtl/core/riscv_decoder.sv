/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains RISC-V RV32IM instructions decoder
 *
 ***********************************************************************************/

module riscv_decoder 

    import riscv_decoder_pkg::*;
    import riscv_alu_pkg::ALU_OP_WIDTH;
    import riscv_lsu_pkg::MSIZE_WIDTH;
    import riscv_csr_pkg::CSR_OP_WIDTH;
    import riscv_mdu_pkg::MDU_OP_W;
    
#(
    int XLEN = 32
)(
    input   logic [XLEN-1:0]                fetched_instr_i,            // Decoding instructions
    
    // Блок АЛУ
    input   logic                           alu_flag_i,                 // ALU flag
    output  logic                           op_a_sel_o, op_b_sel_o,     // Selecting operands for the ALU
    output  logic [ALU_OP_WIDTH-1:0]        alu_op_o,                   // ALU operation
    
    output  logic                           mdu_req_o,
    output  logic [MDU_OP_W-1:0]            mdu_op_o,

    // Блок LSU
    output  logic                           mem_req_o,                  // Request to memory
    output  logic                           mem_we_o,                   // Memory Write Request
    output  logic [MSIZE_WIDTH-1:0]         mem_size_o,                 // Memory access size

    // GPR
    output  logic                           gpr_we_o,                   // RF Write Permission
    output  wb_sel_t                        wb_src_sel_o,               // Selecting a data source for recording in RF

    // CSR
    input   logic                           int_i,                      // Interrupt Request
    output  logic [CSR_OP_WIDTH-1:0]        csr_op_o,                   // Operation CSR

    // PC
    output  pc_sel_t                        pc_sel_o,                   // PC selection

    // Служебные сигналы
    input   logic                           instr_valid_i,              // Validity of the decorated instruction (whether the instruction needs to be decoded)
    input   logic                           stall_i,                    // Decoding Stage Stop Signal
    output  logic                           illegal_instr_o,            // Validity of the decorated instruction (is the instruction supported)
    output  logic                           ecall_o,                    // env call
    output  logic                           trap_o                      // trap

);

    instr32_t instr;
    assign instr = fetched_instr_i;

    always_comb begin
        if (instr.opcode[1:0] != 2'b11)
            illegal_instr_o = 1;
        else begin
            (*parallel_case*) case (instr.opcode[6:2])
                
                OP: begin
                    illegal_instr_o = 0;

                    if(instr.tp.r.funct7 != 7'h01) begin
                        if (instr.tp.r.funct3 == 3'h0 || instr.tp.r.funct3 == 3'h5) begin
                            if (instr.tp.r.funct7 != 7'h00 && instr.tp.r.funct7 != 7'h20)
                                illegal_instr_o = 1;
                        end else if (instr.tp.r.funct7 != 7'h00) begin
                            illegal_instr_o = 1;
                        end
                    end
                end

                OP_IMM: begin
                    illegal_instr_o = 0;

                    if (instr.tp.i.funct3 == 3'h1 && instr.tp.i.imm.imm.funct7 != 7'h00)
                        illegal_instr_o = 1;

                    if (instr.tp.i.funct3 == 3'h5 && instr.tp.i.imm.imm.funct7 != 7'h00 && instr.tp.i.imm.imm.funct7 != 7'h20)
                        illegal_instr_o = 1;
                end

                LOAD: illegal_instr_o = 0;
                STORE: illegal_instr_o = 0;
                BRANCH: illegal_instr_o = 0;
                JAL: illegal_instr_o = 0;
                JALR: illegal_instr_o = 0;
                LUI: illegal_instr_o = 0;
                AUIPC: illegal_instr_o = 0;
                SYSTEM: illegal_instr_o = 0;
                MISC_MEM: illegal_instr_o = 0;
                
                default: illegal_instr_o = 1;
            endcase
        end
    end

    always_comb begin : decode
        op_a_sel_o = 0; op_b_sel_o = 0;
        alu_op_o = 0;
        mem_req_o = 0; mem_we_o = 0;
        mem_size_o = instr.tp.s.funct3;
        gpr_we_o = 0; wb_src_sel_o = WBS_ALU;
        pc_sel_o = PCS_NPC;
        csr_op_o = 0;
        trap_o = 0; ecall_o = 0;
        mdu_req_o = 0;
        mdu_op_o = instr.tp.r.funct3;

        (*parallel_case*) case (instr.opcode[6:2])

            OP: begin
                op_a_sel_o = 0; op_b_sel_o = 0;
                alu_op_o = { instr.tp.r.funct7[5], instr.tp.r.funct3 };
                gpr_we_o = 1; 

                if(instr.tp.r.funct7[0]) begin
                    mdu_req_o    = '1;
                    wb_src_sel_o = WBS_MDU;
                end else begin
                    mdu_req_o    = '0;
                    wb_src_sel_o = WBS_ALU;
                end
                
            end

            OP_IMM: begin
                op_a_sel_o = 0; op_b_sel_o = 1;

                (*parallel_case*) case (instr.tp.i.funct3)
                    3'h5: alu_op_o = { instr.tp.i.imm.imm.funct7[5], instr.tp.i.funct3 };
                    default: alu_op_o = { 1'b0, instr.tp.i.funct3 }; 
                endcase

                gpr_we_o = 1; wb_src_sel_o = WBS_ALU;
            end

            LOAD: begin
                op_a_sel_o = 0; op_b_sel_o = 1;
                gpr_we_o = 1; wb_src_sel_o = WBS_RAM;
                mem_req_o = 1; mem_we_o = 0; 
            end

            STORE: begin
                op_a_sel_o = 0; op_b_sel_o = 1;
                mem_req_o = 1; mem_we_o = 1;
            end

            BRANCH: begin
                op_a_sel_o = 1; op_b_sel_o = 1;
                alu_op_o = { 1'b0, instr.tp.b.funct3 };
                if (alu_flag_i)
                    pc_sel_o = PCS_SUMM;
            end

            JAL: begin
                op_a_sel_o = 1; op_b_sel_o = 1;
                gpr_we_o = 1; wb_src_sel_o = WBS_NPC;
                pc_sel_o = PCS_SUMM;
            end

            JALR: begin
                op_a_sel_o = 0; op_b_sel_o = 1;
                gpr_we_o = 1; wb_src_sel_o = WBS_NPC;
                pc_sel_o = PCS_SUMM;
            end

            LUI: begin
                gpr_we_o = 1; wb_src_sel_o = WBS_IMM;
            end

            AUIPC: begin
                op_a_sel_o = 1; op_b_sel_o = 1;
                gpr_we_o = 1; wb_src_sel_o = WBS_ALU;
            end

            
            SYSTEM: begin
                csr_op_o = instr.tp.i.funct3[CSR_OP_WIDTH-1:0];

                if (instr.tp.i.funct3 == 3'h0) begin
                    unique0 case (instr.tp.i.imm.imm1)
                        12'h000: begin      // ecall
                            trap_o = 1;
                            ecall_o = 1;
                            pc_sel_o = PCS_MTVEC;
                        end
                        12'h001: begin      // ebreak
                        end
                        12'h302: begin      // mret/sret
                            pc_sel_o = PCS_MEPC;
                        end
                    endcase
                end

                if (|instr.tp.i.funct3[1:0]) begin
                    wb_src_sel_o = WBS_CSR; 
                    gpr_we_o = 1;
                end
            end

            MISC_MEM: begin
                // NOP
            end


        endcase

        if (illegal_instr_o || int_i) begin
            mem_req_o = 0; mem_we_o = 0;
            gpr_we_o = 0;
            pc_sel_o = PCS_MTVEC;
            csr_op_o = 0;
            trap_o = 1;
        end

        if (stall_i) begin
            gpr_we_o = 0;
        end

        if (!instr_valid_i) begin
            mem_req_o = 0; mem_we_o = 0;
            gpr_we_o = 0;
            pc_sel_o = PCS_NPC;
            csr_op_o = 0;       // ?
        end
    end

endmodule
