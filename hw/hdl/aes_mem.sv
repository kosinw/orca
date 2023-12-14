`timescale 1ns / 1ps
`default_nettype none

module aes_mem (
  // default inputs
  input wire clk_in,
  input wire rst_in,

  // aes memory addr to access/write to
  // input wire [9:0] aes_mem_rd_addr_in,
  // input wire [9:0] aes_mem_wr_addr_in,

  // write enable flag
  // input wire [3:0] aes_mem_we_in,

  input wire [9:0] cpu_addr_in,
  input wire [9:0] aes_addr_in,

  input wire [3:0] aes_we_in,
  input wire [3:0] cpu_we_in,

  input wire [31:0] cpu_data_in,
  input wire [31:0] aes_data_in,

  output wire [31:0] cpu_data_out,
  output wire [31:0] aes_data_out

  // data in to write to mem
  // input wire [31:0] data_in,

  // data out from aes
  // output wire [31:0] data_out
);

  // Each entry is 4 * 8 bits/1 byte
  // 256 entries for aes input ==> each char is 1 byte total of 1024 chars possible
  // 256 entries for aes ouput
  // first 256 entries for aes input
  // latter 256 entries for aes output
  // ending each with a null character #DEADBEEF
  xilinx_true_dual_port_read_first_byte_write_2_clock_ram #(
    .NB_COL(4),
    .COL_WIDTH(8),
    .RAM_DEPTH(256 + 1 + 256 + 1),
    .RAM_PERFORMANCE("HIGH_PERFORMANCE")
  ) aes_mem (
    .clka(clk_in),
    .rsta(rst_in),
    .addra(cpu_addr_in),
    .dina(cpu_data_in),
    .wea(cpu_we_in),
    .ena(1'b1),
    .regcea(1'b1),
    .douta(cpu_data_out),

    .clkb(clk_in),
    .rstb(rst_in),
    .addrb(aes_addr_in),
    .dinb(aes_data_in),
    .web(aes_we_in),
    .enb(1'b1),
    .regceb(1'b1),
    .doutb(aes_data_out)
  );

endmodule