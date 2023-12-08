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

    input wire [15:0] debug_in,
    output logic [31:0] debug_out,
    output logic [15:0] led_out
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
        logic   [31:0]  data;
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
    WritebackState          WB;

    // ID stage combinational signals
    logic       if_ready;
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
    logic        ex_br_taken;

    // MEM stage combinational signals
    logic [31:0] mem_data_out;
    logic        mem_ready;

    // WB stage combinational signals
    logic [31:0] wb_data;

    // Hazard management combinational signals
    logic ltu_stall_rs1;
    logic ltu_stall_rs2;

    logic raw_rs1_ex;
    logic raw_rs2_ex;
    logic raw_rs1_mem;
    logic raw_rs2_mem;
    logic raw_rs1_wb;
    logic raw_rs2_wb;
    logic bypass;

    logic stall;

    logic annul;
    logic last_annul;
    logic last_last_annul;

    // probes for testbenching
`ifndef TOPLEVEL
    logic           DEBUG0_STALL;
    logic           DEBUG0_BYPASS;
    logic           DEBUG0_ANNUL;
    logic           DEBUG0_MEM_READY;

    logic [31:0]    DEBUG1_IF_PC;

    logic [31:0]    DEBUG2_ID1_PC;
    logic [31:0]    DEBUG2_ID2_INSTR;
    logic [4:0]     DEBUG2_ID3_RS1;
    logic [4:0]     DEBUG2_ID4_RS2;
    logic [4:0]     DEBUG2_ID5_RD;
    logic [31:0]    DEBUG2_ID6_X1;
    logic [31:0]    DEBUG2_ID7_X2;
    logic [31:0]    DEBUG2_ID8_IMM;

    logic [31:0]    DEBUG3_EX1_A;
    logic [31:0]    DEBUG3_EX2_B;
    logic [31:0]    DEBUG3_EX3_RESULT;
    logic [3:0]     DEBUG3_EX4_ALU_FUNC;
    logic           DEBUG3_EX5_BRANCH_TAKEN;

    logic [31:0]    DEBUG4_MEM1_ADDR;
    logic [31:0]    DEBUG4_MEM2_DATA;
    logic           DEBUG4_MEM3_READ_ENABLE;
    logic           DEBUG4_MEM4_WRITE_ENABLE;

    logic [31:0]    DEBUG5_WB1_DATA;
    logic [4:0]     DEBUG5_WB2_RD;
    logic [31:0]    DEBUG5_WB3_RESULT;
    logic [31:0]    DEBUG5_WB4_PC;
    logic           DEBUG5_WB5_WERF;

    assign DEBUG0_STALL = stall;
    assign DEBUG0_BYPASS = bypass;
    assign DEBUG0_ANNUL = annul || last_annul || last_last_annul;
    assign DEBUG0_MEM_READY = mem_ready;

    assign DEBUG1_IF_PC = PC;

    assign DEBUG2_ID1_PC = ID.pc;
    assign DEBUG2_ID2_INSTR = ID.instr;
    assign DEBUG2_ID3_RS1 = id_rs1;
    assign DEBUG2_ID4_RS2 = id_rs2;
    assign DEBUG2_ID5_RD  = id_rd;
    assign DEBUG2_ID6_X1  = id_rd1;
    assign DEBUG2_ID7_X2  = id_rd2;
    assign DEBUG2_ID8_IMM = id_imm;

    assign DEBUG3_EX1_A   = EX.a;
    assign DEBUG3_EX2_B   = EX.b;
    assign DEBUG3_EX3_RESULT = ex_alu_result;
    assign DEBUG3_EX4_ALU_FUNC = EX.alu_func;
    assign DEBUG3_EX5_BRANCH_TAKEN = ex_br_taken;

    assign DEBUG4_MEM1_ADDR = MEM.addr;
    assign DEBUG4_MEM2_DATA = MEM.alu_result;
    assign DEBUG4_MEM3_READ_ENABLE = MEM.dmem_read_enable;
    assign DEBUG4_MEM4_WRITE_ENABLE = MEM.dmem_write_enable;

    assign DEBUG5_WB1_DATA = WB.data;
    assign DEBUG5_WB2_RD = WB.rd;
    assign DEBUG5_WB3_RESULT = WB.result;
    assign DEBUG5_WB4_PC = WB.pc;
    assign DEBUG5_WB5_WERF = WB.werf;
`endif // TOPLEVEL


    //////////////////////////////////////////////////////////////////////
    //
    // TOP LEVEL DEBUG
    //
    //////////////////////////////////////////////////////////////////////

    always_comb begin
        reg_debug_in = debug_in[6:3];
        case (debug_in[2:0])
            3'b000:     debug_out = ID.pc;
            3'b001:     debug_out = ID.instr;
            3'b010:     debug_out = reg_debug_out;
            3'b011:     debug_out = MEM.addr;
            3'b100:     debug_out = MEM.alu_result;
            3'b101:     debug_out = dmem_data_in;
            3'b110:     debug_out = wb_data;
            3'b111:     debug_out = WB.pc;
        endcase

        led_out[15] = stall;
        led_out[14] = bypass;
        led_out[13] = annul || last_annul || last_last_annul;
        led_out[12] = WB.werf;
        led_out[11] = MEM.dmem_read_enable;
        led_out[10] = MEM.dmem_write_enable;
        led_out[9]  = cpu_step_in;
        led_out[8]  = mem_ready;
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
    //  - There is a load instruction in EX or MEM
    //  - Said load instruction has an RD equal to RS1/RS2
    //  - ENSURE THERE IS A BYPASS FROM WB

    assign ltu_stall_rs1 = id_rs1 != 5'b0 && (id_op1_sel === `OP1_RS1) &&
                           ((EX.wb_sel === `WRITEBACK_DATA && EX.rd === id_rs1) ||
                            (MEM.wb_sel === `WRITEBACK_DATA && MEM.rd === id_rs1));

    assign ltu_stall_rs2 = id_rs2 != 5'b0 && (id_op2_sel === `OP2_RS2) &&
                        ((EX.wb_sel === `WRITEBACK_DATA && EX.rd === id_rs2) ||
                        (MEM.wb_sel === `WRITEBACK_DATA && MEM.rd === id_rs2));

    assign stall = ltu_stall_rs1 || ltu_stall_rs2;

    // Read-after-write hazard is active when:
    //  - The incident register cannot be x0
    //  - The current instruction is actually using RS1/RS2
    //  - There is an instruction further in the pipeline which writebacks to register file (WERF)
    //  - Destination register of writeback instruction matches RS1 (or RS2)

    assign raw_rs1_ex  = id_rs1 != 5'b0 && (id_op1_sel === `OP1_RS1) && (EX.werf  && EX.rd  === id_rs1);
    assign raw_rs1_mem = id_rs1 != 5'b0 && (id_op1_sel === `OP1_RS1) && (MEM.werf && MEM.rd === id_rs1);
    assign raw_rs1_wb  = id_rs1 != 5'b0 && (id_op1_sel === `OP1_RS1) && (WB.werf  && WB.rd  === id_rs1);

    // NOTE(kosinw): Edge case where stores use RS2 but not in operator select
    assign raw_rs2_ex  = id_rs2 != 5'b0 && (id_op2_sel === `OP2_RS2) && (EX.werf  && EX.rd  === id_rs2);
    assign raw_rs2_mem = id_rs2 != 5'b0 && (id_op2_sel === `OP2_RS2) && (MEM.werf && MEM.rd === id_rs2);
    assign raw_rs2_wb  = id_rs2 != 5'b0 && (id_op2_sel === `OP2_RS2) && (WB.werf  && WB.rd  === id_rs2);

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
        end else if (raw_rs1_wb) begin
            case (WB.wb_sel)
                `WRITEBACK_PC4:     id_operand_a = WB.pc + 4;
                `WRITEBACK_DATA:    id_operand_a = WB.data;
                default:            id_operand_a = WB.result;
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
        end else if (raw_rs2_wb) begin
            case (WB.wb_sel)
                `WRITEBACK_PC4:     id_operand_b = WB.pc + 4;
                `WRITEBACK_DATA:    id_operand_b = WB.data;
                default:            id_operand_b = WB.result;
            endcase
        end else begin
            case (id_op2_sel)
                `OP2_RS2:           id_operand_b = id_rd2;
                `OP2_IMM:           id_operand_b = id_imm;
            endcase
        end
    end

    assign bypass = (raw_rs1_ex || raw_rs1_mem || raw_rs1_wb) ||
                    (raw_rs2_ex || raw_rs2_mem || raw_rs2_wb);

    always_ff @(posedge clk_in) begin
        last_annul <= annul;
        last_last_annul <= last_annul;
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
        end else if (cpu_step_in && mem_ready) begin
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
        end else if (cpu_step_in && mem_ready) begin
            if (annul || last_annul || last_last_annul) begin
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
        end else if (cpu_step_in && mem_ready) begin
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
    // MEMORY (MEM) - >3 cycles
    //
    //////////////////////////////////////////////////////////////////////

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            MEM <= '0;
        end else if (cpu_step_in && mem_ready) begin
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
    // WRITEBACK (WB) - 1 cycle
    //
    //////////////////////////////////////////////////////////////////////

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            WB <= '0;
        end else if (cpu_step_in && mem_ready) begin
            WB.pc <= MEM.pc;
            WB.rd <= MEM.rd;
            WB.result <= MEM.alu_result;
            WB.data <= mem_data_out;
            WB.werf <= MEM.werf;
            WB.wb_sel <= MEM.wb_sel;
        end
    end

    always_comb begin
        case (WB.wb_sel)
            `WRITEBACK_ALU:     wb_data = WB.result;
            `WRITEBACK_PC4:     wb_data = WB.pc + 4;
            `WRITEBACK_DATA:    wb_data = WB.data;
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
        .step_in(cpu_step_in),
        .ra_in(id_rs1),
        .rd1_out(id_rd1),
        .rb_in(id_rs2),
        .rd2_out(id_rd2),
        .rd_in(WB.rd),
        .wd_in(wb_data),
        .write_enable_in(WB.werf),
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
        .rst_in(rst_in),
        .step_in(cpu_step_in),

        .cpu_addr_in(MEM.addr),
        .cpu_data_in(MEM.alu_result),
        .cpu_size_in(MEM.dmem_size),
        .cpu_read_enable_in(MEM.dmem_read_enable),
        .cpu_write_enable_in(MEM.dmem_write_enable),
        .cpu_data_out(mem_data_out),
        .cpu_data_ready_out(mem_ready),

        .mem_addr_out(dmem_addr_out),
        .mem_data_out(dmem_data_out),
        .mem_write_enable(dmem_write_enable_out),
        .mem_data_in(dmem_data_in)
    );
endmodule