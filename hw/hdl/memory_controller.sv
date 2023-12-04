`timescale 1ns / 1ps
`default_nettype none

module memory_controller(
    input wire clk_cpu_in,
    input wire rst_in,

    // cpu port
    input wire   [31:0] cpu_addr_in,
    input wire   [31:0] cpu_data_in,
    input wire   [3:0]  cpu_write_enable_in,
    output logic [31:0] cpu_data_out,

    // video memory port
    output logic [31:0] video_addr_out,
    output logic [31:0] video_data_out,
    output logic [3:0]  video_write_enable_out,
    input wire   [31:0] video_data_in,

    // RAM port
    output logic [31:0] ram_addr_out,
    output logic [31:0] ram_data_out,
    output logic [3:0]  ram_write_enable_out,
    input wire   [31:0] ram_data_in,

    // keyboard module port
    output logic [31:0] keyboard_addr_out,
    output logic [31:0] keyboard_data_out,
    output logic [3:0]  keyboard_write_enable_out,
    input wire   [31:0] keyboard_data_in
);
    assign video_addr_out = cpu_addr_in;
    assign video_data_out = cpu_data_in;
    assign video_write_enable_out = cpu_write_enable_in;

    assign ram_addr_out = cpu_addr_in;
    assign ram_data_out = cpu_data_in;
    assign ram_write_enable_out = cpu_write_enable_in;

    assign keyboard_addr_out = cpu_addr_in;
    assign keyboard_data_out = cpu_data_in;
    assign keyboard_write_enable_out = cpu_write_enable_in;

    logic [3:0] cpu_addr_top;

    pipeline#(
        .PIPELINE_STAGES(2),
        .PIPELINE_WIDTH(4)
    ) addr_pipeline (
        .clk_in(clk_cpu_in),
        .rst_in(rst_in),
        .signal_in(cpu_addr_in[19:16]),
        .signal_out(cpu_addr_top)
    );

    always_comb begin
        case (cpu_addr_top)
            4'h0, 4'h1: cpu_data_out = ram_data_in;
            4'h2:       cpu_data_out = video_data_in;
            4'h3:       cpu_data_out = keyboard_data_in;
            // todo aes and spi
            default:    cpu_data_out = ram_data_in;
        endcase
    end

endmodule