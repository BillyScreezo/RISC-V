/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains UART peripheral device like a plug
 *
 ***********************************************************************************/

module riscv_uart_plug #(
	int XLEN 	= 32
) (
	input 	logic 				clk,
	input 	logic 				rstn,

	input 	logic 				sel,
	input 	logic 				enable,
	input 	logic 				write,
	input 	logic [XLEN-1:0] 	addr,
	input 	logic [XLEN-1:0] 	wdata,
	output 	logic [XLEN-1:0] 	rdata,

	output 	logic 				txd,
	input 	logic 				rxd
);

//  ===============================================================================================
//  ==================== Defines
//  ===============================================================================================

	typedef byte unsigned ubytearr_t   [ ];
	typedef byte unsigned ubytearr_q_t [$];

	localparam int ADDR_LOW_WIDTH = 12;
	localparam int DATA_WIDTH = 8;
	
	enum logic [ADDR_LOW_WIDTH-1:0] {
		A_RD = 12'h000,
		A_WR = 12'h004
	} addr_t;

	byte uart_data;

	// Coremark info byte representation

    ubytearr_q_t coremark_info_byte;

    // Coremark info string

    string coremark_info_str;

    // Coremark finish message

    string coremark_finish_msg_0 = "Correct operation validated.\n";
	string coremark_finish_msg_1 = "Errors detected\n";
	string coremark_finish_msg_2 = "Cannot validate operation for these seed values, please compare with results on a known platform.\n";

//  ===============================================================================================
//  ==================== TX logic
//  ===============================================================================================

	assign uart_data = wdata[DATA_WIDTH-1:0];
	assign rdata = { 31'b0, 1'b1 };
	assign txd = '0;

	function string ascii_to_str(ubytearr_t ascii);
        automatic string str = "";
        foreach(ascii[i]) begin
            str = {str, string'(ascii[i])};
        end
        return str;
    endfunction

    initial begin
        forever begin
            if (sel && enable && write && addr[ADDR_LOW_WIDTH-1:0] == A_WR) begin
            	coremark_info_byte.push_back(uart_data);
	            if( ascii_to_str('{uart_data}) == "\n" ) begin
	                coremark_info_str = ascii_to_str(coremark_info_byte);
	                $write("CoreMark: ", coremark_info_str);
	                coremark_info_byte = '{};
	            end
	            if( coremark_info_str == coremark_finish_msg_0 || coremark_info_str == coremark_finish_msg_1 || coremark_info_str == coremark_finish_msg_2) begin
	                $finish();
	            end
            end
            @(posedge clk);
        end
    end

endmodule
