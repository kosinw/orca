`timescale 1ns / 1ps
`default_nettype none

module ps2_rx_tb;
    logic clk_in, rst_in, ps2_clk_in, ps2_data_in;
    logic valid_out, error_out;
    logic [7:0] scancode_out;

    localparam integer H_SCANCODE = 11'b11_00110011_0;
    localparam integer E_SCANCODE = 11'b11_00100100_0;
    localparam integer BAD_SCANCODE = 11'b11_00110100_0;

    ps2_rx uut(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .ps2_clk_in(ps2_clk_in),
        .ps2_data_in(ps2_data_in),
        .valid_out(valid_out),
        .error_out(error_out),
        .scancode_out(scancode_out)
    );

    always begin
        #5;
        clk_in = !clk_in;
    end

    initial begin
        $dumpfile("vcd/ps2_rx.vcd");    // file to store value change dump
        $dumpvars(0,ps2_rx_tb);         // store everything at current level and below
        $display("Starting simulation...");

        clk_in = 0;
        rst_in = 0;
        ps2_clk_in = 1;
        ps2_data_in = 1;
        #5;
        rst_in = 1;
        #20;
        rst_in = 0;

        #180_239;

        // send scancode for charater 'H'
        // send data at ~16khz clock rate
        for (integer i = 0; i < 11; i = i + 1) begin
            ps2_data_in = H_SCANCODE[i];
            #250;
            ps2_clk_in = 0;
            #31250;
            ps2_clk_in = 1;
            #31000;
        end

        ps2_data_in = 1'b1;

        #180_867;

        // send scancode for charater 'E'
        // send data at ~16khz clock rate
        for (integer i = 0; i < 11; i = i + 1) begin
            ps2_data_in = E_SCANCODE[i];
            #250;
            ps2_clk_in = 0;
            #31250;
            ps2_clk_in = 1;
            #31000;
        end

        // send scancode for some character with invalid parity
        // send data at ~16khz clock rate
        for (integer i = 0; i < 11; i = i + 1) begin
            ps2_data_in = BAD_SCANCODE[i];
            #250;
            ps2_clk_in = 0;
            #31250;
            ps2_clk_in = 1;
            #31000;
        end

        ps2_data_in = 1'b1;
        $display("Finishing simulation...");
        $finish;
    end
endmodule
`default_nettype wire