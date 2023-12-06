module aes_key_schedule_tb;
  logic [3:0] round_in;
  logic [127:0] key_in;
  logic [127:0] key_out;
  logic clk;

  aes_key_schedule uut(
    .round_in(round_in),
    .key_in(key_in),
    .key_out(key_out)
  );

  always begin
    #10;
    clk = !clk;
  end

  initial begin
    $dumpfile("vcd/aes_key_schedule.vcd");
    $dumpvars(0, aes_key_schedule_tb);
    $display("starting simulation...\n");

    clk = 1;
    round_in = 1;
    key_in = 128'h2b28ab097eaef7cf15d2154f16a6883c;

    display_data(key_in);

    // for (integer i = 1; i < 11; i = i + 1) begin
    //   $display("*** Round %0d ***", round_in);
    //   display_data(key_in);
    //   display_data(key_out);
    //   round_in = round_in + 1;
    //   key_in = key_out;
    //   #10;
    // end

    #100;

    display_data(key_out);

    $display("Finishing simulation...");
    $finish;
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

endmodule