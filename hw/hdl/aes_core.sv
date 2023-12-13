// ======================================================================
//
// aes_core.sv
// --------------------
// The general AES core wrapper. Handles all round logics, from key
// expansion, to encryption and decryption.
//
// ======================================================================

`timescale 1ns / 1ps
`default_nettype none
`include "hdl/aes_defs.sv"

module aes_core (
  // Default system inputs
  input wire clk_in,
  input wire rst_in,

  // Encryption decryption flag: 1'b1 for ENCRYPT, 1'b0 for DECRYPT
  input wire mode_in,

  // Flag to indicate the start of AES encryption/decryption
  input wire init_in,

  // Data and key input
  input wire [127:0] data_in,
  input wire [127:0] key_in,

  // Result output and valid result output flag
  output logic [127:0] data_out,
  output logic valid_out
);

  localparam NUM_ROUND_KEYS = 10;

  // round_key variable that feeds into Decrypt and Encrypt of the right key at a given round
  logic [127:0] round_key;

  // encryption/decryption output
  logic [127:0] data_out_encrypt, data_out_decrypt;
  logic [127:0] temp_data_in;

  // round - what round of the encryption/decryption it is currently in
  // key_memory_round_rd_in - the round to read the key in aes_key_memory module
  logic [3:0] round, key_memory_round_rd_in;

  // next_round - general flag for when it is going to the next round
  // next_round_decrypt - next round flag for decryption
  // next_round_encrypt - next round flag for encryption
  logic next_round, next_round_decrypt, next_round_encrypt;

  // flag to indicate whether the key has been expanded for all 10 rounds
  logic key_expanded;
  // flag to indicate the start of encryption/decryption. raised for 1 cycle after key has expanded
  logic start_aes;
  // flags to indicate the start of encrypt and decrypt (raised for 1 cycle)
  logic encrypt_init, decrypt_init;
  // flags to indicate when there is a valid encrypt/decrypt (raised for 1 cycle)
  logic valid, valid_encrypt, valid_decrypt;

  // initialize the encrypt/decrypt init flag
  assign encrypt_init = (mode_in == `ENCRYPT && start_aes) ? 1'b1 : 1'b0;
  assign decrypt_init = (mode_in == `DECRYPT && start_aes) ? 1'b1 : 1'b0;

  // round to read the key from key_memory module. If decrypt, read from the back.
  assign key_memory_round_rd_in = mode_in == `ENCRYPT ? round : NUM_ROUND_KEYS - round;

  // assign the valid flag based on valid_encrypt or valid_decrypt
  assign valid = mode_in == `ENCRYPT ? valid_encrypt : valid_decrypt;
  assign valid_out = valid;

  // assign the next_round flag and data_out output
  assign next_round = mode_in == `ENCRYPT ? next_round_encrypt : next_round_decrypt;
  assign data_out = mode_in == `ENCRYPT ? data_out_encrypt : data_out_decrypt;

  // aes_key_memory module
  // contains all the keys necessary to computer each rounds
  aes_key_memory aes_key_memory (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .init_in(init_in),
    .round_rd_in(key_memory_round_rd_in),
    .key_in(key_in),
    .key_out(round_key),
    .key_expanded_out(key_expanded)
  );

  // aes_encryption module
  // converts plaintext input into ciphertext output
  aes_encryption aes_encryption (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .init_in(encrypt_init),
    .data_in(temp_data_in),
    .key_in(round_key),
    .round_in(round),
    .next_round_out(next_round_encrypt),
    .data_out(data_out_encrypt),
    .valid_out(valid_encrypt)
  );

  // aes_decryption module
  // converts ciphertext input into plaintext output
  aes_decryption aes_decryption (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .init_in(decrypt_init),
    .data_in(temp_data_in),
    .key_in(round_key),
    .round_in(round),
    .next_round_out(next_round_decrypt),
    .data_out(data_out_decrypt),
    .valid_out(valid_decrypt)
  );

  // combinational logic to handle the increment of rounds and resetting of rounds
  always_comb begin
    if (next_round) begin
      round = round + 1;
    end
    if (valid) begin
      round = `ROUND_INIT;
    end
  end

  // sequential logic to handle the when the aes should start
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      round <= `ROUND_INIT;
      start_aes <= 1'b0;
    end else begin
      if (init_in) begin
        temp_data_in <= data_in;
      end
      if (key_expanded) begin
        start_aes <= 1'b1;
      end else begin
        start_aes <= 1'b0;
      end
    end
  end
endmodule
