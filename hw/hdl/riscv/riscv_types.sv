`ifndef __riscv_types__
`define __riscv_types__

////////////////////////////////////////////////////////
//
//  DATA MEMORY
//
////////////////////////////////////////////////////////

typedef enum {
    MEM_X,
    MEM_LD,
    MEM_ST
} MemoryFunction;

typedef enum {
    MASK_X,
    MASK_W,
    MASK_B,
    MASK_H,
    MASK_BU,
    MASK_HU
} MemoryMask;

typedef struct packed {
    logic   [31:0]      data;
    logic   [31:0]      addr;
    logic               enable;
    MemoryMask          mask;
    MemoryFunction      fn;
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
    BR_EQ,
    BR_NE,
    BR_LT,
    BR_LTU,
    BR_GE,
    BR_GEU
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
    ALU_JAL,
    ALU_JALR,
    ALU_COPY1,
    ALU_COPY2
} AluFunc;

typedef enum {
    PC_PC4,
    PC_ALU,
    PC_BR
} PcSel;

typedef enum {
    OP1_X,
    OP1_RS1,    // used for most instructions
    OP1_PC      // used for AUIPC
} Op1Sel;

typedef enum {
    OP2_X,
    OP2_RS2,    // used for arithmetic instructions
    OP2_IMM     // used for immediate
} Op2Sel;

typedef enum {
    WB_X,
    WB_ALU,     // writeback from ALU
    WB_PC4,     // writeback from PC + 4
    WB_MEM      // writeback from data memory
} WritebackSel;

typedef struct packed {
    logic           valid;      // is the output instruction valid
    logic [4:0]     rs1_sel;    // selection for rs1
    logic [4:0]     rs2_sel;    // selection for rs2
    logic [4:0]     rd_sel;     // selection for rd
    logic [31:0]    imm;        // immediate value
    AluFunc         alu_func;   // alu operation
    BrFunc          br_func;    // br operation
    Op1Sel          op1_sel;    // which item to select for operand 1
    Op2Sel          op2_sel;    // which item to select for operand 2
    WritebackSel    wb_sel;     // which item to writeback to in later stages
    logic           werf;       // do we writeback to register file in WB stage?
    logic           mem_enable; // is memory enabled?
    PcSel           pc_sel;     // program counter select
    MemoryFunction  mem_fn;     // load or store?
    MemoryMask      mem_mask;   // byte vs halfword vs word
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

`endif