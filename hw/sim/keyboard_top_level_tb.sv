module keyboard_top_level_tb;
  logic clk, rst;
  logic ps2_clk, ps2_data;
  logic kb_valid, error_out;
  logic [7:0] kb_scancode;

  logic [31:0] cpu_addr_in;
  logic [3:0] cpu_write_enable_in;
  logic [31:0] cpu_data_out;

  logic [6:0] buffer_ctr;

  localparam integer H_SCANCODE = 11'b11_00110011_0;
  localparam integer E_SCANCODE = 11'b11_00100100_0;
  localparam integer BAD_SCANCODE = 11'b11_00110100_0;

  always begin
    #5;
    clk = !clk;
  end

  ps2_rx kb (
    .clk_in(clk),
    .rst_in(rst),
    .ps2_clk_in(ps2_clk),
    .ps2_data_in(ps2_data),
    .valid_out(kb_valid),
    .error_out(error_out),
    .scancode_out(kb_scancode)
  );

  keyboard_ram kb_ram (
    .clk_in(clk),
    .rst_in(rst),
    
    .kb_scancode_in(kb_scancode),
    .kb_valid_in(kb_valid),
    
    .cpu_addr_in(cpu_addr_in),
    .cpu_write_enable_in(cpu_write_enable_in),
    .cpu_data_out(cpu_data_out)
  );

  task write_to_kb_mem(input [31:0] addr, input [3:0] we);
    cpu_addr_in = addr;
    cpu_write_enable_in = we;
    #10;
  endtask

  task read_from_kb_mem(input [31:0] addr);
    $display("Address: %0h", addr);
    cpu_addr_in = addr;
    #10;
    #10;
    $display("Data Read: %0b", cpu_data_out);
  endtask

  initial begin
    $dumpfile("vcd/keyboard_top_level.vcd");
    $dumpvars(0, keyboard_top_level_tb);
    $display("Starting simulation...");

    clk = 0;
    rst = 0;
    ps2_clk = 1;
    ps2_data = 1;
    #5;
    rst = 1;
    #20;
    rst = 0;

    read_from_kb_mem(32'h1_0000);

    #180_239;

    // send scancode for charater 'H'
    // send data at ~16khz clock rate
    for (integer i = 0; i < 11; i = i + 1) begin
      ps2_data = H_SCANCODE[i];
      #250;
      ps2_clk = 0;
      #31250;
      ps2_clk = 1;
      #31000;
    end

    ps2_data = 1'b1;

    #180_867;

    // send scancode for charater 'E'
    // send data at ~16khz clock rate
    for (integer i = 0; i < 11; i = i + 1) begin
      ps2_data = E_SCANCODE[i];
      #250;
      ps2_clk = 0;
      #31250;
      ps2_clk = 1;
      #31000;
    end

    // send scancode for some character with invalid parity
    // send data at ~16khz clock rate
    for (integer i = 0; i < 11; i = i + 1) begin
        ps2_data = BAD_SCANCODE[i];
        #250;
        ps2_clk = 0;
        #31250;
        ps2_clk = 1;
        #31000;
    end

    ps2_data = 1'b1;

    read_from_kb_mem(32'h3_0080);

    if (cpu_data_out[0]) begin
      buffer_ctr = cpu_data_out[7:1];
    end

    for (integer i = 0; i < buffer_ctr; i = i + 1) begin
      read_from_kb_mem(32'h3_0000 + i);
    end

    #100;

    write_to_kb_mem(32'h3_0080, 4'hf);  

    #100;

    read_from_kb_mem(32'h3_0080);

    #10000;

    $display("Finishing simulation...");
    $finish;
  end


endmodule