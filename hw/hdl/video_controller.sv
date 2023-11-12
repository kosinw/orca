`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

module video_controller#(
    parameter TEXT_INIT_FILE = `FPATH(text.mem),
    parameter FONT_INIT_FILE = `FPATH(font.mem)
)
(
    input wire clk_hdmi_in,
    input wire rst_in,
    output logic vsync_out,
    output logic hsync_out,
    output logic active_draw_out,
    output logic new_frame_out,
    output logic [7:0] red_out,
    output logic [7:0] green_out,
    output logic [7:0] blue_out
);
    logic [10:0] hcount;
    logic [9:0] vcount;
    logic active_draw;

    logic [5:0] vsg_frame_count, frame_count;
    logic vsg_vsync, vsg_hsync, vsg_new_frame;

    video_sig_gen vsg(
        .clk_pixel_in(clk_hdmi_in),
        .rst_in(rst_in),
        .hcount_out(hcount),
        .vcount_out(vcount),
        .vs_out(vsg_vsync),
        .hs_out(vsg_hsync),
        .ad_out(active_draw),
        .nf_out(vsg_new_frame),
        .fc_out(vsg_frame_count)
    );

    pipeline#(
        .PIPELINE_STAGES(5),
        .PIPELINE_WIDTH(4)
    ) output_pipeline (
        .clk_in(clk_hdmi_in),
        .rst_in(rst_in),
        .signal_in({vsg_vsync, vsg_hsync, active_draw, vsg_new_frame}),
        .signal_out({vsync_out, hsync_out, active_draw_out, new_frame_out})
    );

    pipeline#(
        .PIPELINE_STAGES(4),
        .PIPELINE_WIDTH(6)
    ) frame_counter_pipeline (
        .clk_in(clk_hdmi_in),
        .rst_in(rst_in),
        .signal_in(vsg_frame_count),
        .signal_out(frame_count)
    );

    logic mvb_valid;
    logic [2:0] mvb_x;
    logic [3:0] mvb_y;
    logic [7:0] mvb_code_point, mvb_attribute;

    video_bram#(
        .TEXT_INIT_FILE(TEXT_INIT_FILE)
    ) mvb (
        .clk_hdmi_in(clk_hdmi_in),
        .rst_in(rst_in),
        .hcount_in(hcount),
        .vcount_in(vcount),
        .active_draw_in(active_draw),
        .valid_out(mvb_valid),
        .x_out(mvb_x),
        .y_out(mvb_y),
        .code_point_out(mvb_code_point),
        .attribute_out(mvb_attribute)
    );

    logic mfb_valid, mfb_pixel;
    logic [7:0] mfb_attribute;

    font_brom#(
        .FONT_INIT_FILE(FONT_INIT_FILE)
    ) mfb (
        .clk_hdmi_in(clk_hdmi_in),
        .rst_in(rst_in),
        .valid_in(mvb_valid),
        .x_in(mvb_x),
        .y_in(mvb_y),
        .code_point_in(mvb_code_point),
        .attribute_in(mvb_attribute),
        .attribute_out(mfb_attribute),
        .pixel_out(mfb_pixel),
        .valid_out(mfb_valid)
    );

    attribute_brom mab (
        .clk_hdmi_in(clk_hdmi_in),
        .rst_in(rst_in),
        .pixel_in(mfb_pixel),
        .valid_in(mfb_valid),
        .attribute_in(mfb_attribute),
        .frame_count_in(frame_count),
        .red_out(red_out),
        .blue_out(blue_out),
        .green_out(green_out)
    );
endmodule

`default_nettype wire