/***********************************************************************************
 * Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains RISC-V coremark tb
 *
 ***********************************************************************************/

`timescale 1ns / 1ps

module riscv_tb ();

    // `define postSynth

    `ifdef postSynth
        parameter real PERIOD   = 10.0;                     // ns
        parameter bit  TB_MODE  = 0;
    `else
        parameter real PERIOD   = 14.2857142857143;                     // ns
        parameter bit  TB_MODE  = 1;
    `endif

	parameter real SYS_CLK_FREQ     = 1000.0 / PERIOD;     // MHz
    
    import riscv_pkg::UART_BAUDRATE;

	logic sys_clk, sys_rstn;
	logic [15:0] io_led, io_sw;
	logic io_btnc;
	logic uart_txd_in, uart_rxd_out;

	always begin
		sys_clk = 0;
		#(PERIOD/2) sys_clk = 1;
		#(PERIOD/2);
	end

	top #(.TB_MODE(TB_MODE)) dut (.sys_clk(sys_clk), .sys_rstn(sys_rstn),
		.io_sw(io_sw), .io_led(io_led), .io_btnc(io_btnc),
		.uart_txd_in(uart_txd_in), .uart_rxd_out(uart_rxd_out));

	initial begin
		sys_rstn    = 0;
		io_btnc     = 0;
        io_sw       = '0;
		uart_txd_in = 0;

		repeat(100) @(posedge sys_clk);;
		sys_rstn = 1;
	end

    `ifdef postSynth

        typedef byte unsigned ubytearr_t   [ ];
        typedef byte unsigned ubytearr_q_t [$];
        int unsigned uart_time_frame = (1e9)/UART_BAUDRATE;

        byte uart_data;
        ubytearr_q_t coremark_info_byte;
        string coremark_info_str;

        string coremark_finish_msg = "Correct operation validated.";

        function string ascii_to_str(ubytearr_t ascii);
            automatic string str = "";
            foreach(ascii[i]) begin
                str = {str, string'(ascii[i])};
            end
            return str;
        endfunction

        task automatic get_uart_transaction(output byte data);
            forever begin
                @(negedge uart_rxd_out);
                #(uart_time_frame/2);
                if(uart_rxd_out == 0) begin
                    for(int i = 0; i < 8; i++) begin
                        #uart_time_frame;
                        data += uart_rxd_out << i;
                    end
                    #uart_time_frame;
                    if(uart_rxd_out != ^data) begin
                        $error("Parity check failed");
                        continue;
                    end
                    #uart_time_frame;
                    if(uart_rxd_out != 1) begin
                        $error("Stop bit didn't found");
                        continue;
                    end
                    break;
                end
            end
        endtask

        initial begin
            forever begin
                get_uart_transaction(uart_data);
                coremark_info_byte.push_back(uart_data);
                if( ascii_to_str('{uart_data}) == "\n" ) begin
                    coremark_info_str = ascii_to_str(coremark_info_byte);
                    $display("CoreMark: ", coremark_info_str);
                    coremark_info_byte = '{};
                end
                if( coremark_info_str == coremark_finish_msg) begin
                    break;
                end
            end
        end
    `endif

endmodule
