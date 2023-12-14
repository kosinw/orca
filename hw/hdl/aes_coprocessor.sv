`timescale 1ns / 1ps
`default_nettype none

module aes_coprocessor (
  input wire clk_in,
  input wire rst_in,
  
  input wire [31:0] cpu_addr_in,
  input wire [31:0] cpu_data_in,
  input wire [3:0] cpu_write_enable_in,

  output logic [31:0] cpu_data_out
);

  // HIGH is aes is done encrypting/decrypting the aes input buffer data, LOW else
  logic aes_complete_out;

  // aes module inputs and outputs, and aes_mem inputs
  logic [31:0] aes_data_in, aes_data_out, temp_cpu_data_out;
  logic [9:0] aes_addr_out;
  logic [3:0] aes_write_enable;
  logic [31:0] aes_mem_data_out;

  // registers to make up MMIO_AES register
  logic aes_valid_result, aes_decrypt, aes_encrypt;

  // register to check whether cpu_addr_in is in range
  logic cpu_addr_in_range, cpu_addr_is_aes_ctrl_reg;
  logic [3:0] cpu_write_enable;

  // MMIO_AES control register
  logic [2:0] MMIO_AES;
  assign MMIO_AES = {aes_valid_result, aes_decrypt, aes_encrypt};

  assign cpu_addr_in_range = (cpu_addr_in[19:16] == 4'h4);
  assign cpu_addr_is_aes_ctrl_reg = (cpu_addr_in[19:0] == 20'h40300);
  assign cpu_write_enable = (cpu_addr_in_range) ? cpu_write_enable_in : 4'h0;

  always_comb begin
    if (cpu_addr_in_range) begin
      if (cpu_addr_is_aes_ctrl_reg) begin
        cpu_data_out = MMIO_AES;
      end else begin
        cpu_data_out = temp_cpu_data_out;
      end
    end
  end

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      aes_valid_result <= 0;
      aes_decrypt <= 0;
      aes_encrypt <= 0;
    end else begin
      if (cpu_addr_is_aes_ctrl_reg && cpu_write_enable[0]) begin
        aes_valid_result <= cpu_data_in[2];
        aes_decrypt <= cpu_data_in[1];
        aes_encrypt <= cpu_data_in[0];
      end

      if (aes_complete_out) begin
        aes_valid_result <= 1;
        aes_decrypt <= 0;
        aes_encrypt <= 0;
      end
    end
  end

  aes aes (
    .clk_in(clk_in),
    .rst_in(rst_in),
    
    .aes_ctrl_in(MMIO_AES),
    
    .data_in(aes_data_out),
    .data_out(aes_data_in),
    
    .aes_addr_out(aes_addr_out),

    .aes_mem_we_out(aes_write_enable),
    
    .aes_complete_out(aes_complete_out)
  );

  aes_mem aes_ram (
    .clk_in(clk_in),
    .rst_in(rst_in),

    .cpu_addr_in(cpu_addr_in[11:2]),
    .aes_addr_in(aes_addr_out),

    .cpu_we_in(cpu_write_enable),
    .aes_we_in(aes_write_enable),

    .cpu_data_in(cpu_data_in),
    .aes_data_in(aes_data_in),

    .cpu_data_out(temp_cpu_data_out),
    .aes_data_out(aes_data_out)
  );
endmodule