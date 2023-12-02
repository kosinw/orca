`include "hdl/riscv_constants.sv"

`timescale 1ns / 1ps
`default_nettype none

module riscv_alu(
    input  wire     [3:0]    alu_func_in,
    input  wire     [2:0]    br_func_in,
    input  wire     [31:0]   a_in,
    input  wire     [31:0]   b_in,
    output logic    [31:0]   result_out,
    output logic             branch_taken_out
);
    logic signed [31:0] a_sign;
    logic signed [31:0] b_sign;

    assign a_sign = a_in;
    assign b_sign = b_in;

    always_comb begin
        branch_taken_out = `OFF;

        case (alu_func_in)
            `ALU_FUNC_ADD:      result_out = a_in + b_in;
            `ALU_FUNC_SUB:      result_out = a_in - b_in;
            `ALU_FUNC_SLL:      result_out = (a_in << b_in[4:0]);
            `ALU_FUNC_SLT:      result_out = {31'b0,a_sign<b_sign};
            `ALU_FUNC_SLTU:     result_out = {31'b0,a_in<b_in};
            `ALU_FUNC_XOR:      result_out = a_in ^ b_in;
            `ALU_FUNC_SRL:      result_out = (a_sign >> b_in[4:0]);
            `ALU_FUNC_SRA:      result_out = (a_sign >>> b_in[4:0]);
            `ALU_FUNC_OR:       result_out = a_in | b_in;
            `ALU_FUNC_AND:      result_out = a_in & b_in;
            `ALU_FUNC_JALR:     begin
                result_out = a_in+b_in;
                result_out = {result_out[31:1],1'b0};
            end
            `ALU_FUNC_LUI:      result_out = b_in;
            `ALU_FUNC_BR:       begin
                result_out = `ZERO;
                case (br_func_in)
                    `BR_FUNC_EQ:    branch_taken_out = (a_in==b_in) ? `ON : `OFF;
                    `BR_FUNC_NE:    branch_taken_out = (a_in!=b_in) ? `ON : `OFF;
                    `BR_FUNC_LT:    branch_taken_out = (a_sign<b_sign) ? `ON : `OFF;
                    `BR_FUNC_GE:    branch_taken_out = (a_sign>=b_sign) ? `ON : `OFF;
                    `BR_FUNC_LTU:   branch_taken_out = (a_in<b_in) ? `ON : `OFF;
                    `BR_FUNC_GEU:   branch_taken_out = (a_in>=b_in) ? `ON : `OFF;
                    default:        branch_taken_out = `OFF;
                endcase
            end
            default:            result_out = `ZERO;
        endcase
    end
endmodule