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

    logic [31:0] dmem_data_out;

    //
    // memory map
    //  [000000000-00000ffff]   GENERAL PURPOSE MEMORY
    //  [000010000-000010003]   COUNTER
    //  [000010004-000010007]   ENTROPY SOURCE
    //

    assign cpu_addr_in_range = (cpu_addr_in < 32'h10000);
    assign cpu_write_enable = (cpu_addr_in_range) ? cpu_write_enable_in : 4'b0000;

    logic [31:0]    MMIO_COUNTER;
    logic [31:0]    MMIO_ENTROPY;
    logic [5:0]     little_counter;

    always_comb begin
        cpu_data_out = 0;

        if (cpu_addr_in_range) begin
            cpu_data_out = dmem_data_out;
        end else if (cpu_addr_in[31:2] == 32'h4000) begin
            cpu_data_out = MMIO_COUNTER;
        end else if (cpu_addr_in[31:2] == 32'h4001) begin
            cpu_data_out = MMIO_ENTROPY;
        end
    end

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            MMIO_COUNTER <= 0;
            little_counter <= 0;
        end else begin
            little_counter <= (little_counter == 6'd50) ? 0 : little_counter + 1;
            MMIO_COUNTER <= (little_counter == 6'd50) ? MMIO_COUNTER + 1 : MMIO_COUNTER;
        end
    end

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
        .doutb(dmem_data_out)
    );

    lfsr_32 lfsr (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .lfsr_out(MMIO_ENTROPY)
    );
endmodule

`default_nettype wire