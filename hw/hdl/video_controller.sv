`timescale 1ns / 1ps
`default_nettype none

module video_controller#(
    parameter TEXT_INIT_FILE = "",
    parameter FONT_INIT_FILE = "",
    parameter PALETTE_INIT_FILE = ""
)
(
    input wire clk_hdmi_in,
    input wire rst_in,
    output logic vsync_out,
    output logic hsync_out,
    output logic active_draw_out,
    output logic new_frame_out,
    output logic [7:0] red,
    output logic [7:0] green,
    output logic [7:0] blue
);
    logic [10:0] hcount;
    logic [9:0] vcount;
    logic active_draw;

    logic [5:0] vsg_frame_count;
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

    )  (

    );

    logic mdm_valid;
    logic [2:0] mdm_x;
    logic [3:0] mdm_y;
    logic [7:0] mdm_code_point, mdm_attribute;

    video_bram#(
        .TEXT_INIT_FILE(TEXT_INIT_FILE)
    ) mdm (
        .clk_hdmi_in(clk_hdmi_in),
        .rst_in(rst_in),
        .hcount_in(hcount),
        .vcount_in(vcount),
        .active_draw_in(active_draw),
        .valid_out(mdm_valid),
        .x_out(mdm_x),
        .y_out(mdm_y),
        .code_point_out(mdm_code_point),
        .attribute_out(mdm_attribute)
    );

    logic mfb_valid, mfb_pixel;
    logic [7:0] mfb_attribute;

    font_brom#(
        .FONT_INIT_FILE(FONT_INIT_FILE)
    ) mfb (
        .clk_hdmi_in(clk_hdmi_in),
        .rst_in(rst_in),
        .valid_in(mdm_valid),
        .x_in(mdm_x),
        .y_in(mdm_y),
        .code_point_in(mdm_code_point),
        .attribute_in(mdm_attribute),
        .attribute_out(mfb_attribute),
        .pixel_out(mfb_pixel),
        .valid_out(mfb_valid)
    );
endmodule

`default_nettype wire