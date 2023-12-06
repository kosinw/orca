`default_nettype none

module aes_key_schedule (
    input  wire  [  3:0] round_in,
    input  wire  [127:0] key_in,
    output logic [127:0] key_out
);

  logic [7:0] k0, k1, k2, k3, k4, k5, k6, k7, k8, k9, k10, k11, k12, k13, k14, k15;
  logic [7:0] r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15;
  logic [7:0] sa, sb, sc, sd;
  logic [7:0] rcon;
  logic [127:0] temp_rot_word, temp_subbytes_result;

  // get the individual key cells
  assign k0 = key_in[127:120];
  assign k1 = key_in[119:112];
  assign k2 = key_in[111:104];
  assign k3 = key_in[103:096];

  assign k4 = key_in[095:088];
  assign k5 = key_in[087:080];
  assign k6 = key_in[079:072];
  assign k7 = key_in[071:064];

  assign k8 = key_in[063:056];
  assign k9 = key_in[055:048];
  assign k10 = key_in[047:040];
  assign k11 = key_in[039:032];

  assign k12 = key_in[031:024];
  assign k13 = key_in[023:016];
  assign k14 = key_in[015:008];
  assign k15 = key_in[007:000];

  assign temp_rot_word = {k7, k11, k15, k3, 96'h0};

  assign sa = temp_subbytes_result[127:120];
  assign sb = temp_subbytes_result[119:112];
  assign sc = temp_subbytes_result[111:104];
  assign sd = temp_subbytes_result[103:096];

  always_comb begin
    case (round_in)
      4'd1: rcon = 8'h01;
      4'd2: rcon = 8'h02;
      4'd3: rcon = 8'h04;
      4'd4: rcon = 8'h08;
      4'd5: rcon = 8'h10;
      4'd6: rcon = 8'h20;
      4'd7: rcon = 8'h40;
      4'd8: rcon = 8'h80;
      4'd9: rcon = 8'h1b;
      4'd10: rcon = 8'h36;
      default: rcon = 8'h00;
    endcase
  end

  always_comb begin
    r0  = k0 ^ sa ^ rcon;
    r4  = k4 ^ sb ^ 8'h00;
    r8  = k8 ^ sc ^ 8'h00;
    r12 = k12 ^ sd ^ 8'h00;

    r1  = k1 ^ r0;
    r5  = k5 ^ r4;
    r9  = k9 ^ r8;
    r13 = k13 ^ r12;

    r2  = k2 ^ r1;
    r6  = k6 ^ r5;
    r10 = k10 ^ r9;
    r14 = k14 ^ r13;

    r3  = k3 ^ r2;
    r7  = k7 ^ r6;
    r11 = k11 ^ r10;
    r15 = k15 ^ r14;
  end

  assign key_out = {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15};

  aes_sbox aes_sbox (
      .data_in (temp_rot_word),
      .data_out(temp_subbytes_result)
  );

endmodule
