/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains declarations for the decoder module
 *
 ***********************************************************************************/

package riscv_decoder_pkg;

//  ==================== Opcodes
    enum logic [4:0] {
        LOAD     = 5'b00_000,
        MISC_MEM = 5'b00_011,
        OP_IMM   = 5'b00_100,
        AUIPC    = 5'b00_101,
        STORE    = 5'b01_000,
        OP       = 5'b01_100,
        LUI      = 5'b01_101,
        BRANCH   = 5'b11_000,
        JALR     = 5'b11_001,
        JAL      = 5'b11_011,
        SYSTEM   = 5'b11_100
    } opcode32_e;

//  ==================== WB source select

    typedef enum {
        WBS_ALU,
        WBS_MDU,
        WBS_NPC,
        WBS_CSR,
        WBS_RAM,
        WBS_IMM
    } wb_sel_t;

//  ==================== PC soruce select

    typedef enum {
        PCS_NPC,
        PCS_SUMM,
        PCS_MEPC,
        PCS_MTVEC
    } pc_sel_t;

//  ==================== Instruction types
    typedef struct packed {
        logic [6:0] funct7;
        logic [4:0] rs2;
        logic [4:0] rs1;
        logic [2:0] funct3;
        logic [4:0] rd;
    } r_type_t;

    typedef struct packed {
    	union packed {
    		struct packed {
    			logic [6:0] funct7;
    			logic [4:0] shamt;
    		} imm;
    		logic [11:0] imm1;
    	} imm;
        logic [4:0] rs1;
        logic [2:0] funct3;
        logic [4:0] rd;
    } i_type_t;

    typedef struct packed {
        logic [6:0] imm1;
        logic [4:0] rs2;
        logic [4:0] rs1;
        logic [2:0] funct3;
        logic [4:0] imm0;
    } s_type_t;

    typedef struct packed {
        logic [6:0] imm1;
        logic [4:0] rs2;
        logic [4:0] rs1;
        logic [2:0] funct3;
        logic [4:0] imm0;
    } b_type_t;

    typedef struct packed {
        logic [19:0] imm0;
        logic [4:0] rd;
    } u_type_t;

    typedef struct packed {
        logic [19:0] imm0;
        logic [4:0] rd;
    } j_type_t;

    typedef struct packed {
        union packed {
            r_type_t r;
            i_type_t i;
            s_type_t s;
            b_type_t b;
            u_type_t u;
            j_type_t j;
        } tp;
        logic [6:0] opcode;
    } instr32_t;

endpackage
