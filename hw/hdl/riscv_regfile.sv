`timescale 1ns / 1ps
`default_nettype none

module riscv_regfile(
    input wire clk_in,
    input wire rst_in,
    input wire write_enable_in,

    input wire [4:0] ra_in,
    input wire [4:0] rb_in,
    input wire [4:0] rd_in,

    input  wire  [31:0] wd_in,
    output logic [31:0] rd1_out,
    output logic [31:0] rd2_out,

    input wire [4:0] reg_debug_in,
    output logic [31:0] reg_debug_out
);
    // 32 registers of 32-bit width
    logic [31:0] registers [31:0];

    assign rd1_out = registers[ra_in];
    assign rd2_out = registers[rb_in];
    assign reg_debug_out = registers[reg_debug_in];

    // always set to 0
    initial registers[0] = 32'b0;

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            for (integer i = 1; i < 32; i = i + 1)
                registers[i] <= 32'b0;
        end else if (write_enable_in && rd_in != 5'b0) begin
            registers[rd_in] <= wd_in;
        end
    end
endmodule