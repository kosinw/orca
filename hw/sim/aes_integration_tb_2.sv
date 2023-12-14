module aes_integration_2_tb;
  logic clk;
  logic rst;

  logic [31:0] cpu_addr_in;
  logic [31:0] cpu_data_in;
  logic [3:0] cpu_write_enable_in;

  logic [31:0] cpu_data_out;

  logic do_while;

  aes_coprocessor aes_coprocessor(
    .clk_in(clk),
    .rst_in(rst),
    
    .cpu_addr_in(cpu_addr_in),
    .cpu_data_in(cpu_data_in),
    .cpu_write_enable_in(cpu_write_enable_in),

    .cpu_data_out(cpu_data_out)
  );

  always begin
    #10;
    clk = !clk;
  end

  task write_to_aes_mem(input [31:0] addr_in, input [31:0] data_in, input [3:0] we_in);
    cpu_write_enable_in = we_in;
    cpu_addr_in = addr_in;
    cpu_data_in = data_in;
    $display("Data Written: %h", data_in);
    #20;
  endtask

  task read_from_aes_mem(input [31:0] addr_in, input [3:0] we_in, input print);
    cpu_addr_in = addr_in;
    cpu_write_enable_in = we_in;
    #20;
    #20;
    if (print) begin
      $display("Data Read: %0h", cpu_data_out);
    end
  endtask

  task wait_complete;
    do_while = 1;
    while (do_while) begin
      read_from_aes_mem(32'h0004_1000, 4'h0, 1'b0);
      $display("AES Control Reg: %0b", cpu_data_out);
      if (cpu_data_out[2]) begin
        do_while = 0;
      end
    end
  endtask

  initial begin
    $dumpfile("vcd/aes_integration_2.vcd");
    $dumpvars(0, aes_integration_2_tb);
    $display("Starting simulation...\n");

    clk = 0;
    rst = 0;
    #20;
    rst = 1;
    #20;
    rst = 0;
    
    #200;

    $display("\n*** Writing to AES Input Buffer ***\n");

    write_to_aes_mem(32'h0004_0000, 32'h6b2ee973, 4'hf);
    write_to_aes_mem(32'h0004_0004, 32'hc1403d93, 4'hf);
    write_to_aes_mem(32'h0004_0008, 32'hbe9f7e17, 4'hf);
    write_to_aes_mem(32'h0004_000c, 32'he296112a, 4'hf);
    write_to_aes_mem(32'h0004_0010, 32'hae1e9e45, 4'hf);
    write_to_aes_mem(32'h0004_0014, 32'h2d03b7af, 4'hf);
    write_to_aes_mem(32'h0004_0018, 32'h8aac6f8e, 4'hf);
    write_to_aes_mem(32'h0004_001d, 32'h579cac51, 4'hf);
    write_to_aes_mem(32'h0004_0020, 32'hdeadbeef, 4'hf);

    #100;

    $display("\n*** Checking AES Input Buffer ***\n");

    read_from_aes_mem(32'h0004_0000, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_0004, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_0008, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_000c, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_0010, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_0014, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_0018, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_001d, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_0020, 4'h0, 1'b1);

    #100;

    $display("\n*** Writing to AES MMIO Control Register: Encryption ***\n");

    write_to_aes_mem(32'h0004_1000, 32'b001, 4'hf);
    
    #20;

    wait_complete();
    
    $display("\n*** AES Completed ***\n");

    $display("\n*** Reading AES Output Buffer After Encryption***\n");

    read_from_aes_mem(32'h0004_0404, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_0408, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_040c, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_0410, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_0414, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_0418, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_041c, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_0420, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_0424, 4'h0, 1'b1);

    #100;

    $display("\n*** Writing Ciphertext ***\n");

    write_to_aes_mem(32'h0004_0000, 32'h3a0da824, 4'hf);
    write_to_aes_mem(32'h0004_0004, 32'hd77a9e66, 4'hf);
    write_to_aes_mem(32'h0004_0008, 32'h7b36caef, 4'hf);
    write_to_aes_mem(32'h0004_000c, 32'hb460f397, 4'hf);
    write_to_aes_mem(32'h0004_0010, 32'hf503e796, 4'hf);
    write_to_aes_mem(32'h0004_0014, 32'hd3b985fd, 4'hf);
    write_to_aes_mem(32'h0004_0018, 32'hd56989ba, 4'hf);
    write_to_aes_mem(32'h0004_001d, 32'h859d5aaf, 4'hf);
    write_to_aes_mem(32'h0004_0020, 32'hdeadbeef, 4'hf);

    #100;

    $display("\n*** Checking AES Input Buffer ***\n");

    read_from_aes_mem(32'h0004_0000, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_0004, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_0008, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_000c, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_0010, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_0014, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_0018, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_001d, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_0020, 4'h0, 1'b1);

    #100;

    write_to_aes_mem(32'h0004_1000, 32'b010, 4'hf);

    #20;

    wait_complete();

    read_from_aes_mem(32'h0004_0404, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_0408, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_040c, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_0410, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_0414, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_0418, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_041c, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_0420, 4'h0, 1'b1);
    read_from_aes_mem(32'h0004_0424, 4'h0, 1'b1);

    $display("Finishing simulation");
    $finish;
  end
endmodule