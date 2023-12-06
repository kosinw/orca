module aes_encryption_tb;

  logic clk_in;
  logic rst_in;
  logic init_in;
  logic [127:0] data_in;
  logic [127:0] key_in;
  logic [127:0] data_out;
  logic valid_out;
  logic [127:0] key;

  aes_encryption uut (
      .clk_in(clk_in),
      .rst_in(rst_in),
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

  task test(input [2:0] tc_number, input [127:0] aes_128_key, input [127:0] plaintext,
            input [127:0] expected);
    begin
      $display("*** TC %0d Started   ***", tc_number);

      data_in = plaintext;
      key_in  = aes_128_key;
      #10;
      init_in = 1;
      #10;
      init_in = 0;
      wait_valid();

      if (data_out == expected) begin
        $display("*** TC %0d Successful!", tc_number);
      end else begin
        $display("*** TC %0d NOT Successful :(", tc_number);
        $display("Expected: 0x%032x", expected);
        $display("Got:      0x%032x", data_out);
        $display("  \n");
      end
    end
  endtask

  initial begin
    logic [127:0] plaintext0, plaintext1, plaintext2, plaintext3, plaintext4;
    logic [127:0]
        plaintext0_enc_expected,
        plaintext1_enc_expected,
        plaintext2_enc_expected,
        plaintext3_enc_expected,
        plaintext4_enc_expected;
    logic [127:0] aes_128_key0, aes_128_key1;

    aes_128_key0 = 128'h2b28ab097eaef7cf15d2154f16a6883c;
    aes_128_key1 = 128'h0004080c0105090d02060a0e03070b0f;

    // plaintext tests for aes_128_key0
    plaintext0 = 128'h6b2ee973c1403d93be9f7e17e296112a;
    plaintext1 = 128'hae1e9e452d03b7af8aac6f8e579cac51;
    plaintext2 = 128'h30a3e51ac85cfb0a1ce4c152461119ef;
    plaintext3 = 128'hf6dfade69f4f2b6c249b413745177b10;

    // plaintext test for aes_128_key1
    plaintext4 = 128'h004488cc115599dd2266aaee3377bbff;

    // expected encryption results for aes_128_key0
    plaintext0_enc_expected = 128'h3a0da824d77a9e667b36caefb460f397;
    plaintext1_enc_expected = 128'hf503e796d3b985fdd56989ba859d5aaf;
    plaintext2_enc_expected = 128'h435988edb18e1b03cdce00067f23e388;
    plaintext3_enc_expected = 128'h7b2782040ce8237278ad205d5e3f71d4;

    // expected encryption result for aes_128_key1
    plaintext4_enc_expected = 128'h696ad870c47bcdb4e004b7c5d830805a;

    $dumpfile("vcd/aes_encryption.vcd");
    $dumpvars(0, aes_encryption_tb);
    $display("Starting simulation...\n");

    clk_in = 1;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;

    test(3'd0, aes_128_key0, plaintext0, plaintext0_enc_expected);
    test(3'd1, aes_128_key0, plaintext1, plaintext1_enc_expected);
    test(3'd2, aes_128_key0, plaintext2, plaintext2_enc_expected);
    test(3'd3, aes_128_key0, plaintext3, plaintext3_enc_expected);
    test(3'd4, aes_128_key1, plaintext4, plaintext4_enc_expected);

    $display("Finishing simulation...");
    $finish;
  end

endmodule
