`timescale 1ns / 1ps
`default_nettype none

module video_bram#(
    parameter INITIAL_VIDEO_BRAM = ""
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
    output logic [7:0] attribute_out,

    input wire [31:0] cpu_addr_in,
    input wire [31:0] cpu_data_in,
    input wire [3:0] cpu_write_enable_in,
    output logic [31:0] cpu_data_out
);
    logic [2:0] x_in;
    logic [3:0] y_in;

    logic [12:0] frame_buffer_addr;
    logic [31:0] douta;

    logic even;

    assign x_in = hcount_in[2:0];
    assign y_in = vcount_in[3:0];
    assign frame_buffer_addr = (active_draw_in)?(160*vcount_in[9:4])+hcount_in[10:3]:0;

    assign code_point_out = (even) ? douta[7:0] : douta[23:16];
    assign attribute_out = (even) ? douta[15:8] : douta[31:24];

    pipeline#(
        .PIPELINE_STAGES(2),
        .PIPELINE_WIDTH(9)
    ) control_signal_pipeline (
        .clk_in(clk_hdmi_in),
        .rst_in(rst_in),
        .signal_in({x_in,y_in,active_draw_in,!frame_buffer_addr[0]}),
        .signal_out({x_out,y_out,valid_out,even})
    );

    xilinx_true_dual_port_read_first_byte_write_2_clock_ram #(
        .NB_COL(4),                           // Specify number of columns (number of bytes)
        .COL_WIDTH(8),                        // Specify column width (byte width, typically 8 or 9)
        .RAM_DEPTH(80*45),                    // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
        .INIT_FILE(INITIAL_VIDEO_BRAM)        // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) bram (
        .addra(frame_buffer_addr[12:1]),
        .addrb(cpu_addr_in[11:0]),
        .dina(32'h0),
        .dinb(cpu_data_in),
        .clka(clk_hdmi_in),
        .clkb(clk_hdmi_in),
        .wea(4'b0),
        .web(cpu_write_enable_in),
        .ena(1'b1),
        .enb(1'b1),
        .rsta(rst_in),
        .rstb(rst_in),
        .regcea(1'b1),
        .regceb(1'b1),
        .douta(douta),
        .doutb(cpu_data_out)
    );
endmodule

`default_nettype wire