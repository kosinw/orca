`timescale 1ns / 1ps
`default_nettype none

module keyboard_ram (
  // default stuff
  input wire clk_in,
  input wire rst_in,
  
  // outputs from ps2_rx module
  input wire [7:0] kb_scancode_in,
  input wire kb_valid_in,

  // 
  input wire [31:0] cpu_addr_in,
  input wire [3:0] cpu_write_enable_in,

  // outputs the scancode stored in ram buffer
  output logic [31:0] cpu_data_out
);
  
  logic cpu_write_enable;
  logic cpu_addr_in_range;

  // cpu_addr_is_keyboard_ctrl_reg if cpu_addr_in == 32'30080h
  logic cpu_addr_is_keyboard_ctrl_reg;

  // HIGH if scancodes from keyboard in buffer, else 0
  logic keyboard_data_available;
  // counter of num of available scancodes from last polling
  logic [6:0] keyboard_ctr;

  // keyboard write enable in - wired to kb_valid_in
  logic kb_we_in;

  // data output from kb_ram
  logic [7:0] kb_mem_data_out;

  // keyboard control register
  // bits 7-1: keyboard_ctr
  // bit 0: keyboard data available flag
  logic [7:0] MMIO_KEYBOARD;

  assign kb_we_in = kb_valid_in;

  assign cpu_addr_in_range = (cpu_addr_in[19:16] == 4'h3);
  assign cpu_addr_is_keyboard_ctrl_reg = (cpu_addr_in[19:0] == 20'h30080);
  assign cpu_write_enable = (cpu_addr_in_range) ? cpu_write_enable_in[0] : 1'b0;

  assign MMIO_KEYBOARD = {keyboard_ctr, keyboard_data_available};

  always_comb begin
    cpu_data_out = 0;

    if (cpu_addr_in_range) begin
      if (cpu_addr_is_keyboard_ctrl_reg) begin
        cpu_data_out = MMIO_KEYBOARD;
      end else begin
        // assign cpu_data_out to be the output of kb_mem
        cpu_data_out = kb_mem_data_out;
      end
    end
  end

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      keyboard_ctr <= 0;
      keyboard_data_available <= 0;
    end else begin
      // if kb_valid_in, increment keyboard_ctr
      if (kb_valid_in) begin
        keyboard_ctr <= keyboard_ctr + 1;
        keyboard_data_available <= 1;
      end

      // if software enables write, clear MMIO_KEYBOARD register
      // software should enable write after getting all the scancodes
      if (cpu_addr_is_keyboard_ctrl_reg && cpu_write_enable) begin
        keyboard_ctr <= 0;
        keyboard_data_available <= 0;
      end
    end
  end


  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(8),
    .RAM_DEPTH(128),
    .RAM_PERFORMANCE("HIGH_PERFORMANCE")
  ) kb_ram (
    .clka(clk_in),
    .rsta(rst_in),
    .addra(keyboard_ctr),
    .dina(kb_scancode_in),
    .wea(kb_we_in),
    .ena(1'b1),
    .regcea(1'b1),
    .douta(),

    .clkb(clk_in),
    .rstb(rst_in),
    .addrb(cpu_addr_in[6:0]),
    .dinb(),
    .web(1'h0),
    .enb(1'b1),
    .regceb(1'b1),
    .doutb(kb_mem_data_out)
  );

endmodule