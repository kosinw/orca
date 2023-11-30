`ifndef __riscv_types__
`define __riscv_types__

////////////////////////////////////////////////////////
//
//  MEMORY
//
////////////////////////////////////////////////////////

localparam logic REQ_RD = 1'b0;
localparam logic REQ_WR = 1'b1;

typedef struct packed {
    logic   [31:0]      data;
    logic   [31:0]      addr;
    logic               valid;
    logic               kind;
} MemoryRequest;

typedef struct packed {
    logic   [31:0]      data;
    logic               valid;
} MemoryResponse;

////////////////////////////////////////////////////////
//
//  ALU
//
////////////////////////////////////////////////////////

typedef enum {
    BR_X,       // no branch
    BR_EQ,      // beq
    BR_NE,      // bne
    BR_LT,      // blt
    BR_LTU,     // bltu
    BR_GE,      // bge
    BR_GEU,     // bgeu
    BR_J,       // jal
    BR_JR       // jalr
} BrFunc;

typedef enum {
    ALU_X,      // no alu
    ALU_ADD,
    ALU_SUB,
    ALU_AND,
    ALU_OR,
    ALU_XOR,
    ALU_SLT,
    ALU_SLTU,
    ALU_SLL,
    ALU_SRL,
    ALU_SRA,
    ALU_COPY1,
    ALU_COPY2
} AluFunc;

////////////////////////////////////////////////////////
//
//  DECODE
//
////////////////////////////////////////////////////////

typedef struct packed {
    logic           valid;      // is the output instruction valid
    BrFunc          br
} DecodeOut;

////////////////////////////////////////////////////////
//
//  PIPELINE
//
////////////////////////////////////////////////////////

typedef struct packed {
    logic   [31:0]  pc; // program counter
} InstructionFetchState;

typedef struct packed {
    logic   [31:0] pc;      // program counter from IF/ID pipeline register
    logic   [31:0] instr;   // instruction from instruction memory
} InstructionDecodeState;

typedef struct packed {
    logic   [31:0]  pc;         // program counter from ID/EX pipeline register
    logic   [31:0]  instr;      // instruction from ID/EX pipeline register

    logic   [4:0]   rd_addr;    // address of dest register
    logic   [4:0]   rs1_addr;   // address of source register 1 (used to check bypasses)
    logic   [4:0]   rs2_addr;   // address of source register 2

    AluFunc         alu_func;   // operand for alu
    logic   [31:0]  op1_data;   // data of operand 1 for ALU
    logic   [31:0]  op2_data;   // data of operand 2 for ALU

    BrFunc          br_func;    // operand for branch hardware
} ExecuteState;

`endif