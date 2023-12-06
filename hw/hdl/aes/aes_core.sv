`timescale 1ns / 1ps 
`default_nettype none
`include "hdl/aes/aes_defs.sv"

module aes_core (
    // Default inputs
    input wire clk_in,
    input wire rst_in,

    // Encryption decryption flag
    input wire mode_in,

    // Initialize encryption or decryption
    input wire init_in,

    // Key input and data input
    input wire [127:0] data_in,
    input wire [127:0] key_in,

    // Result and valid flag
    output logic [127:0] data_out,
    output logic valid_out
);
  logic [127:0] round_key;

  // Initialiez round for what round of the encryption it is currently in
  logic [3:0] round, key_round;
  logic next_round;

  logic key_expanded;
  logic start_aes;
  logic encrypt_init, decrypt_init;
  logic valid;

  assign encrypt_init = ((mode_in) && start_aes) ? 1'b1 : 1'b0;
  assign decrypt_init = ((!mode_in) && start_aes) ? 1'b1 : 1'b0;

  assign valid_out = valid;

  aes_key_memory aes_key_memory(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .init_in(init_in),
    .round_rd_in(round),
    .key_in(key_in),
    .key_out(round_key),
    .key_expanded_out(key_expanded)
  );

  aes_encryption aes_encryption(
      .clk_in(clk_in),
      .rst_in(rst_in),
      .init_in(encrypt_init),
      .data_in(data_in),
      .key_in(round_key),
      .round_in(round),
      .next_round_out(next_round),
      .data_out(data_out),
      .valid_out(valid)
  );

  always_comb begin
    if (next_round) begin
      round = round + 1;
    end
    if (valid) begin
      round = `ROUND_INIT;
    end 
  end

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      round <= `ROUND_INIT;
      start_aes <= 1'b0;
    end else begin
      if (key_expanded) begin
        start_aes <= 1'b1;
      end else begin
        start_aes <= 1'b0;
      end
    end
  end
endmodule
