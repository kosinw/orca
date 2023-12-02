`include "hdl/riscv_constants.sv"

`timescale 1ns / 1ps
`default_nettype none

module riscv_decode(
    input  wire  [31:0] inst_in,
    output logic [4:0]  rs1_out,
    output logic [4:0]  rs2_out,
    output logic [4:0]  rd_out,
    output logic [31:0] imm_out,
    output logic [2:0]  br_func_out,
    output logic [1:0]  pc_sel_out,
    output logic        op1_sel_out,
    output logic        op2_sel_out,
    output logic [1:0]  writeback_sel_out,
    output logic [3:0]  alu_func_out,
    output logic        write_enable_rf_out,
    output logic [2:0]  dmem_size_out,
    output logic        dmem_read_enable_out,
    output logic        dmem_write_enable_out
);
    logic [6:0]  opcode;
    logic [2:0]  funct3;
    logic [6:0]  funct7;
    logic [31:0] immI, immS, immB, immU, immJ;

    assign opcode = inst_in[6:0];
    assign funct3 = inst_in[14:12];
    assign funct7 = inst_in[31:25];
    assign rs1_out = inst_in[19:15];
    assign rs2_out = inst_in[24:20];
    assign rd_out = inst_in[11:7];
    assign immI = {{21{inst_in[31]}},inst_in[30:25],inst_in[24:20]};
    assign immS = {{21{inst_in[31]}},inst_in[30:25],inst_in[11:7]};
    assign immB = {{20{inst_in[31]}},inst_in[7],inst_in[30:25],inst_in[11:8],1'b0};
    assign immU = {{1{inst_in[31]}},inst_in[30:20],inst_in[19:12],12'b0};
    assign immJ = {{12{inst_in[31]}},inst_in[19:12],inst_in[20],inst_in[30:25],inst_in[24:21],1'b0};


    always_comb begin
        case (opcode)
            `OPCODE_AUIPC: begin
                imm_out = immU;
                br_func_out = `BR_FUNC_NONE;
                pc_sel_out = `PC_SEL_NEXTPC;
                op1_sel_out = `OP1_PC;
                op2_sel_out = `OP2_IMM;
                writeback_sel_out = `WRITEBACK_ALU;
                alu_func_out = `ALU_FUNC_ADD;
                write_enable_rf_out = `ON;
                dmem_size_out = `MASK_NONE;
                dmem_read_enable_out = `OFF;
                dmem_write_enable_out = `OFF;
            end
            `OPCODE_LUI: begin
                imm_out = immU;
                br_func_out = `BR_FUNC_NONE;
                pc_sel_out = `PC_SEL_NEXTPC;
                op1_sel_out = `OP1_PC;
                op2_sel_out = `OP2_IMM;
                writeback_sel_out = `WRITEBACK_ALU;
                alu_func_out = `ALU_FUNC_LUI;
                write_enable_rf_out = `ON;
                dmem_size_out = `MASK_NONE;
                dmem_read_enable_out = `OFF;
                dmem_write_enable_out = `OFF;
            end
            `OPCODE_JAL: begin
                imm_out = immJ;
                br_func_out = `BR_FUNC_NONE;
                pc_sel_out = `PC_SEL_ALU;
                op1_sel_out = `OP1_PC;
                op2_sel_out = `OP2_IMM;
                writeback_sel_out = `WRITEBACK_PC4;
                alu_func_out = `ALU_FUNC_ADD;
                write_enable_rf_out = `ON;
                dmem_size_out = `MASK_NONE;
                dmem_read_enable_out = `OFF;
                dmem_write_enable_out = `OFF;
            end
            `OPCODE_JALR: begin
                imm_out = immI;
                br_func_out = `BR_FUNC_NONE;
                pc_sel_out = `PC_SEL_ALU;
                op1_sel_out = `OP1_RS1;
                op2_sel_out = `OP2_IMM;
                writeback_sel_out = `WRITEBACK_PC4;
                alu_func_out = `ALU_FUNC_JALR;
                write_enable_rf_out = `ON;
                dmem_size_out = `MASK_NONE;
                dmem_read_enable_out = `OFF;
                dmem_write_enable_out = `OFF;
            end
            `OPCODE_BR: begin
                imm_out = immB;
                case (funct3)
                    `FUNCT3_BR_EQ:  br_func_out = `BR_FUNC_EQ;
                    `FUNCT3_BR_NE:  br_func_out = `BR_FUNC_NE;
                    `FUNCT3_BR_LT:  br_func_out = `BR_FUNC_LT;
                    `FUNCT3_BR_GE:  br_func_out = `BR_FUNC_GE;
                    `FUNCT3_BR_LTU: br_func_out = `BR_FUNC_LTU;
                    `FUNCT3_BR_GEU: br_func_out = `BR_FUNC_GEU;
                endcase
                pc_sel_out = `PC_SEL_BRJMP;
                op1_sel_out = `OP1_RS1;
                op2_sel_out = `OP2_RS2;
                writeback_sel_out = `WRITEBACK_X;
                alu_func_out = `ALU_FUNC_BR;
                write_enable_rf_out = `OFF;
                dmem_size_out = `MASK_NONE;
                dmem_read_enable_out = `OFF;
                dmem_write_enable_out = `OFF;
            end
            `OPCODE_LOAD: begin
                imm_out = immI;
                br_func_out = `BR_FUNC_NONE;
                pc_sel_out = `PC_SEL_NEXTPC;
                op1_sel_out = `OP1_RS1;
                op2_sel_out = `OP2_IMM;
                writeback_sel_out = `WRITEBACK_DATA;
                alu_func_out = `ALU_FUNC_ADD;
                write_enable_rf_out = `ON;
                case (funct3)
                    `FUNCT3_MEM_B:   dmem_size_out = `MASK_B;
                    `FUNCT3_MEM_H:   dmem_size_out = `MASK_H;
                    `FUNCT3_MEM_W:   dmem_size_out = `MASK_W;
                    `FUNCT3_MEM_BU:  dmem_size_out = `MASK_BU;
                    `FUNCT3_MEM_HU:  dmem_size_out = `MASK_HU;
                    default:         dmem_size_out = `MASK_NONE;
                endcase
                dmem_read_enable_out = `ON;
                dmem_write_enable_out = `OFF;
            end
            `OPCODE_STORE: begin
                imm_out = immS;
                br_func_out = `BR_FUNC_NONE;
                pc_sel_out = `PC_SEL_NEXTPC;
                op1_sel_out = `OP1_RS1;
                op2_sel_out = `OP2_IMM;
                writeback_sel_out = `WRITEBACK_X;
                alu_func_out = `ALU_FUNC_ADD;
                write_enable_rf_out = `OFF;
                case (funct3)
                    `FUNCT3_MEM_B:   dmem_size_out = `MASK_B;
                    `FUNCT3_MEM_H:   dmem_size_out = `MASK_H;
                    `FUNCT3_MEM_W:   dmem_size_out = `MASK_W;
                    `FUNCT3_MEM_BU:  dmem_size_out = `MASK_BU;
                    `FUNCT3_MEM_HU:  dmem_size_out = `MASK_HU;
                    default:         dmem_size_out = `MASK_NONE;
                endcase
                dmem_read_enable_out = `OFF;
                dmem_write_enable_out = `ON;
            end
            `OPCODE_IMM: begin
                imm_out = immI;
                br_func_out = `BR_FUNC_NONE;
                pc_sel_out = `PC_SEL_NEXTPC;
                op1_sel_out = `OP1_RS1;
                op2_sel_out = `OP2_IMM;
                writeback_sel_out = `WRITEBACK_ALU;
                case (funct3)
                    `FUNCT3_ALU_ADD:     alu_func_out = `ALU_FUNC_ADD;
                    `FUNCT3_ALU_SLL:     alu_func_out = `ALU_FUNC_SLL;
                    `FUNCT3_ALU_SLT:     alu_func_out = `ALU_FUNC_SLT;
                    `FUNCT3_ALU_SLTU:    alu_func_out = `ALU_FUNC_SLTU;
                    `FUNCT3_ALU_XOR:     alu_func_out = `ALU_FUNC_XOR;
                    `FUNCT3_ALU_OR:      alu_func_out = `ALU_FUNC_OR;
                    `FUNCT3_ALU_SR:      alu_func_out = (funct7 === `FUNCT7_ALU_SRL) ?  `ALU_FUNC_SRL :
                                                        (funct7 === `FUNCT7_ALU_SRA) ?  `ALU_FUNC_SRA :
                                                        `ALU_FUNC_NONE;
                    `FUNCT3_ALU_AND:     alu_func_out = `ALU_FUNC_AND;
                    default:             alu_func_out = `ALU_FUNC_NONE;
                endcase
                write_enable_rf_out = `ON;
                dmem_size_out = `MASK_NONE;
                dmem_read_enable_out = `OFF;
                dmem_write_enable_out = `OFF;
            end
            `OPCODE_REG: begin
                imm_out = `ZERO;
                br_func_out = `BR_FUNC_NONE;
                pc_sel_out = `PC_SEL_NEXTPC;
                op1_sel_out = `OP1_RS1;
                op2_sel_out = `OP2_RS2;
                writeback_sel_out = `WRITEBACK_ALU;
                case (funct3)
                    `FUNCT3_ALU_ADD:     alu_func_out = (funct7 === `FUNCT7_ALU_ADD) ?  `ALU_FUNC_ADD :
                                                        (funct7 === `FUNCT7_ALU_SUB) ?  `ALU_FUNC_SUB :
                                                        `ALU_FUNC_NONE;
                    `FUNCT3_ALU_SLL:     alu_func_out = `ALU_FUNC_SLL;
                    `FUNCT3_ALU_SLT:     alu_func_out = `ALU_FUNC_SLT;
                    `FUNCT3_ALU_SLTU:    alu_func_out = `ALU_FUNC_SLTU;
                    `FUNCT3_ALU_XOR:     alu_func_out = `ALU_FUNC_XOR;
                    `FUNCT3_ALU_OR:      alu_func_out = `ALU_FUNC_OR;
                    `FUNCT3_ALU_SR:      alu_func_out = (funct7 === `FUNCT7_ALU_SRL) ?  `ALU_FUNC_SRL :
                                                        (funct7 === `FUNCT7_ALU_SRA) ?  `ALU_FUNC_SRA :
                                                        `ALU_FUNC_NONE;
                    `FUNCT3_ALU_AND:     alu_func_out = `ALU_FUNC_AND;
                    default:             alu_func_out = `ALU_FUNC_NONE;
                endcase
                write_enable_rf_out = `ON;
                dmem_size_out = `MASK_NONE;
                dmem_read_enable_out = `OFF;
                dmem_write_enable_out = `OFF;
            end
            default: begin
                imm_out = `ZERO;
                br_func_out = `BR_FUNC_NONE;
                pc_sel_out = `PC_SEL_NEXTPC;
                op1_sel_out = `OP1_PC;
                op2_sel_out = `OP2_IMM;
                writeback_sel_out = `WRITEBACK_X;
                alu_func_out = `ALU_FUNC_NONE;
                write_enable_rf_out = `OFF;
                dmem_size_out = `MASK_NONE;
                dmem_read_enable_out = `OFF;
                dmem_write_enable_out = `OFF;
            end
        endcase
    end
endmodule