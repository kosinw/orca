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
    output logic [31:0] cpu_data_out
);
    logic [3:0] cpu_write_enable;
    logic cpu_addr_in_range;

    assign cpu_addr_in_range = (cpu_addr_in[19:16] === 4'h2);
    assign cpu_write_enable = (cpu_addr_in_range) ? cpu_write_enable_in : 4'b0000;

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(32),
        .RAM_DEPTH(16384),
        .RAM_PERFORMANCE("LOW_LATENCY"),
        .INIT_FILE(`FPATH(program.mem))
    ) imem (
        .addra(pc_in[13:2]),
        .dina(32'h0),
        .clka(clk_in),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(instr_out)
    );

    xilinx_true_dual_port_read_first_byte_write_2_clock_ram #(
        .NB_COL(4),                           // Specify number of columns (number of bytes)
        .COL_WIDTH(8),                        // Specify column width (byte width, typically 8 or 9)
        .RAM_DEPTH(16384),                    // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
        .INIT_FILE(`FPATH(program.mem))
    ) dmem (
        .addra(12'b0),
        .dina(32'h0),
        .clka(clk_in),
        .wea(4'b0),
        .ena(1'b0),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(),

        .addrb(cpu_addr_in[13:2]),
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