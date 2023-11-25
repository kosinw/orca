`define ADD               6'b00_0000
`define SUB               6'b00_0001
`define XOR               6'b00_0010
`define OR                6'b00_0011
`define AND               6'b00_0100
`define SLL               6'b00_0101
`define SRL               6'b00_0110
`define SRA               6'b00_0111
`define SLT               6'b00_1000
`define SLTU              6'b00_1001

`define ADDI              6'b00_1010
`define XORI              6'b00_1011
`define ORI               6'b00_1100
`define ANDI              6'b00_1101
`define SLLI              6'b00_1110
`define SRLI              6'b00_1111
`define SRAI              6'b01_0000
`define SLTI              6'b01_0001
`define SLTIU             6'b01_0010

`define LB                6'b01_0011
`define LH                6'b01_0100
`define LW                6'b01_0101
`define LBU               6'b01_0110
`define LHU               6'b01_0111

`define SB                6'b01_1000
`define SH                6'b01_1001
`define SW                6'b01_1010

`define BEQ               6'b01_1011
`define BNE               6'b01_1100
`define BLT               6'b01_1101
`define BGE               6'b01_1110
`define BLTU              6'b01_1111
`define BGEU              6'b10_0000

`define JAL               6'b10_0001
`define JALR              6'b10_0010

`define LUI               6'b10_0011
`define AUIPC             6'b10_0100

`define ECALL             6'b10_0101
`define EBREAK            6'b10_0110

`define MUL               6'b10_0111
`define MULH              6'b10_1000
`define MULSU             6'b10_1001
`define MULU              6'b10_1010
`define DIV               6'b10_1011
`define DIVU              6'b10_1100
`define REM               6'b10_1101
`define REMU              6'b10_1110