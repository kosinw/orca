`timescale 1ns / 1ps
`default_nettype none
`include "riscv_defs.sv"

module riscv_decode (
  input wire [31:0] inst_in,
  output logic [4:0] rd_out,
  output logic [4:0] rs1_out,
  output logic [4:0] rs2_out,
  output logic [31:0] imm_out,
  output logic [6:0] op_out,
);

  logic [6:0] opcode;
  logic [4:0] rd, rs1, rs2;
  logic [2:0] funct3;
  logic [6:0] funct7;
  logic [31:0] immD, immI, immS, immB, immU, immJ;

  always_comb begin : DecodeBlock
    opcode = inst_in[6:0];
    funct3 = inst_in[14:12];
    funct7 = inst_in[31:25];
    rd = inst_in[11:7];
    rs1 = inst_in[19:15];
    rs2 = inst_in[24:20];

    immD = 0;
    immB = { { 20{inst_in[31]} }, { inst_in[31], inst_in[7], inst_in[30:25], inst_in[11:8] }};
    immU = { { 12{inst_in[31]} }, inst_in[31:12] };
    immI = { { 20{inst_in[31]} }, inst_in[31:20] };
    immJ = { { 12{inst_in[31]} }, { inst_in[31], inst_in[19:12], inst_in[20], inst_in[31:21] } };  
    immS = { { 20{inst_in[31]} }, { inst_in[31:25], inst_in[11:7] } };

    case (opcode)
      7'b011_0011: begin 
        rd_out = rd;
        rs1_out = rs1;
        rs2_out = rs2;
        if (funct3 == 3'h0 && funct7 == 7'h00) begin
          op_out = `ADD;
        end else if (funct3 == 3'h0 && funct7 == 7'h20) begin
          op_out = `SUB;
        end else if (funct3 == 3'h4 && funct7 == 7'h00) begin
          op_out = `XOR;
        end else if (funct3 == 3'h6 && funct7 == 7'h00) begin
          op_out = `OR;
        end else if (funct3 == 3'h7 && funct7 == 7'h00) begin
          op_out = `AND;
        end else if (funct3 == 3'h1 && funct7 == 7'h00) begin
          op_out = `SLL;
        end else if (funct3 == 3'h5 && funct7 == 7'h00) begin
          op_out = `SRL;
        end else if (funct3 == 3'h5 && funct7 == 7'h20) begin
          op_out = `SRA;
        end else if (funct3 == 3'h2 && funct7 == 7'h00) begin
          op_out = `SLT;
        end else if (funct3 == 3'h3 && funct7 == 7'h00) begin
          op_out = `SLTU;
        end else if (funct3 == 3'h0 && funct7 == 7'h01) begin
          op_out = `MUL;
        end else if (funct3 == 3'h1 && funct7 == 7'h01) begin
          op_out = `MULH;
        end else if (funct3 == 3'h2 && funct7 == 7'h01) begin
          op_out = `MULSU;
        end else if (funct3 == 3'h3 && funct7 == 7'h01) begin
          op_out = `MULU;
        end else if (funct3 == 3'h4 && funct7 == 7'h01) begin
          op_out = `DIV;
        end else if (funct3 == 3'h5 && funct7 == 7'h01) begin
          op_out = `DIVU;
        end else if (funct3 == 3'h6 && funct7 == 7'h01) begin
          op_out = `REM;
        end else if (funct3 == 3'h7 && funct7 == 7'h01) begin
          op_out = `REMU;
        end 
      end 
      7'b001_0011: begin
        rd_out = rd;
        rs1_out = rs1;
        imm_out = immI;
        if (funct3 == 3'h0) begin
          op_out = `ADDI;
        end else if (funct3 == 3'h4) begin
          op_out = `XORI;
        end else if (funct3 == 3'h6) begin
          op_out = `ORI;
        end else if (funct3 == 3'h7) begin
          op_out = `ANDI;
        end else if (funct3 == 3'h1 && funct7 == 7'h00) begin
          op_out = `SLLI;
        end else if (funct3 == 3'h5 && funct7 == 7'h00) begin
          op_out = `SRLI;
        end else if (funct3 == 3'h5 && funct7 == 7'h20) begin
          op_out = `SRAI;
        end else if (funct3 == 3'h2) begin
          op_out = `SLTI;
        end else if (funct3 == 3'h3) begin
          op_out = `SLTIU;
        end
      end
      7'b000_0011: begin
        rd_out = rd;
        rs1_out = rs1;
        imm_out = immI;
        if (funct3 == 3'h0) begin
          op_out = `LB;
        end else if (funct3 == 3'h1) begin
          op_out = `LH;
        end else if (funct3 == 3'h2) begin
          op_out = `LW;
        end else if (funct3 == 3'h4) begin
          op_out = `LBU;
        end else if (funct3 == 3'h5) begin
          op_out = `LHU;
        end
      end
      7'b010_0011: begin
        rs1_out = rs1;
        rs2_out = rs2;
        imm_out = immS;
        if (funct3 == 3'h0) begin
          op_out = `SB;
        end else if (funct3 == 3'h1) begin
          op_out = `SH;
        end else if (funct3 == 3'h2) begin
          op_out = `SW;
        end
      end
      7'b110_0011: begin
        rs1_out = rs1;
        rs2_out = rs2;
        imm_out = immB;
        if (funct3 == 3'h0) begin
          op_out = `BEQ;
        end else if (funct3 == 3'h1) begin
          op_out = `BNE;
        end else if (funct3 == 3'h4) begin
          op_out = `BLT;
        end else if (funct3 == 3'h5) begin
          op_out = `BGE;
        end else if (funct3 == 3'h6) begin
          op_out = `BLTU;
        end else if (funct3 == 3'h7) begin
          op_out = `BGEU;
        end
      end
      7'b110_1111: begin
        rd_out = rd;
        imm_out = immJ;
        if (funct3 == 3'h0) begin
          op_out = `JAL;
        end
      end
      7'b110_0111: begin
        rd_out = rd;
        rs1_out = rs1;
        imm_out = immI;
        if (funct3 == 3'h0) begin
          op_out = `JALR;
        end
      end
      7'b011_0111: begin
        rd_out = rd;
        imm_out = immU;
        op_out = `LUI;
      end
      7'b001_0111: begin
        rd_out = rd;
        imm_out = immU;
        op_out = `AUIPC;
      end
      // ECALL and EBREAK
      // 7'b111_0011: begin
        // pass
      // end
    endcase

  end

endmodule