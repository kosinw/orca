`timescale 1ns / 1ps
`default_nettype none

module top_level(
    input wire clk_100mhz,
    input wire [15:0] sw,
    input wire [3:0] btn,
    output logic [15:0] led,
    output logic [2:0] hdmi_tx_p,           // hdmi output signals (blue, green, red)
    output logic [2:0] hdmi_tx_n,           // hdmi output signals (negatives)
    output logic hdmi_clk_p, hdmi_clk_n,    // differential hdmi clock
    output logic [2:0] rgb0,
    output logic [2:0] rgb1
);
    ////////////////////////////////////////////////////////////
    // DECLARATIONS
    ////////////////////////////////////////////////////////////

    // turn off bright LEDs
    assign rgb1 = 0;
    assign rgb0 = 0;

    // have btn[0] control resetting system
    logic sys_rst;
    assign sys_rst = btn[0];

    // clock domains
    logic clk_74mhz, clk_371mhz;    // 74.25 MHz hdmi clock and 371.25 MHz
    logic locked_u;                 // locked signal (unused)

    // tmds
    logic [9:0] tmds_10b [0:2];     // output of TMDS encoder
    logic tmds_signal [2:0];        // output of TMDS serializer

    // video controller

    ////////////////////////////////////////////////////////////
    // BLOCKS
    ////////////////////////////////////////////////////////////

    hdmi_clk_wiz_720p hdmicw (
        .clk_pixel(clk_74mhz),
        .clk_tmds(clk_371mhz),
        .reset(0),
        .locked(locked_u),
        .clk_ref(clk_100mhz)
    );

    tmds_encoder tmds_encoder_red(
        .clk_in(clk_74mhz),
        .rst_in(sys_rst),
        .data_in(video_red),
        .control_in(2'b0),
        .ve_in(video_active_draw),
        .tmds_out(tmds_10b[2])
    );

    tmds_encoder tmds_encoder_green(
        .clk_in(clk_74mhz),
        .rst_in(sys_rst),
        .data_in(video_green),
        .control_in(2'b0),
        .ve_in(video_active_draw),
        .tmds_out(tmds_10b[1])
    );

    tmds_encoder tmds_encoder_blue(
        .clk_in(clk_74mhz),
        .rst_in(sys_rst),
        .data_in(video_blue),
        .control_in({video_vsync, video_hsync}),
        .ve_in(video_active_draw),
        .tmds_out(tmds_10b[0])
    );

    tmds_serializer tmds_serializer_red(
        .clk_in(clk_74mhz),
        .clk_5x_in(clk_371mhz),
        .rst_in(sys_rst),
        .tmds_in(tmds_10b[2]),
        .tmds_out(tmds_signal[2])
    );

    tmds_serializer tmds_serializer_green(
        .clk_in(clk_74mhz),
        .clk_5x_in(clk_371mhz),
        .rst_in(sys_rst),
        .tmds_in(tmds_10b[1]),
        .tmds_out(tmds_signal[1])
    );

    tmds_serializer tmds_serializer_blue(
        .clk_in(clk_74mhz),
        .clk_5x_in(clk_371mhz),
        .rst_in(sys_rst),
        .tmds_in(tmds_10b[0]),
        .tmds_out(tmds_signal[0])
    );

    OBUFDS OBUFDS_blue (.I(tmds_signal[0]), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));
    OBUFDS OBUFDS_green(.I(tmds_signal[1]), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
    OBUFDS OBUFDS_red  (.I(tmds_signal[2]), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
    OBUFDS OBUFDS_clock(.I(clk_74mhz), .O(hdmi_clk_p), .OB(hdmi_clk_n));

endmodule