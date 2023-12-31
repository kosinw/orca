`timescale 1ns / 1ps
`default_nettype none

`include "hdl/riscv_constants.sv"

module core_tb;
    logic clk_in;
    logic rst_in;
    logic step_in;

    logic [31:0] imem_data_in;
    logic [31:0] imem_addr_out;

    logic [31:0] dmem_addr_out;
    logic [31:0] dmem_data_out;
    logic [3:0] dmem_write_enable_out;
    logic [31:0] dmem_data_in;

    logic [31:0] cycle;

    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(32),
        .RAM_DEPTH(16384),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE("data/program.mem")
    ) imem (
        .addra(imem_addr_out[15:2]),
        .dina(32'h0),
        .clka(clk_in),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(1'b0),
        .regcea(1'b1),
        .douta(imem_data_in)
    );

    xilinx_true_dual_port_read_first_byte_write_2_clock_ram #(
        .NB_COL(4),
        .COL_WIDTH(8),
        .RAM_DEPTH(16384),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE("data/program.mem")
    ) dmem (
        .addrb(dmem_addr_out[15:2]),
        .dinb(dmem_data_out),
        .clkb(clk_in),
        .web(dmem_write_enable_out),
        .enb(1'b1),
        .rstb(1'b0),
        .regceb(1'b1),
        .doutb(dmem_data_in)
    );

    riscv_core uut (
        .clk_in(clk_in),
        .rst_in(rst_in),

        .cpu_step_in(step_in),

        .imem_data_in(imem_data_in),
        .imem_addr_out(imem_addr_out),

        .dmem_addr_out(dmem_addr_out),
        .dmem_data_out(dmem_data_out),
        .dmem_write_enable_out(dmem_write_enable_out),
        .dmem_data_in(dmem_data_in)
    );

    always begin
        #5;
        clk_in = !clk_in;
        // step_in = $random();
        step_in = 1'b1;
    end

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            cycle <= 0;
        end else begin
            cycle <= cycle + 1;
        end
    end

    initial begin
        $dumpfile("vcd/dump.vcd");
        $dumpvars(0,core_tb);
        $display("Starting simulation...");

        step_in = 0;
        clk_in = 0;
        rst_in = 1;

        #10;
        rst_in = 0;

        #20_000;

        $display("Finishing simulation...");
        $finish;
    end
endmodule
`default_nettype wire