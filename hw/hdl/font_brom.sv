`timescale 1ns / 1ps
`default_nettype none

module font_brom#(
    parameter FONT_INIT_FILE = ""
)
(
    input wire clk_hdmi_in,
    input wire rst_in,
    input wire valid_in,
    input wire [2:0] x_in,
    input wire [3:0] y_in,
    input wire [7:0] code_point_in,
    input wire [7:0] attribute_in,
    output logic [7:0] attribute_out,
    output logic pixel_out,
    output logic valid_out
);
    logic [127:0] character_data;

    assign pixel_out = (valid_out)?character_data[{y_in,x_in}]:0;

    pipeline#(
        .PIPELINE_STAGES(2),
        .PIPELINE_WIDTH(9)
    ) control_signal_pipeline (
        .clk_in(clk_hdmi_in),
        .rst_in(rst_in),
        .signal_in({valid_in,attribute_in}),
        .signal_out({valid_out,attribute_out})
    );

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(128),
        .RAM_DEPTH(256),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(FONT_INIT_FILE)
    ) brom (
        .addra(code_point_in),
        .dina(128'h0),
        .clka(clk_hdmi_in),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(character_data)
    );
endmodule

`default_nettype wire