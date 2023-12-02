`timescale 1ns / 1ps
`default_nettype none
`include "hdl/riscv_constants.sv"

module riscv_core (
    input wire clk_in,
    input wire rst_in,

    input  wire  [31:0] imem_data_in,
    output logic [31:0] imem_addr_out,

    output logic [31:0] dmem_addr_out,
    output logic [31:0] dmem_data_out,
    output logic [3:0]  dmem_write_enable_out,
    input  wire  [31:0] dmem_data_in
);
    typedef struct packed {
        logic   [31:0]  pc;
        logic   [31:0]  instr;
    } InstructionDecodeState;

    typedef struct packed {
        logic   [31:0]  pc;
        logic   [31:0]  br_target;
        logic   [31:0]  rd2;
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
        logic   [31:0]  pc;
        logic   [4:0]   rd;
        logic   [31:0]  alu_result;
        logic   [31:0]  rd2;
        logic   [1:0]   wb_sel;
        logic           werf;
        logic   [2:0]   dmem_size;
        logic           dmem_read_enable;
        logic           dmem_write_enable;
    } MemoryState;

    typedef struct packed {
        logic   [31:0]  pc;
        logic   [4:0]   rd;
        logic   [31:0]  result;
        logic           werf;
        logic   [1:0]   wb_sel;
    } WritebackState;

    //
    //  The processor implements the base RV32I instruction set using a
    //  6-stage pipeline with 1 cycle instruction memory read and 2 cycle
    //  data memory read/write (in other words no cache misses.)
    //

    logic [31:0]            PC;
    InstructionDecodeState  ID;
    ExecuteState            EX;
    MemoryState             MEM;
    WritebackState          WB1, WB2;

    // ID stage combinational signals
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

    // EX stage combinational signals
    logic [31:0] ex_alu_result;
    logic ex_br_taken;

    //////////////////////////////////////////////////////////////////////
    //
    // INSTRUCTION FETCH (IF)
    //
    //////////////////////////////////////////////////////////////////////

    assign imem_addr_out = PC[31:2];

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            PC <= 0;
        end else begin
            // TODO(kosinw): Check for stall / annulment before updating this
            case (EX.pc_sel)
                `PC_SEL_NEXTPC:     PC <= PC + 4;
                `PC_SEL_BRJMP:      PC <= (ex_br_taken) ? EX.br_target : PC + 4;
                `PC_SEL_ALU:        PC <= ex_alu_result;
                default:            PC <= PC + 4;
            endcase
        end
    end

    //////////////////////////////////////////////////////////////////////
    //
    // INSTRUCTION DECODE (ID)
    //
    //////////////////////////////////////////////////////////////////////

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            ID <= '0;
        end else begin
            // TODO(kosinw): Check for stall / annulment before updating this
            ID.pc <= PC;
            ID.instr <= imem_data_in;
        end
    end

    // logic [4:0] id_rs1, id_rs2, id_rd;
    // logic [31:0] id_rd1, id_rd2;
    // logic [31:0] id_imm;
    // logic [2:0] id_br_func;
    // logic [1:0] id_pc_sel;
    // logic id_op1_sel, id_op2_sel;
    // logic [1:0] id_wb_sel;
    // logic [3:0] id_alu_func;
    // logic id_we_rf;
    // logic [2:0] id_dmem_size;
    // logic id_dmem_read_enable;
    // logic id_dmem_write_enable;

    //////////////////////////////////////////////////////////////////////
    //
    // EXECUTE (EX)
    //
    //////////////////////////////////////////////////////////////////////

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            EX <= '0;
        end else begin
            // TODO(kosinw): Check for stall / annulment before updating this
            EX.pc        <= ID.pc;
            EX.br_target <= id_imm + ID.pc;
            EX.rd2       <= id_rd2;
            EX.rd        <= id_rd;
            EX.a         <= (id_op1_sel === `OP1_RS1) ? id_rd1 : ID.pc;
            EX.b         <= (id_op2_sel === `OP2_RS2) ? id_rd2 : id_imm;
            EX.br_func   <= id_br_func;
            EX.alu_func  <= id_alu_func;
            EX.pc_sel    <= id_pc_sel;
            EX.wb_sel    <= id_wb_sel;
            EX.werf      <= id_we_rf;
            EX.dmem_size <= id_dmem_size;
            EX.dmem_read_enable <= id_dmem_read_enable;
            EX.dmem_write_enable <= id_dmem_write_enable;
        end
    end

    // logic [31:0] ex_alu_result;
    // logic ex_br_taken;

    //////////////////////////////////////////////////////////////////////
    //
    // MEMORY (MEM)
    //
    //////////////////////////////////////////////////////////////////////

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            MEM <= '0;
        end else begin
            MEM.pc <= EX.pc;
            MEM.rd <= EX.rd;
            MEM.alu_result <= ex_alu_result;
            MEM.rd2 <= EX.rd2;
            MEM.wb_sel <= EX.wb_sel;
            MEM.werf <= EX.werf;
            MEM.dmem_size <= EX.dmem_size;
            MEM.dmem_read_enable <= EX.dmem_read_enable;
            MEM.dmem_write_enable <= EX.dmem_write_enable;
        end
    end

    logic [31:0] mem_data_out;

    //////////////////////////////////////////////////////////////////////
    //
    // WRITEBACK (WB)
    //
    //////////////////////////////////////////////////////////////////////

    logic [31:0] wb_data;

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            WB1 <= '0;
            WB2 <= '0;
        end else begin
            WB1.pc       <= MEM.pc;
            WB1.rd       <= MEM.rd;
            WB1.result   <= MEM.alu_result;
            WB1.werf     <= MEM.werf;
            WB1.wb_sel   <= MEM.wb_sel;

            WB2 <= WB1;
        end
    end

    always_comb begin
        case (WB2.wb_sel)
            `WRITEBACK_ALU:     wb_data = WB2.result;
            `WRITEBACK_PC4:     wb_data = WB2.pc + 4;
            `WRITEBACK_DATA:    wb_data = mem_data_out;
            default:            wb_data = 32'h0;
        endcase
    end

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
        .rd_in(WB2.rd),
        .wd_in(wb_data),
        .write_enable_in(WB2.werf)
    );

    riscv_alu alu (
        .alu_func_in(EX.alu_func),
        .br_func_in(EX.br_func),
        .a_in(EX.a),
        .b_in(EX.b),
        .result_out(ex_alu_result),
        .branch_taken_out(ex_br_taken)
    );

    riscv_memory_iface dmem_iface (
        .clk_in(clk_in),
        .rst_in(rst_in),

        .cpu_addr_in(MEM.alu_result),
        .cpu_data_in(MEM.rd2),
        .cpu_size_in(MEM.dmem_size),
        .cpu_read_enable_in(MEM.dmem_read_enable),
        .cpu_write_enable_in(MEM.dmem_write_enable),
        .cpu_data_out(mem_data_out),

        .mem_addr_out(dmem_addr_out),
        .mem_data_out(dmem_data_out),
        .mem_write_enable(dmem_write_enable_out),
        .mem_data_in(dmem_data_in)
    );

endmodule