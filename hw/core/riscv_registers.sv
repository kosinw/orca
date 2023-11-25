`timescale 1ns / 1ps
`default_nettype none

module riscv_registers (
  input wire clk_in,
  input wire rst_in,
  input wire [4:0] rd_in,
  input wire [31:0] rd_val_in,
  input wire [4:0] ra_in,
  input wire [4:0] rb_in,
  input wire we_in,
  output logic [31:0] ra_val_out,
  output logic [31:0] rb_val_out
);
  
  logic [31:0] x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16, x17, x18, x19, x20, x21, x22, x23, x24, x25, x26, x27, x28, x29, x30, x31;
  logic [31:0] temp_ra_val, temp_rb_val;

  always_ff @(posedge clk_in) begin : registerBlock
    if (rst_in) begin
      x0 <= 0;
      x1 <= 0;
      x2 <= 0;
      x3 <= 0;
      x4 <= 0;
      x5 <= 0;
      x6 <= 0;
      x7 <= 0;
      x8 <= 0;
      x9 <= 0;
      x10 <= 0;
      x11 <= 0;
      x12 <= 0;
      x13 <= 0;
      x14 <= 0;
      x15 <= 0;
      x16 <= 0;
      x17 <= 0;
      x18 <= 0;
      x19 <= 0;
      x20 <= 0;
      x21 <= 0;
      x22 <= 0;
      x23 <= 0;
      x24 <= 0;
      x25 <= 0;
      x26 <= 0;
      x27 <= 0;
      x28 <= 0;
      x29 <= 0;
      x30 <= 0;
      x31 <= 0;
    end else begin
      if (we_in) begin
        case (rd_in)
          5'd1: x1 <= rd_val_in;
          5'd2: x2 <= rd_val_in;
          5'd3: x3 <= rd_val_in;
          5'd4: x4 <= rd_val_in;
          5'd5: x5 <= rd_val_in;
          5'd6: x6 <= rd_val_in;
          5'd7: x7 <= rd_val_in;
          5'd8: x8 <= rd_val_in;
          5'd9: x9 <= rd_val_in;
          5'd10: x10 <= rd_val_in;
          5'd11: x11 <= rd_val_in;
          5'd12: x12 <= rd_val_in;
          5'd13: x13 <= rd_val_in;
          5'd14: x14 <= rd_val_in;
          5'd15: x15 <= rd_val_in;
          5'd16: x16 <= rd_val_in;
          5'd17: x17 <= rd_val_in;
          5'd18: x18 <= rd_val_in;
          5'd19: x19 <= rd_val_in;
          5'd20: x20 <= rd_val_in;
          5'd21: x21 <= rd_val_in;
          5'd22: x22 <= rd_val_in;
          5'd23: x23 <= rd_val_in;
          5'd24: x24 <= rd_val_in;
          5'd25: x25 <= rd_val_in;
          5'd26: x26 <= rd_val_in;
          5'd27: x27 <= rd_val_in;
          5'd28: x28 <= rd_val_in;
          5'd29: x29 <= rd_val_in;
          5'd30: x30 <= rd_val_in;
          5'd31: x31 <= rd_val_in;
          default: x0 <= 0;
        endcase
      end
    end
  end

  always_comb begin : AsyncRegReadBlock
    case (ra_in)
        5'd1: temp_ra_val = x1;
        5'd2: temp_ra_val = x2;
        5'd3: temp_ra_val = x3;
        5'd4: temp_ra_val = x4;
        5'd5: temp_ra_val = x5;
        5'd6: temp_ra_val = x6;
        5'd7: temp_ra_val = x7;
        5'd8: temp_ra_val = x8;
        5'd9: temp_ra_val = x9;
        5'd10: temp_ra_val = x10;
        5'd11: temp_ra_val = x11;
        5'd12: temp_ra_val = x12;
        5'd13: temp_ra_val = x13;
        5'd14: temp_ra_val = x14;
        5'd15: temp_ra_val = x15;
        5'd16: temp_ra_val = x16;
        5'd17: temp_ra_val = x17;
        5'd18: temp_ra_val = x18;
        5'd19: temp_ra_val = x19;
        5'd20: temp_ra_val = x20;
        5'd21: temp_ra_val = x21;
        5'd22: temp_ra_val = x22;
        5'd23: temp_ra_val = x23;
        5'd24: temp_ra_val = x24;
        5'd25: temp_ra_val = x25;
        5'd26: temp_ra_val = x26;
        5'd27: temp_ra_val = x27;
        5'd28: temp_ra_val = x28;
        5'd29: temp_ra_val = x29;
        5'd30: temp_ra_val = x30;
        5'd31: temp_ra_val = x31;
      default: temp_ra_val = 0;
    endcase

    case (rb_in)
        5'd1: temp_rb_val = x1;
        5'd2: temp_rb_val = x2;
        5'd3: temp_rb_val = x3;
        5'd4: temp_rb_val = x4;
        5'd5: temp_rb_val = x5;
        5'd6: temp_rb_val = x6;
        5'd7: temp_rb_val = x7;
        5'd8: temp_rb_val = x8;
        5'd9: temp_rb_val = x9;
        5'd10: temp_rb_val = x10;
        5'd11: temp_rb_val = x11;
        5'd12: temp_rb_val = x12;
        5'd13: temp_rb_val = x13;
        5'd14: temp_rb_val = x14;
        5'd15: temp_rb_val = x15;
        5'd16: temp_rb_val = x16;
        5'd17: temp_rb_val = x17;
        5'd18: temp_rb_val = x18;
        5'd19: temp_rb_val = x19;
        5'd20: temp_rb_val = x20;
        5'd21: temp_rb_val = x21;
        5'd22: temp_rb_val = x22;
        5'd23: temp_rb_val = x23;
        5'd24: temp_rb_val = x24;
        5'd25: temp_rb_val = x25;
        5'd26: temp_rb_val = x26;
        5'd27: temp_rb_val = x27;
        5'd28: temp_rb_val = x28;
        5'd29: temp_rb_val = x29;
        5'd30: temp_rb_val = x30;
        5'd31: temp_rb_val = x31;
      default: temp_rb_val = 0;
    endcase
  end

  assign ra_val_out = temp_ra_val;
  assign rb_val_out = temp_rb_val;
endmodule