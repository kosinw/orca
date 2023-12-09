`timescale 1ns / 1ps
`default_nettype none

module lfsr_32 (
  input wire clk_in,
  input wire rst_in,
  output logic [31:0] lfsr_out
);
  // Define LFSR state register
  logic [31:0] lfsr_state;
  initial lfsr_state = 32'hDEADBEEF;

  // Using polynomial x^32 + x^4 + x^3 + x + 1
  // Taps at positions 31, 4, 3, 1, and 0
  always_ff @(posedge clk_in) begin
    if (rst_in)
      lfsr_state <= 64'hDEADBEEF; // Initialize LFSR with a non-zero seed
    else begin
      // LFSR feedback calculation
      lfsr_state <= {lfsr_state[30:0], lfsr_state[31] ^ lfsr_state[4] ^ lfsr_state[3] ^ lfsr_state[1] ^ lfsr_state[0]};
    end
  end

  // Output the current LFSR state
  assign lfsr_out = lfsr_state;
endmodule

`default_nettype wire
