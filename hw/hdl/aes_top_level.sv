`timescale 1ns / 1ps
`default_nettype none

module aes_top_level(
  input wire clk_in,
  input wire rst_in,

  input wire [2:0] aes_ctrl_in,

  input wire [31:0] aes_data_in,
  input wire [3:0] aes_mem_we_in,
  
  input wire [9:0] aes_mem_rd_addr_in,
  input wire [9:0] aes_mem_wr_addr_in,

  output wire [31:0] aes_data_out,
  output wire aes_complete_out
);

  logic mode_decrypt, mode_encrypt;

  logic [31:0] temp_aes_data_in, aes_mem_data_in;
  logic [9:0] temp_aes_mem_rd_addr, aes_mem_rd_addr;
  logic [9:0] temp_aes_mem_wr_addr, aes_mem_wr_addr;
  logic [31:0] aes_mem_data_out;
  logic [3:0] temp_aes_mem_we, aes_mem_we;

  assign mode_decrypt = aes_ctrl_in[1];
  assign mode_encrypt = aes_ctrl_in[0];

  always_comb begin
    case ({mode_decrypt, mode_encrypt})
      2'b01, 2'b10: begin
        aes_mem_data_in = temp_aes_data_in;
        aes_mem_rd_addr = temp_aes_mem_rd_addr;
        aes_mem_wr_addr = temp_aes_mem_wr_addr;
        aes_mem_we = temp_aes_mem_we;
      end 
      default: begin
        aes_mem_data_in = aes_data_in;
        aes_mem_rd_addr = aes_mem_rd_addr;
        aes_mem_wr_addr = aes_mem_wr_addr;
        aes_mem_we = aes_mem_we_in;
      end
    endcase
  end

  assign aes_data_out = aes_mem_data_out;

  aes aes(
    .clk_in(clk_in),
    .rst_in(rst_in),

    .aes_ctrl_in(aes_ctrl_in),

    .data_in(aes_mem_data_out),
    .data_out(temp_aes_data_in),

    .aes_mem_we_out(temp_aes_mem_we),
    .aes_mem_rd_addr_out(temp_aes_mem_rd_addr),
    .aes_mem_wr_addr_out(temp_aes_mem_wr_addr),
    .aes_complete_out(aes_complete_out)
  );
  
  aes_mem aes_mem(
    .clk_in(clk_in),
    .rst_in(rst_in),
    
    .aes_mem_rd_addr_in(aes_mem_rd_addr),
    .aes_mem_wr_addr_in(aes_mem_wr_addr),

    .data_in(aes_mem_data_in),
    .aes_mem_we_in(aes_mem_we),
    .data_out(aes_mem_data_out)
  );

endmodule