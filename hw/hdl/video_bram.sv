`timescale 1ns / 1ps
`default_nettype none

module video_bram#(
    parameter TEXT_INIT_FILE = ""
)
(
    input wire clk_hdmi_in,
    input wire rst_in,
    input wire [10:0] hcount_in,
    input wire [9:0] vcount_in,
    input wire active_draw_in,
    output logic valid_out,
    output logic [2:0] x_out,
    output logic [3:0] y_out,
    output logic [7:0] code_point_out,
    output logic [7:0] attribute_out
);
    logic [2:0] x_in;
    logic [3:0] y_in;

    logic [15:0] frame_buffer_data;
    logic [12:0] frame_buffer_addr;

    assign {code_point_out,attribute_out} = frame_buffer_data;
    assign x_in = hcount_in[2:0];
    assign y_in = vcount_in[3:0];
    assign frame_buffer_addr = (active_draw_in)?(160*vcount_in[9:4])+hcount_in[10:3]:0;

    pipeline#(
        .PIPELINE_STAGES(2),
        .PIPELINE_WIDTH(8)
    ) control_signal_pipeline (
        .clk_in(clk_hdmi_in),
        .rst_in(rst_in),
        .signal_in({x_in,y_in,active_draw_in}),
        .signal_out({x_out,y_out,valid_out})
    );

    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(16),
        .RAM_DEPTH(160*45),
        .INIT_FILE(TEXT_INIT_FILE)
    ) bram (
        .addra(13'b0),
        .clka(clk_hdmi_in), // change me
        .wea(1'b0),
        .dina(16'b0),
        .ena(1'b0),
        .regcea(1'b0),
        .rsta(1'b0),
        .douta(),

        .addrb(frame_buffer_addr),
        .dinb(16'b0),
        .clkb(clk_hdmi_in),
        .web(1'b0),
        .enb(1'b1),
        .rstb(rst_in),
        .regceb(1'b1),
        .doutb(frame_buffer_data)
    );
endmodule

`default_nettype wire