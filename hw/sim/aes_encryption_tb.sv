`include "hdl/aes_defs.sv"

module aes_core_tb;
  logic clk_in;
  logic rst_in;
  logic mode_in;
  logic init_in;
  logic [127:0] data_in;
  logic [127:0] key_in;
  logic [127:0] data_out;
  logic valid_out;

  aes_core uut (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .mode_in(mode_in),
    .init_in(init_in),
    .data_in(data_in),
    .key_in(key_in),
    .data_out(data_out),
    .valid_out(valid_out)
  );

  always begin
    #5;
    clk_in = !clk_in;
  end

  task display_data(input logic [127:0] data);
    begin
      $display("Data In");
      $display("%h %h %h %h", data[127:120], data[119:112], data[111:104], data[103:096]);
      $display("%h %h %h %h", data[095:088], data[087:080], data[079:072], data[071:064]);
      $display("%h %h %h %h", data[063:056], data[055:048], data[047:040], data[039:032]);
      $display("%h %h %h %h", data[031:024], data[023:016], data[015:008], data[007:000]);
      $display("\n");
    end
  endtask

  task wait_valid;
    begin
      while (!valid_out) begin
        #10;
      end
    end
  endtask

  task test(input [3:0] tc_number, input mode, input [127:0] aes_128_key, input [127:0] plaintext, input [127:0] expected);
    begin
      $display("*** TC %0d Started   ***", tc_number);
      mode_in = mode;
      data_in = plaintext;
      key_in  = aes_128_key;
      #10;
      init_in = 1;
      #10;
      init_in = 0;
      wait_valid();

      if (data_out == expected) begin
        if (mode) begin
          $display("*** TC %0d Encryption Successful!", tc_number);
        end else begin
          $display("*** TC %0d Decryption Successful!", tc_number);
        end
      end else begin
        if (mode) begin
          $display("*** TC %0d Encryption NOT Successful :(", tc_number);
          $display("Expected: 0x%032x", expected);
          $display("Got:      0x%032x", data_out);
          $display("  \n");
        end else begin
          $display("*** TC %0d Decryption NOT Successful :(", tc_number);
          $display("Expected: 0x%032x", expected);
          $display("Got:      0x%032x", data_out);
        end
      end
    end
  endtask

  initial begin
    logic [127:0] plaintext0, plaintext1, plaintext2, plaintext3, plaintext4, plaintext5;
    logic [127:0] plaintext0_enc_expected, plaintext1_enc_expected, plaintext2_enc_expected, plaintext3_enc_expected, plaintext4_enc_expected, plaintext5_enc_expected;
    logic [127:0] aes_128_key0, aes_128_key1;

    aes_128_key0 = 128'h2b28ab097eaef7cf15d2154f16a6883c;
    aes_128_key1 = 128'h0004080c0105090d02060a0e03070b0f;

    // plaintext tests for aes_128_key0
    plaintext0 = 128'h6b2ee973c1403d93be9f7e17e296112a;
    plaintext1 = 128'hae1e9e452d03b7af8aac6f8e579cac51;
    plaintext2 = 128'h30a3e51ac85cfb0a1ce4c152461119ef;
    plaintext3 = 128'hf6dfade69f4f2b6c249b413745177b10;
    plaintext5 = 128'h328831e0435a3137f6309807a88da234;

    // plaintext test for aes_128_key1
    plaintext4 = 128'h004488cc115599dd2266aaee3377bbff;

    // expected encryption results for aes_128_key0
    plaintext0_enc_expected = 128'h3a0da824d77a9e667b36caefb460f397;
    plaintext1_enc_expected = 128'hf503e796d3b985fdd56989ba859d5aaf;
    plaintext2_enc_expected = 128'h435988edb18e1b03cdce00067f23e388;
    plaintext3_enc_expected = 128'h7b2782040ce8237278ad205d5e3f71d4;
    plaintext5_enc_expected = 128'h3902dc1925dc116a8409850b1dfb9732;

    // expected encryption result for aes_128_key1
    plaintext4_enc_expected = 128'h696ad870c47bcdb4e004b7c5d830805a;

    $dumpfile("vcd/aes_encryption.vcd");
    $dumpvars(0, aes_core_tb);
    $display("Starting simulation...\n");

    clk_in = 1;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;

    // #10;
    // mode_in = 1'b0;
    // init_in = 1'b1;
    // key_in = aes_128_key0;
    // data_in = plaintext5_enc_expected;
    // #10;
    // init_in = 1'b0;
    
    // while (!valid_out) begin
    //   #10;
    // end

    // #1000;

    test(4'd0, 1'b1, aes_128_key0, plaintext0, plaintext0_enc_expected);
    test(4'd1, 1'b1, aes_128_key0, plaintext1, plaintext1_enc_expected);
    test(4'd2, 1'b1, aes_128_key0, plaintext2, plaintext2_enc_expected);
    test(4'd3, 1'b1, aes_128_key0, plaintext3, plaintext3_enc_expected);
    test(4'd4, 1'b1, aes_128_key1, plaintext4, plaintext4_enc_expected);
    test(4'd5, 1'b1, aes_128_key0, plaintext5, plaintext5_enc_expected);

    test(4'd6, 1'b0, aes_128_key0, plaintext0_enc_expected, plaintext0);
    test(4'd7, 1'b0, aes_128_key0, plaintext1_enc_expected, plaintext1);
    test(4'd8, 1'b0, aes_128_key0, plaintext2_enc_expected, plaintext2);
    test(4'd9, 1'b0, aes_128_key0, plaintext3_enc_expected, plaintext3);
    test(4'd10, 1'b0, aes_128_key1, plaintext4_enc_expected, plaintext4);
    test(4'd11, 1'b0, aes_128_key0, plaintext5_enc_expected, plaintext5);

    test(4'd0, 1'b1, aes_128_key0, 128'h0, plaintext0_enc_expected);

    // 128'h7d1a3eb9f7b8421b6b99f0540cb3476f

    #100;

    $display("Finishing simulation...");
    $finish;
  end

endmodule
