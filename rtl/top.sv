/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains combining the CPU core and peripherals in the SoC
 *
 ***********************************************************************************/

module top 

    import riscv_pkg::*;
    import riscv_intc_pkg::NUMINT;

#(
    int TB_MODE = 0
)(
    input   logic                   sys_clk,
    input   logic                   sys_rstn,
    input   logic [GPIO_WIDTH-1:0]  io_sw,
    output  logic [GPIO_WIDTH-1:0]  io_led,
    input   logic                   io_btnc,

    input   logic                   uart_txd_in,
    output  logic                   uart_rxd_out
);

//  ===============================================================================================
//  ==================== DEFINES
//  ===============================================================================================

//  ==================== CLK, RST
    logic clk, rstn, locked;
    (* ASYNC_REG="TRUE" *) logic [SH_BTN_WIDTH-1:0] rstn_sreg;

//  ==================== Instruction's bus
    logic instr_req_o;
    logic [XLEN-1:0] instr_addr;
    logic [XLEN-1:0] instr_data;

//  ==================== Data bus
    logic [XLEN-1:0] data_addr;
    logic [XLEN-1:0] data_wdata;
    logic [XLEN-1:0] data_rdata;
    logic data_req, data_we;
    logic [(XLEN/8)-1:0] data_be;

//  ==================== Bus slave's signals
    logic [BUS_SLAVES-1:0] sel;
    logic [XLEN-1:0] s_rdata [0:BUS_SLAVES-1];

//  ==================== Interrupt signals
    logic [NUMINT-1:0] ext_int;

//  ==================== IO's
    (* ASYNC_REG="TRUE" *) logic [SH_BTN_WIDTH-1:0] io_btnc_sreg;
    

//  ===============================================================================================
//  ==================== Clock and reset logic
//  ===============================================================================================
    clkgen #(.TB_MODE(TB_MODE)) clkgen_inst (.clkin(sys_clk), .clkout(clk), .locked(locked));

    always_ff @(posedge clk) begin
        rstn_sreg <= {rstn_sreg[SH_BTN_WIDTH-2:0], sys_rstn & locked};
        rstn = rstn_sreg[SH_BTN_WIDTH-1];
    end

//  ===============================================================================================
//  ==================== Include modules
//  ===============================================================================================
    riscv_core #(.XLEN(XLEN), .RSTADDR(RSTADDR))
        mp (
            .clk_i(clk), 
            .rstn_i(rstn),
            
            .instr_req_o (instr_req_o), .instr_addr_o(instr_addr), .instr_data_i(instr_data),
            .data_addr_o(data_addr), .data_wdata_o(data_wdata), .data_rdata_i(data_rdata),
            .data_we_o(data_we), .data_req_o(data_req), .data_be_o(data_be),
            .ext_int_i(ext_int)
        );

    riscv_busc #(.XLEN(XLEN), .NSLAVES(BUS_SLAVES)) 
        busc (
            .clk(clk),
            .addr_i(data_addr), .sel_o(sel), .rdata_i(s_rdata), .rdata_o(data_rdata)
        );

    riscv_dualport_ram #(.WIDTH(XLEN), .RAMSZ(RAMSZ), .INIT_FILE(ROM_INIT_FILE))
        ram (
            .clk(clk), .ena(data_req & sel[0]), .wea(data_we), .bea(data_be),
            .addra(data_addr), .dina(data_wdata), .douta(s_rdata[0]),
            .enb(instr_req_o), .addrb(instr_addr), .doutb(instr_data)
        );

    riscv_gpio #(.XLEN(XLEN), .WIDTH(GPIO_WIDTH)) 
        gpio (
            .clk(clk), .rstn(rstn),
            .sel(sel[1]), .enable(data_req), .write(data_we),
            .addr(data_addr), .wdata(data_wdata), .rdata(s_rdata[1]),
            .gpio_o(io_led), .gpio_i(io_sw)
        );

    generate
        if(TB_MODE) begin
            riscv_uart_plug #(.XLEN(XLEN)) 
                uart (
                    .clk(clk), .rstn(rstn),
                    .sel(sel[2]), .enable(data_req), .write(data_we),
                    .addr(data_addr), .wdata(data_wdata), .rdata(s_rdata[2]),
                    .txd(uart_rxd_out), .rxd(uart_txd_in)
                );
        end else begin
            riscv_uart #(.XLEN(XLEN), .SYS_CLK(SYS_CLK), .BAUDRATE(UART_BAUDRATE), .DBITS(UART_DBITS), .PARITY(UART_PARITY), .N_STOP_BITS(UART_NSTOP)) 
                uart_inst (
                    .clk(clk), .rst_n(rstn),
                    .sel(sel[2]), .enable(data_req), .write(data_we),
                    .addr(data_addr), .wdata(data_wdata), .rdata(s_rdata[2]),
                    .tx(uart_rxd_out), .rx(uart_txd_in)
                );
            end
    endgenerate

//  ===============================================================================================
//  ==================== IO's
//  ===============================================================================================
    always @(posedge clk) begin
        if (!rstn) begin
            io_btnc_sreg <= '0;
            ext_int      <= '0;
        end else begin
            io_btnc_sreg <= {io_btnc_sreg[SH_BTN_WIDTH-2:0], io_btnc};
            ext_int[0]   <= ~io_btnc_sreg[SH_BTN_WIDTH-1] & (&io_btnc_sreg[SH_BTN_WIDTH-2:0]);  // posedge
        end
    end

    assign ext_int[NUMINT-1:1] = '0;

endmodule
