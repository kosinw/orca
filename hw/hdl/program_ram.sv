`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

module program_ram (
    input wire clk_in,
    input wire rst_in,
    input wire [31:0] pc_in,
    output logic [31:0] instr_out,

    input wire [31:0] cpu_addr_in,
    input wire [31:0] cpu_data_in,
    input wire [3:0] cpu_write_enable_in,
    output logic [31:0] cpu_data_out,

    input wire [31:0] brx_addr_in,
    input wire [31:0] brx_data_in,
    input wire brx_valid_in
);
    logic [3:0] cpu_write_enable;
    logic cpu_addr_in_range;

    assign cpu_addr_in_range = (cpu_addr_in < 32'h20000);
    assign cpu_write_enable = (cpu_addr_in_range) ? cpu_write_enable_in : 4'b0000;

    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(32),
        .RAM_DEPTH(16384),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE")
    ) imem (
        .addra(pc_in[15:2]),
        .dina(32'h0),
        .clka(clk_in),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(instr_out),

        .addrb(brx_addr_in[15:2]),
        .dinb(brx_data_in),
        .clkb(clk_in),
        .web(brx_valid_in),
        .enb(1'b1),
        .rstb(rst_in),
        .regceb(1'b1),
        .doutb()
    );

    xilinx_true_dual_port_read_first_byte_write_2_clock_ram #(
        .NB_COL(4),
        .COL_WIDTH(8),
        .RAM_DEPTH(16384),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE")
    ) dmem (
        .addra(brx_addr_in[15:2]),
        .dina(brx_data_in),
        .clka(clk_in),
        .wea({4{brx_valid_in}}),
        .ena(1'b1),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(),

        .addrb(cpu_addr_in[15:2]),
        .dinb(cpu_data_in),
        .clkb(clk_in),
        .web(cpu_write_enable),
        .enb(1'b1),
        .rstb(rst_in),
        .regceb(1'b1),
        .doutb(cpu_data_out)
    );
endmodule

`default_nettype wire