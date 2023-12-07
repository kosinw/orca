module aes_key_memory_tb;
  logic clk;
  logic rst;
  logic init;
  logic key_expanding;
  logic key_expanded;
  logic [3:0] round_rd;
  logic [127:0] key_in, key_out;

  aes_key_memory uut(
    .clk_in(clk),
    .rst_in(rst),
    .init_in(init),
    .round_rd_in(round_rd),
    .key_in(key_in),
    .key_out(key_out),
    .key_expanded_out(key_expanded)
  );

  always begin
    #5;
    clk = !clk;
  end

  task wait_ready;
    begin
      while (!key_expanded) begin
        #10;
      end
    end
  endtask //automatic

  initial begin
    $dumpfile("vcd/aes_key_memory.vcd");
    $dumpvars(0, aes_key_memory_tb);
    $display("Starting simulation...\n");

    key_in = 128'h2b28ab097eaef7cf15d2154f16a6883c;
    round_rd = 0;

    // Start clk and initial rst
    clk = 1'b1;
    #10;
    rst = 1'b1;
    #10;
    rst = 1'b0;

    #10
    init = 1'b1;
    #10;
    init = 1'b0;
    #10

    wait_ready();

    for (integer i = 0; i < 16; i = i + 1) begin
      $display("*** Round %d Key ***", round_rd);
      display_data(key_out);
      round_rd = round_rd + 1;
      #10;
    end

    #100;

    $display("Finishing simulation...");
    $finish;
  end

  task display_data(input logic [127:0] data);
    begin
      $display("%h %h %h %h", data[127:120], data[119:112], data[111:104], data[103:096]);
      $display("%h %h %h %h", data[095:088], data[087:080], data[079:072], data[071:064]);
      $display("%h %h %h %h", data[063:056], data[055:048], data[047:040], data[039:032]);
      $display("%h %h %h %h", data[031:024], data[023:016], data[015:008], data[007:000]);
      $display("\n");
    end
  endtask

endmodule