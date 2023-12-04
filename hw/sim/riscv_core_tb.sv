`timescale 1ns / 1ps
`default_nettype none

`define TESTBENCH
`include "hdl/riscv_constants.sv"

module riscv_core_tb;
    reg [31:0] INSTRUCTIONS [0:16383];

    logic clk_in;
    logic rst_in;

    logic [31:0] imem_data_in;
    logic [31:0] imem_addr_out;

    logic [31:0] dmem_addr_out;
    logic [31:0] dmem_data_out;
    logic [3:0] dmem_write_enable_out;
    logic [31:0] dmem_data_in;

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

    initial begin
        $display("Reading memory...");
        $readmemh("data/program.mem", INSTRUCTIONS);
    end

    always begin
        #5;
        clk_in = !clk_in;
    end

    always begin
        #10;
        imem_data_in = INSTRUCTIONS[imem_addr_out[31:2]];
    end

    initial begin
        $dumpfile("vcd/riscv_core.vcd");
        $dumpvars(0,riscv_core_tb);
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