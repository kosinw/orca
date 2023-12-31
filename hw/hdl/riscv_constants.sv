`ifndef __riscv_constants__
`define __riscv_constants__

`define ON                  1'b1
`define OFF                 1'b0
`define ZERO                32'b0
`define NOP                 32'h00000013
`define X0                  5'h0

// opcodes
`define OPCODE_AUIPC        7'b0010111     // auipc
`define OPCODE_LUI          7'b0110111     // lui
`define OPCODE_JAL          7'b1101111     // jal
`define OPCODE_JALR         7'b1100111     // jalr
`define OPCODE_BR           7'b1100011     // beq, bne, blt, bge, bltu, bgeu
`define OPCODE_LOAD         7'b0000011     // lw, lh, lb, lhu, lbu
`define OPCODE_STORE        7'b0100011     // sw, sh, sb
`define OPCODE_IMM          7'b0010011     // addi, slli, slti, sltiu, xori, srli, srai, ori, andi
`define OPCODE_REG          7'b0110011     // add, sub, sll, slt, stlu, xor, srl, sra, or, and, mul[hsu], div[u], rem[u]

// funct3
`define FUNCT3_ALU_ADD      3'b000
`define FUNCT3_ALU_SLL      3'b001
`define FUNCT3_ALU_SLT      3'b010
`define FUNCT3_ALU_SLTU     3'b011
`define FUNCT3_ALU_XOR      3'b100
`define FUNCT3_ALU_SR       3'b101
`define FUNCT3_ALU_OR       3'b110
`define FUNCT3_ALU_AND      3'b111
`define FUNCT3_ALU_MUL      3'b000
`define FUNCT3_ALU_MULH     3'b001
`define FUNCT3_ALU_MULHSU   3'b010
`define FUNCT3_ALU_MULHU    3'b011
`define FUNCT3_ALU_DIV      3'b100
`define FUNCT3_ALU_DIVU     3'b101
`define FUNCT3_ALU_REM      3'b110
`define FUNCT3_ALU_REMU     3'b111

`define FUNCT3_MEM_B        3'b000
`define FUNCT3_MEM_H        3'b001
`define FUNCT3_MEM_W        3'b010
`define FUNCT3_MEM_BU       3'b100
`define FUNCT3_MEM_HU       3'b101

`define FUNCT3_BR_EQ        3'b000
`define FUNCT3_BR_NE        3'b001
`define FUNCT3_BR_LT        3'b100
`define FUNCT3_BR_GE        3'b101
`define FUNCT3_BR_LTU       3'b110
`define FUNCT3_BR_GEU       3'b111

// funct7
`define FUNCT7_ALU_ADD     7'b0000000
`define FUNCT7_ALU_SUB     7'b0100000
`define FUNCT7_ALU_SRL     7'b0000000
`define FUNCT7_ALU_SRA     7'b0100000
`define FUNCT7_ALU_MUL     7'b0000001

// alu func
`define ALU_FUNC_NONE       5'd0
`define ALU_FUNC_ADD        5'd1
`define ALU_FUNC_SUB        5'd2
`define ALU_FUNC_SLL        5'd3
`define ALU_FUNC_SLT        5'd4
`define ALU_FUNC_SLTU       5'd5
`define ALU_FUNC_XOR        5'd6
`define ALU_FUNC_SRL        5'd7
`define ALU_FUNC_SRA        5'd8
`define ALU_FUNC_OR         5'd9
`define ALU_FUNC_AND        5'd10
`define ALU_FUNC_JALR       5'd11
`define ALU_FUNC_COPY2      5'd12
`define ALU_FUNC_BR         5'd13
`define ALU_FUNC_MUL        5'd14
`define ALU_FUNC_MULH       5'd15
`define ALU_FUNC_MULHSU     5'd16
`define ALU_FUNC_MULHU      5'd17
`define ALU_FUNC_DIV        5'd18
`define ALU_FUNC_DIVU       5'd19
`define ALU_FUNC_REM        5'd20
`define ALU_FUNC_REMU       5'd21

// br func
`define BR_FUNC_NONE        3'd0
`define BR_FUNC_EQ          3'd1
`define BR_FUNC_NE          3'd2
`define BR_FUNC_LT          3'd3
`define BR_FUNC_GE          3'd4
`define BR_FUNC_LTU         3'd5
`define BR_FUNC_GEU         3'd6

// program counter select
`define PC_SEL_NEXTPC       2'd0
`define PC_SEL_BRJMP        2'd1
`define PC_SEL_ALU          2'd2

// operand one select
`define OP1_RS1            1'd0
`define OP1_PC             1'd1

// operand two select
`define OP2_RS2            1'd0
`define OP2_IMM            1'd1

// writeback select
`define WRITEBACK_X         2'd0
`define WRITEBACK_ALU       2'd1
`define WRITEBACK_PC4       2'd2
`define WRITEBACK_DATA      2'd3

// mask size
`define MASK_NONE           3'd0
`define MASK_B              3'd1
`define MASK_H              3'd2
`define MASK_W              3'd3
`define MASK_BU             3'd4
`define MASK_HU             3'd5

// all the instructions
`define AUIPC   32'b?????????????????????????0010111
`define LUI     32'b?????????????????????????0110111
`define JAL     32'b?????????????????????????1101111
`define JALR    32'b?????????????????000?????1100111
`define BEQ     32'b?????????????????000?????1100011
`define BNE     32'b?????????????????001?????1100011
`define BLT     32'b?????????????????100?????1100011
`define BGE     32'b?????????????????101?????1100011
`define BLTU    32'b?????????????????110?????1100011
`define BGEU    32'b?????????????????111?????1100011
`define LB      32'b?????????????????000?????0000011
`define LH      32'b?????????????????001?????0000011
`define LW      32'b?????????????????010?????0000011
`define LBU     32'b?????????????????100?????0000011
`define LHU     32'b?????????????????101?????0000011
`define SB      32'b?????????????????000?????0100011
`define SH      32'b?????????????????001?????0100011
`define SW      32'b?????????????????010?????0100011
`define ADDI    32'b?????????????????000?????0010011
`define SLTI    32'b?????????????????010?????0010011
`define SLTIU   32'b?????????????????011?????0010011
`define XORI    32'b?????????????????100?????0010011
`define ORI     32'b?????????????????110?????0010011
`define ANDI    32'b?????????????????111?????0010011
`define SLLI    32'b0000000??????????001?????0010011
`define SRLI    32'b0000000??????????101?????0010011
`define SRAI    32'b0100000??????????101?????0010011
`define ADD     32'b0000000??????????000?????0110011
`define SUB     32'b0100000??????????000?????0110011
`define SLL     32'b0000000??????????001?????0110011
`define SLT     32'b0000000??????????010?????0110011
`define SLTU    32'b0000000??????????011?????0110011
`define XOR     32'b0000000??????????100?????0110011
`define SRL     32'b0000000??????????101?????0110011
`define SRA     32'b0100000??????????101?????0110011
`define OR      32'b0000000??????????110?????0110011
`define AND     32'b0000000??????????111?????0110011

`endif