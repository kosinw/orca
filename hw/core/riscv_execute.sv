`timescale 1ns / 1ps
`default_nettype none
`include "riscv_defs.sv"

module riscv_execute (
  input wire [31:0] rs1_val_in,
  input wire [31:0] rs2_val_in,
  input wire [31:0] pc_in,
  input wire [6:0] op_in,
  input wire [31:0] imm_in,
  // output logic [31:0] addr_out,
  output logic [31:0] next_pc_out,
  output logic [31:0] data_out,
);
  
  always_comb begin : executeBlock
    case (op_in)
      `ADD: begin
        data_out = rs1_val_in + rs2_val_in;
      end 
      `SUB: begin
        data_out = rs1_val_in - rs2_val_in;
      end
      `XOR: begin
        data_out = rs1_val_in ^ rs2_val_in;
      end
      `OR: begin
        data_out = rs1_val_in | rs2_val_in;
      end
      `AND: begin
        data_out = rs1_val_in & rs2_val_in;
      end
      `SLL: begin
        data_out = rs1_val_in << rs2_val_in;
      end
      `SRL: begin
        data_out = rs1_val_in >> rs2_val_in;
      end
      `SRA: begin
        data_out = rs1_val_in >>> rs2_val_in;
      end
      // Unsure about handling SLT vs SLTU
      `SLT: begin
        data_out = (rs1_val_in < rs2_val_in) ? 1 : 0;
      end
      `SLTU: begin
        data_out = (rs1_val_in < rs2_val_in) ? 1 : 0;
      end

      `ADDI: begin
        data_out = rs1_val_in + imm;
      end
      `XORI: begin
        data_out = rs1_val_in ^ imm;
      end
      `ORI: begin
        data_out = rs1_val_in | imm;
      end
      `ANDI: begin
        data_out = rs1_val_in & imm;
      end
      `SLLI: begin
        data_out = rs1_val_in << imm[4:0];
      end
      `SRLI: begin
        data_out = rs1_val_in >> imm[4:0];
      end
      `SRAI: begin
        data_out = rs1_val_in >>> imm[4:0];
      end
      // Unsure about handling SLTI vs SLTIU
      `SLTI: begin
        data_out = (rs1_val_in < imm[4:0]) ? 1 : 0;
      end
      `SLTIU: begin
        data_out = (rs1_val_in < imm[4:0]) ? 1 : 0;
      end

      `LB, `LH, `LW, `LBU, `LHU, `SB, `SH, `SW: begin
        data_out = rs1_val_in + imm;
      end

      `JAL: begin
        data_out = pc_in + 1;
      end
      `JALR: begin
        data_out = pc_in + 1;
      end

      `LUI: begin
        data_out = imm << 12;
      end
      `AUIPC: begin
        data_out = pc_in + (imm << 12);
      end

      // Missing other Multiply Extensions for now
      `MUL: begin
        data_out = (rs1_val_in * rs2_val_in);
      end
      `DIV: begin
        data_out = (rs1_val_in / rs2_val_in);
      end
    endcase

    case (op_in)
      `ADD, `SUB, `XOR, `OR, `AND, `SLL, `SRL, `SRA, `SLT, `SLTU, `ADDI, `XORI, `ORI, `ANDI, `SLLI, `SRLI, `SRAI, `SLTI, `SLTIU, `LB, `LH, `LW, `LBU, `LHU, `SB, `SH, `SW, `LUI, `AUIPC, `MUL, `MULH, `MULSU, `MULU, `DIV, `DIVU, `REM, `REMU: begin
        next_pc_out = pc_in + 1;
      end

      `BEQ: begin
        if (rs1_val_in == rs2_val_in) begin
          next_pc_out = pc_in + imm;
        end
      end
      `BNE: begin
        if (rs1_val_in != rs2_val_in) begin
          next_pc_out = pc_in + imm;
        end
      end
      `BLT: begin
        if (rs1_val_in < rs2_val_in) begin
          next_pc_out = pc_in + imm;
        end
      end
      `BGE: begin
        if (rs1_val_in >= rs2_val_in) begin
          next_pc_out = pc_in + imm;
        end
      end
      // Unsure about handling BLTU vs BGEU
      `BLTU: begin
        if (rs1_val_in < rs2_val_in) begin
          next_pc_out = pc_in + imm;
        end
      end
      `BGEU: begin
        if (rs1_val_in >= rs2_val_in) begin
          next_pc_out = pc_in + imm;
        end
      end

      `JAL: begin
        next_pc_out = pc_in + imm;
      end
      `JALR: begin
        next_pc_out = rs1_val_in + imm;
      end      

      default: 
    endcase
  end

endmodule