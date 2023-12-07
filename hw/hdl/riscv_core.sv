`timescale 1ns / 1ps
`default_nettype none
`include "hdl/riscv_constants.sv"

module riscv_core (
    input wire clk_in,
    input wire rst_in,

    input wire cpu_step_in,

    input  wire  [31:0] imem_data_in,
    output logic [31:0] imem_addr_out,

    output logic [31:0] dmem_addr_out,
    output logic [31:0] dmem_data_out,
    output logic [3:0]  dmem_write_enable_out,
    input  wire  [31:0] dmem_data_in,

    input wire [7:0] debug_in,
    output logic [31:0] debug_out
);
    typedef struct packed {
        logic   [31:0]  pc;
        logic   [31:0]  instr;
    } InstructionDecodeState;

    typedef struct packed {
        logic   [31:0]  pc;
        logic   [31:0]  br_target;
        logic   [31:0]  imm;
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
        logic   [31:0]  addr;
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
    //  5-stage pipeline with 2 cycle instruction memory read and 2 cycle
    //  data memory read/write (no caching)
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
    logic [31:0] id_operand_a;
    logic [31:0] id_operand_b;

    // debugging signals
    logic [4:0] reg_debug_in;
    logic [31:0] reg_debug_out;

    // EX stage combinational signals
    logic [31:0] ex_alu_result;
    logic ex_br_taken;

    // MEM stage combinational signals
    logic [31:0] mem_data_out;

    // WB2 stage combinational signals
    logic [31:0] wb_data;

    // Hazard management combinational signals
    logic ltu_stall_rs1;
    logic ltu_stall_rs2;

    logic raw_rs1_ex;
    logic raw_rs2_ex;
    logic raw_rs1_mem;
    logic raw_rs2_mem;
    logic raw_rs1_wb1;
    logic raw_rs2_wb1;
    logic raw_rs1_wb2;
    logic raw_rs2_wb2;

    logic stall;
    logic annul;

    // probes for testbenching
`ifndef TOPLEVEL
    logic           DEBUG0_STALL;
    logic           DEBUG0_BYPASS;
    logic           DEBUG0_ANNUL;
    logic [31:0]    DEBUG0_IF_PC;
    logic [31:0]    DEBUG1_ID_PC;
    logic [31:0]    DEBUG1_ID_INSTR;
    logic [4:0]     DEBUG1_ID_RS1;
    logic [4:0]     DEBUG1_ID_RS2;
    logic [4:0]     DEBUG1_ID_RD;
    logic [31:0]    DEBUG1_ID_X1;
    logic [31:0]    DEBUG1_ID_X2;
    logic [31:0]    DEBUG1_ID_IMM;
    logic [31:0]    DEBUG2_EX_A;
    logic [31:0]    DEBUG2_EX_B;
    logic [31:0]    DEBUG2_EX_RESULT;
    logic [3:0]     DEBUG2_EX_ALU_FUNC;
    logic           DEBUG2_EX_BRANCH_TAKEN;
    logic [31:0]    DEBUG3_MEM_ADDR;
    logic [31:0]    DEBUG3_MEM_DATA;
    logic           DEBUG3_MEM_READ_ENABLE;
    logic           DEBUG3_MEM_WRITE_ENABLE;
    logic [1:0]     DEBUG4_WB_SEL;
    logic [31:0]    DEBUG5_WB_DATA;
    logic [4:0]     DEBUG5_WB_RD;
    logic [31:0]    DEBUG5_WB_RESULT;
    logic [31:0]    DEBUG5_WB_PC;
    logic           DEBUG5_WB_WERF;

    assign DEBUG0_STALL = stall;
    assign DEBUG0_BYPASS = (raw_rs1_ex || raw_rs1_mem || raw_rs1_wb1) ||
                           (raw_rs1_wb2 || raw_rs2_ex || raw_rs2_mem) ||
                           (raw_rs2_wb1 || raw_rs2_wb2);
    assign DEBUG0_ANNUL = annul;
    assign DEBUG0_IF_PC = PC;
    assign DEBUG1_ID_PC = ID.pc;
    assign DEBUG1_ID_INSTR = ID.instr;
    assign DEBUG1_ID_RS1 = id_rs1;
    assign DEBUG1_ID_RS2 = id_rs2;
    assign DEBUG1_ID_RD  = id_rd;
    assign DEBUG1_ID_X1  = id_rd1;
    assign DEBUG1_ID_X2  = id_rd2;
    assign DEBUG1_ID_IMM = id_imm;
    assign DEBUG2_EX_A   = EX.a;
    assign DEBUG2_EX_B   = EX.b;
    assign DEBUG2_EX_RESULT = ex_alu_result;
    assign DEBUG2_EX_ALU_FUNC = EX.alu_func;
    assign DEBUG2_EX_BRANCH_TAKEN = ex_br_taken;
    assign DEBUG3_MEM_ADDR = MEM.addr;
    assign DEBUG3_MEM_DATA = MEM.alu_result;
    assign DEBUG3_MEM_READ_ENABLE = MEM.dmem_read_enable;
    assign DEBUG3_MEM_WRITE_ENABLE = MEM.dmem_write_enable;
    assign DEBUG4_WB_SEL = WB1.wb_sel;
    assign DEBUG5_WB_DATA = mem_data_out;
    assign DEBUG5_WB_RD = WB2.rd;
    assign DEBUG5_WB_RESULT = WB2.result;
    assign DEBUG5_WB_PC = WB2.pc;
    assign DEBUG5_WB_WERF = WB2.werf;
`endif // TOPLEVEL


    //////////////////////////////////////////////////////////////////////
    //
    // TOP LEVEL DEBUG
    //
    //////////////////////////////////////////////////////////////////////

    always_comb begin
        reg_debug_in = debug_in[4:0];
        case (debug_in[7:5])
            3'b000:     debug_out = ID.pc;
            3'b001:     debug_out = reg_debug_out;
            3'b010:     debug_out = ID.instr;
            3'b011:     debug_out = dmem_addr_out;
            3'b100:     debug_out = {28'b0, dmem_write_enable_out};
            3'b101:     debug_out = dmem_data_in;
            3'b110:     debug_out = PC;
            default:    debug_out = 32'hDEADBEEF;
        endcase
    end

    //////////////////////////////////////////////////////////////////////
    //
    // HAZARD MANAGEMENT
    //
    //////////////////////////////////////////////////////////////////////

    assign annul = (EX.pc_sel === `PC_SEL_BRJMP && ex_br_taken) || (EX.pc_sel === `PC_SEL_ALU);

    // Load-to-use hazard is active when:
    //  - The incident register cannot be x0
    //  - The current instruction is actually using RS1/RS2
    //  - There is a load instruction in EX, MEM, or WB1
    //  - Said load instruction has an RD equal to RS1/RS2
    //  - ENSURE THERE IS A BYPASS FROM WB2

    assign ltu_stall_rs1 = id_rs1 != 5'b0 && (id_op1_sel === `OP1_RS1) &&
                           ((EX.wb_sel === `WRITEBACK_DATA && EX.rd === id_rs1) ||
                            (MEM.wb_sel === `WRITEBACK_DATA && MEM.rd === id_rs1) ||
                            (WB1.wb_sel === `WRITEBACK_DATA && WB1.rd == id_rs1));

    assign ltu_stall_rs2 = id_rs2 != 5'b0 && (id_op2_sel === `OP2_RS2) &&
                        ((EX.wb_sel === `WRITEBACK_DATA && EX.rd === id_rs2) ||
                        (MEM.wb_sel === `WRITEBACK_DATA && MEM.rd === id_rs2) ||
                        (WB1.wb_sel === `WRITEBACK_DATA && WB1.rd == id_rs2));

    assign stall = ltu_stall_rs1 || ltu_stall_rs2;

    // Read-after-write hazard is active when:
    //  - The incident register cannot be x0
    //  - The current instruction is actually using RS1/RS2
    //  - There is an instruction further in the pipeline which writebacks to register file (WERF)
    //  - Destination register of writeback instruction matches RS1 (or RS2)

    assign raw_rs1_ex  = id_rs1 != 5'b0 && (id_op1_sel === `OP1_RS1) && (EX.werf  && EX.rd  === id_rs1);
    assign raw_rs1_mem = id_rs1 != 5'b0 && (id_op1_sel === `OP1_RS1) && (MEM.werf && MEM.rd === id_rs1);
    assign raw_rs1_wb1 = id_rs1 != 5'b0 && (id_op1_sel === `OP1_RS1) && (WB1.werf && WB1.rd === id_rs1);
    assign raw_rs1_wb2 = id_rs1 != 5'b0 && (id_op1_sel === `OP1_RS1) && (WB2.werf && WB2.rd === id_rs1);

    // NOTE(kosinw): Edge case where stores use RS2 but not in operator select
    assign raw_rs2_ex  = id_rs2 != 5'b0 && (id_op2_sel === `OP2_RS2) && (EX.werf  && EX.rd  === id_rs2);
    assign raw_rs2_mem = id_rs2 != 5'b0 && (id_op2_sel === `OP2_RS2) && (MEM.werf && MEM.rd === id_rs2);
    assign raw_rs2_wb1 = id_rs2 != 5'b0 && (id_op2_sel === `OP2_RS2) && (WB1.werf && WB1.rd === id_rs2);
    assign raw_rs2_wb2 = id_rs2 != 5'b0 && (id_op2_sel === `OP2_RS2) && (WB2.werf && WB2.rd === id_rs2);

    always_comb begin
        if (raw_rs1_ex) begin
            case (EX.wb_sel)
                `WRITEBACK_PC4:     id_operand_a = EX.pc + 4;
                default:            id_operand_a = ex_alu_result;
            endcase
        end else if (raw_rs1_mem) begin
            case (MEM.wb_sel)
                `WRITEBACK_PC4:     id_operand_a = MEM.pc + 4;
                default:            id_operand_a = MEM.alu_result;
            endcase
        end else if (raw_rs1_wb1) begin
            case (WB1.wb_sel)
                `WRITEBACK_PC4:     id_operand_a = WB1.pc + 4;
                default:            id_operand_a = WB1.result;
            endcase
        end else if (raw_rs1_wb2) begin
            case (WB2.wb_sel)
                `WRITEBACK_PC4:     id_operand_a = WB2.pc + 4;
                `WRITEBACK_DATA:    id_operand_a = mem_data_out;
                default:            id_operand_a = WB2.result;
            endcase
        end else begin
            case (id_op1_sel)
                `OP1_RS1:           id_operand_a = id_rd1;
                `OP1_PC:            id_operand_a = ID.pc;
            endcase
        end

        if (raw_rs2_ex) begin
            case (EX.wb_sel)
                `WRITEBACK_PC4:     id_operand_b = EX.pc + 4;
                default:            id_operand_b = ex_alu_result;
            endcase
        end else if (raw_rs2_mem) begin
            case (MEM.wb_sel)
                `WRITEBACK_PC4:     id_operand_b = MEM.pc + 4;
                default:            id_operand_b = MEM.alu_result;
            endcase
        end else if (raw_rs2_wb1) begin
            case (WB1.wb_sel)
                `WRITEBACK_PC4:     id_operand_b = WB1.pc + 4;
                default:            id_operand_b = WB1.result;
            endcase
        end else if (raw_rs2_wb2) begin
            case (WB2.wb_sel)
                `WRITEBACK_PC4:     id_operand_b = WB2.pc + 4;
                `WRITEBACK_DATA:    id_operand_b = mem_data_out;
                default:            id_operand_b = WB2.result;
            endcase
        end else begin
            case (id_op2_sel)
                `OP2_RS2:           id_operand_b = id_rd2;
                `OP2_IMM:           id_operand_b = id_imm;
            endcase
        end
    end

    //////////////////////////////////////////////////////////////////////
    //
    // INSTRUCTION FETCH (IF) - 3 cycles
    //
    //////////////////////////////////////////////////////////////////////

    logic     [31:0] PC_PIPELINE [1:0];

    always_ff @(posedge clk_in) begin
        if (rst_in || annul) begin
            PC_PIPELINE[0] <= 0;
            PC_PIPELINE[1] <= 0;
        end else if (!stall) begin
            PC_PIPELINE[0] <= PC;
            PC_PIPELINE[1] <= PC_PIPELINE[0];
        end
    end

    assign imem_addr_out = PC;

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            PC <= 0;
        end else if (cpu_step_in) begin
            if (annul) begin
                case (EX.pc_sel)
                    `PC_SEL_BRJMP:  PC <= EX.br_target;
                    `PC_SEL_ALU:    PC <= ex_alu_result;
                    default:        PC <= PC + 4;
                endcase
            end else begin
                PC <= (stall) ? PC_PIPELINE[1] : PC + 4;
            end
        end
    end

    //////////////////////////////////////////////////////////////////////
    //
    // INSTRUCTION DECODE (ID) - 1 cycle
    //
    //////////////////////////////////////////////////////////////////////

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            ID <= '0;
        end else if (cpu_step_in) begin
            if (annul) begin
                ID.pc <= `ZERO;
                ID.instr <= `NOP;
            end else if (stall) begin
                ID <= ID;
            end else begin
                ID.pc <= PC_PIPELINE[1];
                ID.instr <= imem_data_in;
            end
        end
    end

    //////////////////////////////////////////////////////////////////////
    //
    // EXECUTE (EX) - 1 cycle
    //
    //////////////////////////////////////////////////////////////////////

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            EX <= '0;
        end else if (cpu_step_in) begin
            if (annul || stall) begin
                EX.pc           <= `ZERO;
                EX.br_target    <= `ZERO;
                EX.imm          <= `ZERO;
                EX.rd           <= `X0;
                EX.a            <= `ZERO;
                EX.b            <= `ZERO;
                EX.br_func      <= `BR_FUNC_NONE;
                EX.alu_func     <= `ALU_FUNC_NONE;
                EX.pc_sel       <= `PC_SEL_NEXTPC;
                EX.wb_sel       <= `WRITEBACK_X;
                EX.werf         <= `OFF;
                EX.dmem_size    <= `MASK_NONE;
                EX.dmem_read_enable <= `OFF;
                EX.dmem_write_enable <= `OFF;
            end else begin
                EX.pc        <= ID.pc;
                EX.br_target <= id_imm + ID.pc;
                EX.imm       <= id_imm;
                EX.rd        <= id_rd;
                EX.a         <= id_operand_a;
                EX.b         <= id_operand_b;
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
    end

    //////////////////////////////////////////////////////////////////////
    //
    // MEMORY (MEM) - 1 cycle
    //
    //////////////////////////////////////////////////////////////////////

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            MEM <= '0;
        end else if (cpu_step_in) begin
            MEM.pc <= EX.pc;
            MEM.rd <= EX.rd;
            MEM.alu_result <= ex_alu_result;
            MEM.addr <= EX.imm + EX.a;
            MEM.wb_sel <= EX.wb_sel;
            MEM.werf <= EX.werf;
            MEM.dmem_size <= EX.dmem_size;
            MEM.dmem_read_enable <= EX.dmem_read_enable;
            MEM.dmem_write_enable <= EX.dmem_write_enable;
        end
    end

    //////////////////////////////////////////////////////////////////////
    //
    // WRITEBACK (WB) - 2 cycles
    //
    //////////////////////////////////////////////////////////////////////

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            WB1 <= '0;
            WB2 <= '0;
        end else if (cpu_step_in) begin
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
        .write_enable_in(WB2.werf),
        .reg_debug_in(reg_debug_in),
        .reg_debug_out(reg_debug_out)
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
        .step_in(cpu_step_in),
        .rst_in(rst_in),

        .cpu_addr_in(MEM.addr),
        .cpu_data_in(MEM.alu_result),
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