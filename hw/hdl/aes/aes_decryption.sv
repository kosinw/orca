`timescale 1ns / 1ps 
`default_nettype none
`include "hdl/aes/aes_defs.sv"

module aes_decryption (
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

  logic [3:0] round;
  logic [2:0] stage;

  assign round = round_in;

  // Initialize some temporary variables;
  logic [127:0] temp_data, temp_subbytes_result;
  logic [31:0] temp_mc_result_0, temp_mc_result_1, temp_mc_result_2, temp_mc_result_3;

  // Initialize cell values for data and mix columns matrix for processing
  logic [7:0] c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15;
  logic [7:0] m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15;

  logic decrypting;

  aes_inv_sbox aes_inv_sbox (
      .data_in (temp_data),
      .data_out(temp_subbytes_result)
  );

  /************************************************
  * Functions to handle inv mix columns operation * 
  ************************************************/

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

  function [7:0] gm4(input [7:0] val);
    begin
      gm4 = gm2(gm2(val));
    end
  endfunction

  function [7:0] gm8(input [7:0] val);
    begin
      gm8 = gm2(gm4(val));
    end
  endfunction

  function [7:0] gm09(input [7:0] val);
    begin
      gm09 = gm8(val) ^ val;
    end
  endfunction

  function [7:0] gm11(input [7:0] val);
    begin
      gm11 = gm8(val) ^ gm2(val) ^ val;
    end
  endfunction

  function [7:0] gm13(input [7:0] val);
    begin
      gm13 = gm8(val) ^ gm4(val) ^ val;
    end
  endfunction

  function [7:0] gm14(input [7:0] val);
    begin
      gm14 = gm8(val) ^ gm4(val) ^ gm2(val);
    end
  endfunction

  function [31:0] inv_mix_columns(input [31:0] val);
    logic [7:0] v0, v1, v2, v3, r0, r1, r2, r3;
    begin
      v0 = val[31:24];
      v1 = val[23:16];
      v2 = val[15:08];
      v3 = val[07:00];

      r0 = gm14(v0) ^ gm11(v1) ^ gm13(v2) ^ gm09(v3);
      r1 = gm09(v0) ^ gm14(v1) ^ gm11(v2) ^ gm13(v3);
      r2 = gm13(v0) ^ gm09(v1) ^ gm14(v2) ^ gm11(v3);
      r3 = gm11(v0) ^ gm13(v1) ^ gm09(v2) ^ gm14(v3);

      inv_mix_columns = {r0, r1, r2, r3};
    end
  endfunction

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

  // get the inv mix columns values
  assign temp_mc_result_0 = inv_mix_columns({c0, c4, c8, c12});
  assign temp_mc_result_1 = inv_mix_columns({c1, c5, c9, c13});
  assign temp_mc_result_2 = inv_mix_columns({c2, c6, c10, c14});
  assign temp_mc_result_3 = inv_mix_columns({c3, c7, c11, c15});

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
      next_round_out <= 1'b0;
    end else begin
      if (init_in) begin
        stage <= `ADD_ROUND_KEY;
        decrypting <= 1'b1;
        temp_data <= data_in;
        valid_out <= 1'b0;
      end else begin
        if (decrypting) begin
          case (round)
            `ROUND_INIT, `ROUND_1, `ROUND_2, `ROUND_3, `ROUND_4, `ROUND_5, `ROUND_6, `ROUND_7, `ROUND_8, `ROUND_9: begin
              case (stage)
                `ADD_ROUND_KEY: begin
                  temp_data <= temp_data ^ key_in;
                  next_round_out <= 1'b0;
                  if (round == `ROUND_INIT) begin
                    stage <= `INV_SHIFT_ROWS;
                  end else begin
                    stage <= `INV_MIX_COLUMNS;
                  end
                end
                `INV_MIX_COLUMNS: begin
                  temp_data <= {
                    m0,  m1,  m2,  m3, 
                    m4,  m5,  m6,  m7, 
                    m8,  m9,  m10, m11, 
                    m12, m13, m14, m15
                  };
                  stage <= `INV_SHIFT_ROWS;
                end
                `INV_SHIFT_ROWS: begin
                  temp_data <= {
                    c0,  c1,  c2,  c3, 
                    c7,  c4,  c5,  c6,
                    c10, c11, c8,  c9,
                    c13, c14, c15, c12
                  };
                  stage <= `INV_SUB_BYTES;
                end
                `INV_SUB_BYTES: begin
                  temp_data <= temp_subbytes_result;
                  next_round_out <= 1'b1;
                  stage <= `ADD_ROUND_KEY;
                end
              endcase
            end
            `ROUND_10: begin
              case (stage)
                `ADD_ROUND_KEY: begin
                  temp_data <= temp_data ^ key_in;
                  next_round_out <= 1'b0;
                  stage <= `IDLE;
                  valid_out <= 1'b1;
                  decrypting <= 1'b0;
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
