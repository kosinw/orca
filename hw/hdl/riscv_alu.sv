`include "hdl/riscv_constants.sv"

`timescale 1ns / 1ps
`default_nettype none

module riscv_alu (
    input  wire              clk_in,
    input  wire              rst_in,
    input  wire     [4:0]    alu_func_in,
    input  wire     [2:0]    br_func_in,
    input  wire     [31:0]   a_in,
    input  wire     [31:0]   b_in,
    input  wire              valid_in,
    output logic    [31:0]   result_out,
    output logic             branch_taken_out,
    output logic             result_ready_out
);
    logic               division;

    logic signed [31:0] a_sign;
    logic signed [31:0] b_sign;
    logic        [31:0] quot_buffer;
    logic        [31:0] rem_buffer;
    logic        [63:0] product;
    logic signed [63:0] product_sign;

    logic               division_finished;
    logic               divider_error;
    logic               divider_unit_finished;

    assign a_sign = a_in;
    assign b_sign = b_in;

    assign division = (alu_func_in == `ALU_FUNC_DIV) || (alu_func_in == `ALU_FUNC_DIVU) ||
                      (alu_func_in == `ALU_FUNC_REM) || (alu_func_in == `ALU_FUNC_REMU);

    assign result_ready_out = !division || (!valid_in && division_finished);

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
            `ALU_FUNC_COPY2:    result_out = b_in;
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
            `ALU_FUNC_MUL: begin
                product = a_in * b_in;
                result_out = product[31:0];
            end
            `ALU_FUNC_MULH: begin
                product_sign = a_sign * b_sign;
                result_out = product_sign[63:32];
            end
            `ALU_FUNC_MULHSU: begin
                product_sign = $signed(a_sign) * $unsigned(b_in);
                result_out = product_sign[63:32];
            end
            `ALU_FUNC_MULHU: begin
                product = a_in * b_in;
                result_out = product[63:32];
            end
            `ALU_FUNC_DIV: begin
                result_out = (divider_error) ? 32'hffffffff : quot_buffer;   // TODO(kosinw): Change bits depending on [31]
            end
            `ALU_FUNC_DIVU: begin
                result_out = (divider_error) ? 32'hffffffff : quot_buffer;
            end
            `ALU_FUNC_REM: begin
                result_out = (divider_error) ? 32'hffffffff : rem_buffer;   // TODO(kosinw): Change bits depending on [31]
            end
            `ALU_FUNC_REMU: begin
                result_out = (divider_error) ? a_in : rem_buffer;
            end
            default:            result_out = `ZERO;
        endcase
    end

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            division_finished <= 0;
        end else begin
            if (valid_in) begin
                division_finished <= 0;
            end else if (divider_unit_finished) begin
                division_finished <= 1;
            end
        end
    end

    divider2 divider_unit (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .dividend_in(a_in),
        .divisor_in(b_in),
        .data_valid_in(valid_in && division),
        .quotient_out(quot_buffer),
        .remainder_out(rem_buffer),
        .data_valid_out(divider_unit_finished),
        .error_out(divider_error),
        .busy_out()
    );
endmodule