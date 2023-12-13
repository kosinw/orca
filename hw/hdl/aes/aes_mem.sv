`timescale 1ns / 1ps
`default_nettype none

module aes_mem (
  // default inputs
  input wire clk_in,
  input wire rst_in,
  
  // aes memory addr to access/write to
  input wire [9:0] aes_mem_rd_addr_in,
  input wire [9:0] aes_mem_wr_addr_in,

  // data in to write to mem
  input wire [31:0] data_in,
  // write enable flag
  input wire [3:0] aes_mem_we_in,

  // data out from aes
  output wire [31:0] data_out
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
    .addra(aes_mem_rd_addr_in),
    .dina(),
    .clka(clk_in),
    .wea(4'h0),
    .ena(1'b1),
    .rsta(rst_in),
    .regcea(1'b1),
    .douta(data_out),

    .addrb(aes_mem_wr_addr_in),
    .dinb(data_in),
    .clkb(clk_in),
    .web(aes_mem_we_in),
    .enb(1'b1),
    .rstb(rst_in),
    .regceb(1'b1),
    .doutb()
  );

endmodule