`timescale 1ns / 1ps
`default_nettype none

`include "hdl/riscv_constants.sv"

module core_tb;
    // reg [31:0] INSTRUCTIONS [0:16383];

    logic clk_in;
    logic rst_in;

    logic [31:0] imem_data_in;
    logic [31:0] imem_addr_out;

    logic [31:0] dmem_addr_out;
    logic [31:0] dmem_data_out;
    logic [3:0] dmem_write_enable_out;
    logic [31:0] dmem_data_in;


    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(32),
        .RAM_DEPTH(16384),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE("data/program.mem")
    ) imem (
        .addra(imem_addr_out[15:2]),
        .dina(32'h0),
        .clka(clk_in),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(imem_data_in)
    );

    riscv_core uut (
        .clk_in(clk_in),
        .rst_in(rst_in),

        .cpu_step_in(1'b1),

        .imem_data_in(imem_data_in),
        .imem_addr_out(imem_addr_out),

        .dmem_addr_out(dmem_addr_out),
        .dmem_data_out(dmem_data_out),
        .dmem_write_enable_out(dmem_write_enable_out),
        .dmem_data_in(dmem_data_in),

        .debug_in(8'b10000000),
        .debug_out()
    );

    always begin
        #5;
        clk_in = !clk_in;
    end

    initial begin
        $dumpfile("vcd/dump.vcd");
        $dumpvars(0,core_tb);
        $display("Starting simulation...");

        clk_in = 0;
        rst_in = 1;
        dmem_data_in = 32'hDEADBEEF;

        #25;
        rst_in = 0;

        #800;

        $display("Finishing simulation...");
        $finish;
    end
endmodule
`default_nettype wire