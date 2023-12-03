`timescale 1ns / 1ps
`default_nettype none

module video_controller_tb;
    logic pixel_clk_in;
    logic rst_in;

    logic vsync, hsync, active_draw, new_frame;
    logic [7:0] red, green, blue;

    logic [31:0] cpu_addr_in;
    logic [31:0] cpu_data_in;
    logic [3:0] cpu_write_enable_in;
    logic [31:0] cpu_data_out;

    video_controller uut(
        .clk_hdmi_in(pixel_clk_in),
        .rst_in(rst_in),
        .vsync_out(vsync),
        .hsync_out(hsync),
        .active_draw_out(active_draw),
        .new_frame_out(new_frame),
        .red_out(red),
        .green_out(green),
        .blue_out(blue),

        .cpu_addr_in(cpu_addr_in),
        .cpu_data_in(cpu_data_in),
        .cpu_write_enable_in(cpu_write_enable_in),
        .cpu_data_out(cpu_data_out)
    );

    always begin
        #5;
        pixel_clk_in = !pixel_clk_in;
    end

    initial begin
        $dumpfile("vcd/video_controller.vcd");  // file to store value change dump (vcd)
        $dumpvars(0,video_controller_tb);       // store everything at current level and below
        $display("Starting simulation...");
        pixel_clk_in = 0;
        rst_in = 0;
        #10;
        rst_in = 1;
        #10;
        rst_in = 0;
        // #13_000_010;
        #13_000;
        $display("Finishing simulation...");
        $finish;
    end
endmodule

`default_nettype wire