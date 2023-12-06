`timescale 1ns / 1ps
`default_nettype none

module aes_core (
  // Default inputs
  input wire clk_in,
  input wire rst_in,

  // Encryption decryption flag
  input wire mode_in,

  // Key input and data input
  input wire [127:0] key_in,
  input wire [127:0] data_in,

  // Initialize encryption or decryption
  input wire init_in,

  // Result and valid flag
  output logic [127:0] result_in,
  output logic valid_result_out,
);
  
  // Round counter, round key
  logic [3:0] round_ctr;
  logic [127:0] round_key;

  // Next flag
  logic next;



endmodule