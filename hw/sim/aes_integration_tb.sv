module aes_integration_tb;
  logic clk, rst;
  logic [2:0] aes_ctrl;
  logic [31:0] aes_data_in;
  logic [3:0] aes_mem_we;
  logic [9:0] aes_mem_addr;

  logic [31:0] aes_data_out;
  logic aes_complete;

  aes_top_level aes_top_level(
    .clk_in(clk),
    .rst_in(rst),
    .aes_ctrl_in(aes_ctrl),
    .aes_data_in(aes_data_in),
    .aes_mem_we_in(aes_mem_we),
    .aes_mem_addr_in(aes_mem_addr),
    .aes_data_out(aes_data_out),
    .aes_complete_out(aes_complete)
  );

  always begin
    #5;
    clk = !clk;
  end

  task wait_complete;
    begin
      while (!aes_complete) begin
        #10;
      end
      aes_ctrl = 3'b000;
    end
  endtask

  task write_to_aes_mem(input [9:0] mem_addr, input [31:0] data);
    aes_mem_we = 4'hf;
    aes_mem_addr = mem_addr;
    aes_data_in = data;
    $display("Data Written: %0h", data);
    #10;
  endtask

  task read_from_aes_mem(input [9:0] mem_addr);
    aes_mem_we = 4'h0;
    aes_mem_addr = mem_addr;
    #20;
    $display("Data Read: %0h", aes_data_out);
  endtask

  task start;
    clk = 1;
    #10;
    rst = 1;
    #10
    rst = 0;
  endtask

  initial begin
    $dumpfile("vcd/aes_integration.vcd");
    $dumpvars(0, aes_integration_tb);
    $display("Starting simulation...\n");

    aes_ctrl = 3'b000;

    start();
    
    write_to_aes_mem(0, 32'h6b2ee973);
    write_to_aes_mem(1, 32'hc1403d93);
    write_to_aes_mem(2, 32'hbe9f7e17);
    write_to_aes_mem(3, 32'he296112a);
    write_to_aes_mem(4, 32'hdeadbeef);

    // read_from_aes_mem(0);
    // read_from_aes_mem(1);
    // read_from_aes_mem(2);
    // read_from_aes_mem(3);
    // read_from_aes_mem(4);
    read_from_aes_mem(5);

    #100;

    aes_ctrl = 3'b101;

    wait_complete();

    // #1000;

    read_from_aes_mem(257);
    read_from_aes_mem(258);
    read_from_aes_mem(259);
    read_from_aes_mem(260);
    read_from_aes_mem(261);

    // $display("Memory written %0h", aes_data_out);

    $display("Finishing simulation...");
    $finish;
  end

endmodule