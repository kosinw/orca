`timescale 1ns / 1ps
`default_nettype none
`include "hdl/aes_defs.sv"

module aes_encryption (
    // Default inputs
    input wire clk_in,
    input wire rst_in,

    // Initialize encryption
    input wire init_in,

    // Data input
    input wire [127:0] data_in,

    // Key input
    input wire [127:0] key_in,

    input wire [3:0] round_in,

    // Data ouput
    output logic next_round_out,
    output logic [127:0] data_out,
    output logic valid_out
);
  // Initialiez round for what round of the encryption it is currently in
  logic [3:0] round;
  // Initialize stage for which stage within a round it is in
  logic [2:0] stage;

  // logic temp_next_out;

  // assign next_round_out = temp_next_out || (encrypting != `ROUND_INIT);
  // assign next_round_out = (round == `ROUND_INIT || (stage == `ADD_ROUND_KEY && round != `ROUND_10));
  assign next_round_out = ((encrypting && round == `ROUND_INIT) || (stage == `ADD_ROUND_KEY && round != `ROUND_10));

  assign round = round_in;

  // Initialize some temporary variables
  logic [127:0] temp_data, temp_subbytes_result;
  logic [31:0] temp_mc_result_0, temp_mc_result_1, temp_mc_result_2, temp_mc_result_3;
  // logic [127:0] round_key, temp_round_key;

  // Initialize cell values for data and mix columns matrix for processing
  logic [7:0] c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15;
  logic [7:0] m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15;

  // Encrypting flag - HIGH if encrypting, LOW if not
  logic encrypting;

  aes_sbox aes_sbox (
      .data_in (temp_data),
      .data_out(temp_subbytes_result)
  );

  // aes_key_schedule aes_key_schedule (
  //     .round_in(round),
  //     .key_in  (round_key),
  //     .key_out (temp_round_key)
  // );

  /********************************************
  * Functions to handle mix columns operation *
  ********************************************/

  function [7:0] gm2(input [7:0] val);
    begin
      gm2 = {val[6:0], 1'b0} ^ (8'h1b & (val[7] ? 8'hff : 8'h00));
    end
  endfunction

  function [7:0] gm3(input [7:0] val);
    begin
      gm3 = gm2(val) ^ val;
    end
  endfunction

  function [31:0] mix_columns(input [31:0] val);
    logic [7:0] v0, v1, v2, v3, r0, r1, r2, r3;
    begin
      v0          = val[31:24];
      v1          = val[23:16];
      v2          = val[15:08];
      v3          = val[07:00];

      r0          = gm2(v0) ^ gm3(v1) ^ v2 ^ v3;
      r1          = v0 ^ gm2(v1) ^ gm3(v2) ^ v3;
      r2          = v0 ^ v1 ^ gm2(v2) ^ gm3(v3);
      r3          = gm3(v0) ^ v1 ^ v2 ^ gm2(v3);

      mix_columns = {r0, r1, r2, r3};
    end
  endfunction

  /**************
  c0  c1  c2  c3
  c4  c5  c6  c7
  c8  c9  c10 c11
  c12 c13 c14 c15
  ***************/

  // get the individual cells
  assign c0 = temp_data[127:120];
  assign c1 = temp_data[119:112];
  assign c2 = temp_data[111:104];
  assign c3 = temp_data[103:096];

  assign c4 = temp_data[095:088];
  assign c5 = temp_data[087:080];
  assign c6 = temp_data[079:072];
  assign c7 = temp_data[071:064];

  assign c8 = temp_data[063:056];
  assign c9 = temp_data[055:048];
  assign c10 = temp_data[047:040];
  assign c11 = temp_data[039:032];

  assign c12 = temp_data[031:024];
  assign c13 = temp_data[023:016];
  assign c14 = temp_data[015:008];
  assign c15 = temp_data[007:000];

  // get the mixcolumns values
  assign temp_mc_result_0 = mix_columns({c0, c4, c8, c12});
  assign temp_mc_result_1 = mix_columns({c1, c5, c9, c13});
  assign temp_mc_result_2 = mix_columns({c2, c6, c10, c14});
  assign temp_mc_result_3 = mix_columns({c3, c7, c11, c15});

  assign m0 = temp_mc_result_0[31:24];
  assign m4 = temp_mc_result_0[23:16];
  assign m8 = temp_mc_result_0[15:08];
  assign m12 = temp_mc_result_0[07:00];

  assign m1 = temp_mc_result_1[31:24];
  assign m5 = temp_mc_result_1[23:16];
  assign m9 = temp_mc_result_1[15:08];
  assign m13 = temp_mc_result_1[07:00];

  assign m2 = temp_mc_result_2[31:24];
  assign m6 = temp_mc_result_2[23:16];
  assign m10 = temp_mc_result_2[15:08];
  assign m14 = temp_mc_result_2[07:00];

  assign m3 = temp_mc_result_3[31:24];
  assign m7 = temp_mc_result_3[23:16];
  assign m11 = temp_mc_result_3[15:08];
  assign m15 = temp_mc_result_3[07:00];

  assign data_out = temp_data;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      stage <= `IDLE;
      // round_key <= 128'h0;
      // next_round_out <= 1'b0;
    end else begin
      // Upon initializing encryption, set round stage to SubBytes
      if (init_in) begin
        stage <= `SUB_BYTES;
        encrypting <= 1'b1;
        temp_data <= data_in;
        // round_key <= key_in;
        valid_out <= 1'b0;
      end else begin
        if (encrypting) begin
          case (round)
            `ROUND_INIT: begin
              // original temp_data contains data_in
              // new temp_data contains data_in (XOR) round_key
              temp_data <= temp_data ^ key_in;
              // next_round_out <= 1'b1;
              // round <= `ROUND_1;
            end
            `ROUND_1, `ROUND_2, `ROUND_3, `ROUND_4, `ROUND_5, `ROUND_6, `ROUND_7, `ROUND_8, `ROUND_9, `ROUND_10: begin
              case (stage)
                `SUB_BYTES: begin
                  // temp_subbytes_result should contain the subbytes from sbox
                  // new temp_data contains the subbytes result
                  temp_data <= temp_subbytes_result;
                  stage <= `SHIFT_ROWS;
                  // next_round_out <= 1'b0;
                end
                `SHIFT_ROWS: begin
                  temp_data <= {
                    c0,  c1,  c2,  c3,
                    c5,  c6,  c7,  c4,
                    c10, c11, c8,  c9,
                    c15, c12, c13, c14
                  };
                  if (round == `ROUND_10) begin
                    stage <= `ADD_ROUND_KEY;
                  end else begin
                    stage <= `MIX_COLUMNS;
                  end
                end
                `MIX_COLUMNS: begin
                  temp_data <= {
                    m0,  m1,  m2,  m3,
                    m4,  m5,  m6,  m7,
                    m8,  m9,  m10, m11,
                    m12, m13, m14, m15
                  };
                  stage <= `ADD_ROUND_KEY;
                end
                `ADD_ROUND_KEY: begin
                  temp_data <= temp_data ^ key_in;
                  // round_key <= temp_round_key;
                  // If we are at last round, reset round, stage
                  // Set valid_out flag to HIGH, set encrypting to LOW
                  if (round == `ROUND_10) begin
                    // round <= `ROUND_INIT;
                    stage <= `IDLE;
                    valid_out <= 1'b1;
                    encrypting <= 1'b0;
                    // Otherwise, cycle again
                  end else begin
                    stage <= `SUB_BYTES;
                    // next_round_out <= 1'b1;
                    // round <= round + 1;
                  end
                end
              endcase
            end
          endcase
        end else begin
          valid_out <= 1'b0;
        end
      end
    end
  end
endmodule
