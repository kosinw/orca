`timescale 1ns / 1ps
`default_nettype none

`include "hdl/riscv_constants.sv"

module riscv_alu_tb;
    logic [71:0] COMMANDS [13:0];

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

    initial begin
        COMMANDS[ 0] = {`ALU_FUNC_ADD,`BR_FUNC_NONE,32'd50,-32'd10};    // 50 + (-10) = 40
        COMMANDS[ 1] = {`ALU_FUNC_SUB,`BR_FUNC_NONE,-32'd30,32'd40};    // -30 - 40 = -70
        COMMANDS[ 2] = {`ALU_FUNC_SLL,`BR_FUNC_NONE,32'd256,32'd4};     // 256 << 4 = 4095
        COMMANDS[ 3] = {`ALU_FUNC_SLT,`BR_FUNC_NONE,-32'd1,32'd9};      // -1 < 9 = T
        COMMANDS[ 4] = {`ALU_FUNC_SLTU,`BR_FUNC_NONE,-32'd1,32'd9};     // -1 <u 9 = F
        COMMANDS[ 5] = {`ALU_FUNC_XOR,`BR_FUNC_NONE,32'h5F07,32'h1467};
        COMMANDS[ 6] = {`ALU_FUNC_SRL,`BR_FUNC_NONE,-32'd20,32'd2};
        COMMANDS[ 7] = {`ALU_FUNC_SRA,`BR_FUNC_NONE,-32'd20,32'd2};
        COMMANDS[ 8] = {`ALU_FUNC_OR,`BR_FUNC_NONE,32'h5F07,32'h1467};
        COMMANDS[ 9] = {`ALU_FUNC_AND,`BR_FUNC_NONE,32'h5F07,32'h1467};
        COMMANDS[10] = {`ALU_FUNC_JALR,`BR_FUNC_NONE,32'hC800,32'h3};
        COMMANDS[11] = {`ALU_FUNC_LUI,`BR_FUNC_NONE,32'hC800,32'h3};
        COMMANDS[12] = {`ALU_FUNC_BR,`BR_FUNC_GE,32'h0,32'h0};
        COMMANDS[13] = {`ALU_FUNC_BR,`BR_FUNC_GEU,-32'h1,32'h8FCD};
    end

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

        for (integer i = 0; i <= 13; i = i + 1) begin
            {alu_func_in,br_func_in,a_in,b_in} = COMMANDS[i];
            #10;
        end

        $display("Finishing simulation...");
        $finish;
    end
endmodule
`default_nettype wire