`timescale 1ns / 1ps
`default_nettype none

module top_level(
    input wire clk_100mhz,
    input wire [3:0] btn,
    input wire [15:0] sw,
    output logic [15:0] led,
    output logic uart_txd,
    input wire uart_rxd,
    output logic [2:0] rgb0,
    output logic [2:0] rgb1
);

    assign rgb1 = 0;
    assign rgb0 = 0;

    localparam CLK_DIVISION_COUNT = 32'd10_000 - 32'd1;

    logic [31:0] val1_in, val2_in, val3_out, val4_out;
    logic [31:0] counter;
    logic trigger_in;
    logic sys_rst;

    // scalar division
    logic [31:0] quotient_out, remainder_out;

    // floating point arithmetic
    logic [31:0] inv_sqrt_out, adder_out, mult1_out, mult2_out;
    logic adder_valid, mult1_valid, mult2_valid, inv_sqrt_valid;
    logic inv_sqrt_ready, adder_ready1, adder_ready2;
    logic mult1_ready1, mult1_ready2, mult2_ready1, mult2_ready2;

    assign sys_rst = btn[0];

    assign val1_in = (!sw[0]) ? quotient_out : inv_sqrt_out;
    assign val2_in = (!sw[0]) ? remainder_out : adder_out;
    assign trigger_in = (counter == CLK_DIVISION_COUNT);

    always_ff @(posedge clk_100mhz) begin
        if (sys_rst) begin
            counter <= 0;
        end else begin
            counter <= (counter == CLK_DIVISION_COUNT) ? 0 : counter + 1;
        end
    end

    manta manta_inst (
        .clk(clk_100mhz),

        .rx(uart_rxd),
        .tx(uart_txd),

        .val1_in(val1_in),
        .val2_in(val2_in),
        .val3_out(val3_out),
        .val4_out(val4_out));

    divider md (
        .clk_in(clk_100mhz),
        .rst_in(sys_rst),
        .dividend_in(val4_out),
        .divisor_in(val3_out),
        .data_valid_in(trigger_in),
        .quotient_out(quotient_out),
        .remainder_out(remainder_out),
        .data_valid_out(led[3]),
        .error_out(led[2]),
        .busy_out(led[1])
    );

    multiplier mm1 (
        .aclk(clk_100mhz),

        .s_axis_a_tdata(val4_out),
        .s_axis_a_tready(mult1_ready1),
        .s_axis_a_tvalid(trigger_in),

        .s_axis_b_tdata(val4_out),
        .s_axis_b_tready(mult1_ready2),
        .s_axis_b_tvalid(trigger_in),

        .m_axis_result_tdata(mult1_out),
        .m_axis_result_tready(adder_ready1),
        .m_axis_result_tvalid(mult1_valid)
    );

    multiplier mm2 (
        .aclk(clk_100mhz),

        .s_axis_a_tdata(val3_out),
        .s_axis_a_tready(mult2_ready1),
        .s_axis_a_tvalid(trigger_in),

        .s_axis_b_tdata(val3_out),
        .s_axis_b_tready(mult2_ready2),
        .s_axis_b_tvalid(trigger_in),

        .m_axis_result_tdata(mult2_out),
        .m_axis_result_tready(adder_ready2),
        .m_axis_result_tvalid(mult2_valid)
    );

    adder ma (
        .aclk(clk_100mhz),

        .s_axis_a_tdata(mult1_out),
        .s_axis_a_tready(adder_ready1),
        .s_axis_a_tvalid(mult1_valid),

        .s_axis_b_tdata(mult2_out),
        .s_axis_b_tready(adder_ready2),
        .s_axis_b_tvalid(mult2_valid),

        .m_axis_result_tdata(adder_out),
        .m_axis_result_tready(inv_sqrt_ready),
        .m_axis_result_tvalid(adder_valid)
    );

    inv_sqrt mis (
        .aclk(clk_100mhz),

        .s_axis_a_tdata(adder_out),
        .s_axis_a_tready(inv_sqrt_ready),
        .s_axis_a_tvalid(adder_valid),

        .m_axis_result_tdata(inv_sqrt_out),
        .m_axis_result_tready(1'b1),
        .m_axis_result_tvalid(inv_sqrt_valid)
    );

endmodule