`timescale 1ns / 1ps
`default_nettype none

`include "hdl/riscv_constants.sv"

module riscv_core_tb;
    logic [31:0] INSTRUCTIONS [34:0];

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

        .imem_data_in(imem_data_in),
        .imem_addr_out(imem_addr_out),

        .dmem_addr_out(dmem_addr_out),
        .dmem_data_out(dmem_data_out),
        .dmem_write_enable_out(dmem_write_enable_out),
        .dmem_data_in(dmem_data_in)
    );

    initial begin
        INSTRUCTIONS[ 0] = 32'h000cb197;     // auipc x3, 203
        INSTRUCTIONS[ 1] = 32'h00013237;     // lui x4, 19

        INSTRUCTIONS[ 2] = 32'hff1fff6f;     // jal x30, -16
        INSTRUCTIONS[ 3] = 32'hff0207e7;     // jalr x15, -16(x4)

        INSTRUCTIONS[ 4] = 32'h00208763;     // beq x1, x2, 14
        INSTRUCTIONS[ 5] = 32'h00209763;     // bne x1, x2, 14
        INSTRUCTIONS[ 6] = 32'h0020c763;     // blt x1, x2, 14
        INSTRUCTIONS[ 7] = 32'h0020d763;     // bge x1, x2, 14
        INSTRUCTIONS[ 8] = 32'h0020e763;     // bltu x1, x2, 14
        INSTRUCTIONS[ 9] = 32'h0020f763;     // bgeu x1, x2, 14

        INSTRUCTIONS[10] = 32'hfe808583;     // lb x11, -24(x1)
        INSTRUCTIONS[11] = 32'hfe809583;     // lh x11, -24(x1)
        INSTRUCTIONS[12] = 32'hfc00a583;     // lw x11, -64(x1)
        INSTRUCTIONS[13] = 32'hfe80c583;     // lbu x11, -24(x1)
        INSTRUCTIONS[14] = 32'hfe80d583;     // lhu x11, -24(x1)

        INSTRUCTIONS[15] = 32'hfeb08423;     // sb x11, -24(x1)
        INSTRUCTIONS[16] = 32'hfeb09423;     // sh x11, -24(x1)
        INSTRUCTIONS[17] = 32'hfeb0a423;     // sw x11, -24(x1)

        INSTRUCTIONS[18] = 32'h03788493;     // addi x9, x17, 55
        INSTRUCTIONS[19] = 32'h0378a493;     // slti x9, x17, 55
        INSTRUCTIONS[20] = 32'h0378b493;     // sltiu x9, x17, 55
        INSTRUCTIONS[21] = 32'h0378c493;     // xori x9, x17, 55
        INSTRUCTIONS[22] = 32'h0378e493;     // ori x9, x17, 55
        INSTRUCTIONS[23] = 32'h0378f493;     // andi x9, x17, 55
        INSTRUCTIONS[24] = 32'h00889493;     // slli x9, x17, 8
        INSTRUCTIONS[25] = 32'h0088d493;     // srli x9, x17, 8
        INSTRUCTIONS[26] = 32'h4088d493;     // srai x9, x17, 8

        INSTRUCTIONS[27] = 32'h00838333;     // add x6, x7, x8
        INSTRUCTIONS[28] = 32'h40838333;     // sub x6, x7, x8
        INSTRUCTIONS[29] = 32'h00839333;     // sll x6, x7, x8
        INSTRUCTIONS[29] = 32'h0083a333;     // slt x6, x7, x8
        INSTRUCTIONS[30] = 32'h0083b333;     // sltu x6, x7, x8
        INSTRUCTIONS[31] = 32'h0083c333;     // xor x6, x7, x8
        INSTRUCTIONS[31] = 32'h0083d333;     // srl x6, x7, x8
        INSTRUCTIONS[32] = 32'h4083d333;     // sra x6, x7, x8
        INSTRUCTIONS[33] = 32'h0083e333;     // or x6, x7, x8
        INSTRUCTIONS[34] = 32'h0083f333;     // and x6, x7, x8
    end

    always begin
        #5;
        clk_in = !clk_in;
    end

    initial begin
        $dumpfile("vcd/riscv_core.vcd");
        $dumpvars(0,riscv_core_tb);
        $display("Starting simulation...");

        clk_in = 0;
        rst_in = 1;
        imem_data_in = `NOP;
        dmem_data_in = 32'hDEADBEEF;

        #25;
        rst_in = 0;

        for (integer i = 0; i <= 34; i = i + 1) begin
            imem_data_in = INSTRUCTIONS[i];
            #10;
        end

        #100;

        $display("Finishing simulation...");
        $finish;
    end
endmodule
`default_nettype wire