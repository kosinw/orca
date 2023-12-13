`timescale 1ns / 1ps
`default_nettype none

module ps2_top_level (
  input wire clk_in,
  input wire rst_in,
  
  // [7:1] character counter in mem, [0] data available flag
  input wire [7:0] ps2_ctrl_in,

  input wire [7:0] ps2_data_in,
  input wire ps2_mem_we_in,

  output wire [7:0] ps2_data_out,
);

  logic [6:0] ps2_mem_addr;
  logic ps2_data_available;

  assign ps2_mem_addr = ps2_ctrl_in[7:1];
  assign ps2_data_available = ps2_ctrl_in[0];

  ps2_rx ps2_rx(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .ps2_clk_in(),
    .ps2_data_in(),
    
    .valid_out(),
    .error_out(),
    .scancode_out()
  );

endmodule