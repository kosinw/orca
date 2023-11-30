`timescale 1ns / 1ps
`default_nettype none

`include "hdl/riscv_constants.sv"

module riscv_alu_tb;
    logic [71:0] COMMANDS []

    logic        clk_in;
    logic [3:0]  alu_func_in;
    logic [2:0]  br_func_in;
    logic [31:0] a_in;
    logic [31:0] b_in;
    logic [31:0] result_out;
    logic        branch_taken_out;

    riscv_alu uut(
        .alu_func_in(alu_func_in),
        .br_func_in(br_func_in),
        .a_in(a_in),
        .b_in(b_in),
        .result_out(result_out),
        .branch_taken_out(branch_taken_out)
    );

    always begin
        #5;
        clk_in = !clk_in;
    end

    initial begin
        $dumpfile("vcd/riscv_alu.vcd");    // file to store value change dump
        $dumpvars(0,riscv_alu_tb);         // store everything at current level and below
        $display("Starting simulation...");

        clk_in = 0;
        #5;

        for (integer i = 0; i <= 34; i = i + 1) begin
            inst_in = INSTRUCTIONS[i];
            #10;
        end

        $display("Finishing simulation...");
        $finish;
    end
endmodule
`default_nettype wire