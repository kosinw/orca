`timescale 1ns / 1ps
`default_nettype none
`include "hdl/riscv_constants.sv"

module riscv_core (
    input wire clk_in,
    input wire rst_in,

    input wire [31:0] imem_data_in,
    output logic [31:0] imem_addr_out,

    input wire [31:0] dmem_data_in,
    output logic [31:0] dmem_addr_out,
    output logic dmem_read_enable_out,
    output logic dmem_write_enable_out,
    output logic [3:0] dmem_byte_enable_out
);
    typedef struct packed {
        logic   [31:0]  pc;
        logic   [31:0]  instr;
    } InstructionDecodeState;

    typedef struct packed {
        logic   [4:0]   rd;
        logic   [31:0]  a;
        logic   [31:0]  b;
        logic   [2:0]   br_func;
        logic   [3:0]   alu_func;
        logic   [1:0]   pc_sel;
        logic   [1:0]   wb_sel;
        logic           werf;
        logic   [2:0]   dmem_size;
        logic           dmem_read_enable;
        logic           dmem_write_enable;
    } ExecuteState;

    typedef struct packed {
        logic   [4:0]   rd;
        logic   [31:0]  alu_result;
        logic   [1:0]   wb_sel;
        logic           werf;
        logic   [2:0]   dmem_size;
        logic           dmem_read_enable;
        logic           dmem_write_enable;
    } MemoryState;

    //
    //  The processor implements the base RV32I instruction set using a
    //  6-stage pipeline with 1 cycle instruction memory read and 2 cycle
    //  data memory read/write (in other words no cache misses.)
    //

    logic [31:0]            pc;

    InstructionDecodeState  ID;
    ExecuteState            EX;
    MemoryState             MEM1,MEM2;

    //////////////////////////////////////////////////////////////////////
    //
    // INSTRUCTION FETCH (IF)
    //
    //////////////////////////////////////////////////////////////////////

    logic [31:0] next_pc;

    assign imem_addr_out = pc;

    always_comb begin
        // TODO(kosinw): Check for:
        //  Branch annulment:
        //      Caused by JAL, JALR, and branch instructions (PC_SEL_ALU in EX)
        //  Stalls:
        //      Caused by load data hazard
        //      Caused by store data hazards
        next_pc = pc + 4;
    end

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            pc <= 0;
        end else begin
            pc <= next_pc;
        end
    end

    //////////////////////////////////////////////////////////////////////
    //
    // INSTRUCTION DECODE (ID)
    //
    //////////////////////////////////////////////////////////////////////

    InstructionDecodeState d;

    logic [4:0] id_rs1, id_rs2, id_rd;
    logic [31:0] id_rd1, id_rd2;
    logic [31:0] id_imm;
    logic [2:0] id_br_func;
    logic [1:0] id_pc_sel;
    logic id_op1_sel, id_op2_sel;
    logic [1:0] id_wb_sel;
    logic [3:0] id_alu_func;
    logic id_we_rf;
    logic [2:0] id_dmem_size;
    logic id_dmem_read_enable;
    logic id_dmem_write_enable;

    always_comb begin
        d = ID;

        // TODO(kosinw): Check for stall / annulment before updating this
        d.pc = pc;
        d.instr = imem_data_in;
    end

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            ID.pc <= 0;
            ID.instr <= 0;
        end else begin
            ID <= d;
        end
    end

    //////////////////////////////////////////////////////////////////////
    //
    // EXECUTE (EX)
    //
    //////////////////////////////////////////////////////////////////////

    ExecuteState x;

    logic [31:0] ex_alu_result;
    logic ex_br_taken;

    always_comb begin
        x = EX;

        // TODO(kosinw): Check for stall / annulment before updating this
        x.rd            = id_rd;
        x.a             = (id_op1_sel === `OP1_RS1) ? id_rd1 : d.pc;
        x.b             = (id_op2_sel === `OP2_RS2) ? id_rd2 : id_imm;
        x.br_func       = id_br_func;
        x.alu_func      = id_alu_func;
        x.pc_sel        = id_pc_sel;
        x.wb_sel        = id_wb_sel;
        x.werf          = id_we_rf;
        x.dmem_size     = id_dmem_size;

        x.dmem_read_enable = id_dmem_read_enable;
        x.dmem_write_enable = id_dmem_write_enable;
    end

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            EX.rd <= 0;
            EX.a <= 0;
            EX.b <= 0;
            EX.br_func <= 0;
            EX.alu_func <= 0;
            EX.pc_sel <= 0;
            EX.wb_sel <= 0;
            EX.werf <= 0;
            EX.dmem_size <= 0;
            EX.dmem_read_enable <= 0;
            EX.dmem_write_enable <= 0;
        end else begin
            EX <= x;
        end
    end

    //////////////////////////////////////////////////////////////////////
    //
    // MEMORY (MEM1 + MEM2)
    //
    //////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////
    //
    // SUBMODULES
    //
    //////////////////////////////////////////////////////////////////////

    riscv_decode decoder (
        .inst_in(ID.instr),
        .rs1_out(id_rs1),
        .rs2_out(id_rs2),
        .rd_out(id_rd),
        .imm_out(id_imm),
        .br_func_out(id_br_func),
        .pc_sel_out(id_pc_sel),
        .op1_sel_out(id_op1_sel),
        .op2_sel_out(id_op2_sel),
        .writeback_sel_out(id_wb_sel),
        .alu_func_out(id_alu_func),
        .write_enable_rf_out(id_we_rf),
        .dmem_size_out(id_dmem_size),
        .dmem_read_enable_out(id_dmem_read_enable),
        .dmem_write_enable_out(id_dmem_write_enable)
    );

    riscv_regfile regfile (
        .clk_in(clk_in),
        .rst_in(rst_in),

        .ra_in(id_rs1),
        .rd1_out(id_rd1),
        .rb_in(id_rs2),
        .rd2_out(id_rd2),

        .rd_in(5'b0),           // TDOO(kosinw): writeback
        .wd_in(32'b0),          // TODO(kosinw): writeback
        .write_enable_in(1'b0)  // TODO(kosinw): writeback
    );

    riscv_alu alu (
        .alu_func_in(EX.alu_func),
        .br_func_in(EX.br_func),
        .a_in(EX.a),
        .b_in(EX.b),
        .result_out(ex_alu_result),
        .branch_taken_out(ex_br_taken)
    );

endmodule