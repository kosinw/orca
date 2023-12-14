module aes_integration_tb;
  logic clk, rst;
  logic [2:0] aes_ctrl;
  logic [31:0] aes_data_in;
  logic [3:0] aes_mem_we;
  logic [9:0] aes_mem_rd_addr;
  logic [9:0] aes_mem_wr_addr;

  logic [31:0] aes_data_out;
  logic aes_complete;

  aes_top_level aes_top_level(
    .clk_in(clk),
    .rst_in(rst),
    .aes_ctrl_in(aes_ctrl),
    .aes_data_in(aes_data_in),
    .aes_mem_we_in(aes_mem_we),
    .aes_mem_rd_addr_in(aes_mem_rd_addr),
    .aes_mem_wr_addr_in(aes_mem_wr_addr),
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
    aes_mem_wr_addr = mem_addr;
    aes_data_in = data;
    $display("Data Written: %0h", data);
    #10;
  endtask

  task read_from_aes_mem(input [9:0] mem_addr, input print);
    aes_mem_we = 4'h0;
    aes_mem_rd_addr = mem_addr;
    #20;
    if (print) begin
      $display("Data Read: %0h", aes_data_out);
    end
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
    write_to_aes_mem(4, 32'he296112a);
    write_to_aes_mem(5, 32'hdeadbeef);

    aes_mem_we = 4'h0;

    read_from_aes_mem(0, 1'b1);
    read_from_aes_mem(1, 1'b1);
    read_from_aes_mem(2, 1'b1);
    read_from_aes_mem(3, 1'b1);
    read_from_aes_mem(4, 1'b1);
    read_from_aes_mem(5, 1'b1);

    #100;

    aes_ctrl = 3'b001;

    wait_complete();

    $display("Break---");

    // #10000;
    read_from_aes_mem(0, 1'b1);
    read_from_aes_mem(1, 1'b1);
    read_from_aes_mem(2, 1'b1);
    read_from_aes_mem(3, 1'b1);
    read_from_aes_mem(4, 1'b1);
    read_from_aes_mem(5, 1'b1);

    $display("Break---");

    read_from_aes_mem(257, 1'b1);
    read_from_aes_mem(258, 1'b1);
    read_from_aes_mem(259, 1'b1);
    read_from_aes_mem(260, 1'b1);
    read_from_aes_mem(261, 1'b1);
    read_from_aes_mem(262, 1'b1);

    // $display("Memory written %0h", aes_data_out);

    $display("Finishing simulation...");
    $finish;
  end

endmodule