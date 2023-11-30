`timescale 1ns / 1ps
`default_nettype none
`include "riscv_types.sv"

module riscv_decode(
    input wire [31:0] inst_in,
    output DecodeOut dec_out
);
    logic [4:0]  rd, rs1, rs2;
    logic [31:0] immR, immI, immS, immB, immU, immJ;

    localparam logic T = 1'b1;
    localparam logic F = 1'b0;

    always_comb begin
        rd = inst_in[11:7];
        rs1 = inst_in[19:15];
        rs2 = inst_in[24:20];

        immR = 32'h0;
        immI = $signed(inst_in[31:20]);
        immS = $signed({inst_in[31:25],inst_in[11:7]});
        immB = $signed({inst_in[31],inst_in[7],inst_in[30:25],inst_in[11:8],1'b0});
        immU = {inst[31:12],12'b0};
        immJ = $signed({inst[31],inst[19:12],inst[20],inst[30:12],1'b0});

        case (inst_in)
            // add upper immediate program counter // load upper immediate
            `AUIPC: dec_out = '{T,rs1,rs2,rd,immU,ALU_ADD  ,BR_X  ,OP1_PC ,OP2_IMM,WB_ALU,T,F,PC_PC4,MEM_X ,MASK_X};
            `LUI:   dec_out = '{T,rs1,rs2,rd,immU,ALU_COPY2,BR_X  ,OP1_X  ,OP2_IMM,WB_ALU,T,F,PC_PC4,MEM_X ,MASK_X};

            // jump and link // jump and link register
            `JAL:   dec_out = '{T,rs1,rs2,rd,immJ,ALU_JAL  ,BR_X  ,OP1_X  ,OP2_IMM,WB_PC4,T,F,PC_ALU,MEM_X ,MASK_X};
            `JALR:  dec_out = '{T,rs1,rs2,rd,immI,ALU_JALR ,BR_X  ,OP1_RS1,OP2_IMM,WB_PC4,T,F,PC_ALU,MEM_X ,MASK_X};

            // branch instructions
            `BEQ:   dec_out = '{T,rs1,rs2,rd,immB,ALU_X    ,BR_EQ ,OP1_RS1,OP2_RS2,WB_X  ,F,F,PC_BR ,MEM_X ,MASK_X};
            `BNE:   dec_out = '{T,rs1,rs2,rd,immB,ALU_X    ,BR_NE ,OP1_RS1,OP2_RS2,WB_X  ,F,F,PC_BR ,MEM_X ,MASK_X};
            `BLT:   dec_out = '{T,rs1,rs2,rd,immB,ALU_X    ,BR_LT ,OP1_RS1,OP2_RS2,WB_X  ,F,F,PC_BR ,MEM_X ,MASK_X};
            `BGE:   dec_out = '{T,rs1,rs2,rd,immB,ALU_X    ,BR_GE ,OP1_RS1,OP2_RS2,WB_X  ,F,F,PC_BR ,MEM_X ,MASK_X};
            `BLTU:  dec_out = '{T,rs1,rs2,rd,immB,ALU_X    ,BR_LTU,OP1_RS1,OP2_RS2,WB_X  ,F,F,PC_BR ,MEM_X ,MASK_X};
            `BGEU:  dec_out = '{T,rs1,rs2,rd,immB,ALU_X    ,BR_GEU,OP1_RS1,OP2_RS2,WB_X  ,F,F,PC_BR ,MEM_X ,MASK_X};

            // load / store instructions
            `LB:    dec_out = '{T,rs1,rs2,rd,immI,ALU_ADD  ,BR_X  ,OP1_RS1,OP2_IMM,WB_MEM,T,T,PC_PC4,MEM_LD,MASK_B};
            `LH:    dec_out = '{T,rs1,rs2,rd,immI,ALU_ADD  ,BR_X  ,OP1_RS1,OP2_IMM,WB_MEM,T,T,PC_PC4,MEM_LD,MASK_H};
            `LW:    dec_out = '{T,rs1,rs2,rd,immI,ALU_ADD  ,BR_X  ,OP1_RS1,OP2_IMM,WB_MEM,T,T,PC_PC4,MEM_LD,MASK_W};
            `LBU:   dec_out = '{T,rs1,rs2,rd,immI,ALU_ADD  ,BR_X  ,OP1_RS1,OP2_IMM,WB_MEM,T,T,PC_PC4,MEM_LD,MASK_BU};
            `LHU:   dec_out = '{T,rs1,rs2,rd,immI,ALU_ADD  ,BR_X  ,OP1_RS1,OP2_IMM,WB_MEM,T,T,PC_PC4,MEM_LD,MASK_HU};
            `SB:    dec_out = '{T,rs1,rs2,rd,immS,ALU_ADD  ,BR_X  ,OP1_RS1,OP2_IMM,WB_X  ,F,T,PC_PC4,MEM_ST,MASK_B};
            `SH:    dec_out = '{T,rs1,rs2,rd,immS,ALU_ADD  ,BR_X  ,OP1_RS1,OP2_IMM,WB_X  ,F,T,PC_PC4,MEM_ST,MASK_H};
            `SW:    dec_out = '{T,rs1,rs2,rd,immS,ALU_ADD  ,BR_X  ,OP1_RS1,OP2_IMM,WB_X  ,F,T,PC_PC4,MEM_ST,MASK_W};

            // register immediate instructions
            `ADDI:  dec_out = '{T,rs1,rs2,rd,immI,ALU_ADD  ,BR_X  ,OP1_RS1,OP2_IMM,WB_ALU,T,F,PC_PC4,MEM_X ,MASK_X};
            `SLTI:  dec_out = '{T,rs1,rs2,rd,immI,ALU_SLT  ,BR_X  ,OP1_RS1,OP2_IMM,WB_ALU,T,F,PC_PC4,MEM_X ,MASK_X};
            `SLTIU: dec_out = '{T,rs1,rs2,rd,immI,ALU_SLTU ,BR_X  ,OP1_RS1,OP2_IMM,WB_ALU,T,F,PC_PC4,MEM_X ,MASK_X};
            `XORI:  dec_out = '{T,rs1,rs2,rd,immI,ALU_XOR  ,BR_X  ,OP1_RS1,OP2_IMM,WB_ALU,T,F,PC_PC4,MEM_X ,MASK_X};
            `ORI:   dec_out = '{T,rs1,rs2,rd,immI,ALU_OR   ,BR_X  ,OP1_RS1,OP2_IMM,WB_ALU,T,F,PC_PC4,MEM_X ,MASK_X};
            `ANDI:  dec_out = '{T,rs1,rs2,rd,immI,ALU_AND  ,BR_X  ,OP1_RS1,OP2_IMM,WB_ALU,T,F,PC_PC4,MEM_X ,MASK_X};
            `SLLI:  dec_out = '{T,rs1,rs2,rd,immI,ALU_SLL  ,BR_X  ,OP1_RS1,OP2_IMM,WB_ALU,T,F,PC_PC4,MEM_X ,MASK_X};
            `SRLI:  dec_out = '{T,rs1,rs2,rd,immI,ALU_SRL  ,BR_X  ,OP1_RS1,OP2_IMM,WB_ALU,T,F,PC_PC4,MEM_X ,MASK_X};
            `SRAI:  dec_out = '{T,rs1,rs2,rd,immI,ALU_SRA  ,BR_X  ,OP1_RS1,OP2_IMM,WB_ALU,T,F,PC_PC4,MEM_X ,MASK_X};

            // register register instructions
            `ADD:   dec_out = '{T,rs1,rs2,rd,immI,ALU_ADD  ,BR_X  ,OP1_RS1,OP2_IMM,WB_ALU,T,F,PC_PC4,MEM_X ,MASK_X};
            `SUB:   dec_out = '{T,rs1,rs2,rd,immI,ALU_SUB  ,BR_X  ,OP1_RS1,OP2_IMM,WB_ALU,T,F,PC_PC4,MEM_X ,MASK_X};
            `SLL:   dec_out = '{T,rs1,rs2,rd,immI,ALU_SLL  ,BR_X  ,OP1_RS1,OP2_IMM,WB_ALU,T,F,PC_PC4,MEM_X ,MASK_X};
            `SLT:   dec_out = '{T,rs1,rs2,rd,immI,ALU_SLT  ,BR_X  ,OP1_RS1,OP2_IMM,WB_ALU,T,F,PC_PC4,MEM_X ,MASK_X};
            `SLTU:  dec_out = '{T,rs1,rs2,rd,immI,ALU_SLTU ,BR_X  ,OP1_RS1,OP2_IMM,WB_ALU,T,F,PC_PC4,MEM_X ,MASK_X};
            `XOR:   dec_out = '{T,rs1,rs2,rd,immI,ALU_XOR  ,BR_X  ,OP1_RS1,OP2_IMM,WB_ALU,T,F,PC_PC4,MEM_X ,MASK_X};
            `SRL:   dec_out = '{T,rs1,rs2,rd,immI,ALU_SRL  ,BR_X  ,OP1_RS1,OP2_IMM,WB_ALU,T,F,PC_PC4,MEM_X ,MASK_X};
            `SRA:   dec_out = '{T,rs1,rs2,rd,immI,ALU_SRA  ,BR_X  ,OP1_RS1,OP2_IMM,WB_ALU,T,F,PC_PC4,MEM_X ,MASK_X};
            `OR:    dec_out = '{T,rs1,rs2,rd,immI,ALU_OR   ,BR_X  ,OP1_RS1,OP2_IMM,WB_ALU,T,F,PC_PC4,MEM_X ,MASK_X};
            `AND:   dec_out = '{T,rs1,rs2,rd,immI,ALU_AND  ,BR_X  ,OP1_RS1,OP2_IMM,WB_ALU,T,F,PC_PC4,MEM_X ,MASK_X};

            // invalid instruction
            default: dec_out = '{F,rs1,rs2,rd,32'b0,ALU_X,BR_X,OP1_X,OP2_X,WB_X,F,F,PC_PC4,MEM_X,MASK_X};
        endcase
    end
endmodule