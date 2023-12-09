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

    input wire   [15:0] debug_in,
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
    //  5-stage pipeline with a 2-way set associative instruction cache
    //  and no data cache (don't have the time).
    //

    logic [31:0]            PC;
    InstructionDecodeState  ID;
    ExecuteState            EX;
    MemoryState             MEM;
    WritebackState          WB;

    // IF signals
    logic   [31:0] if_instruction;
    logic          if_cache_miss;

    // ID signals
    logic [31:0] id_instr;
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
    logic [4:0]  reg_debug_in;
    logic [31:0] reg_debug_out;

    // EX signals
    logic [31:0] ex_alu_result;
    logic [31:0] ex_next_pc;
    logic        ex_br_taken;

    // MEM signals
    logic [31:0] mem_data_out;
    logic        mem_cache_miss;
    logic        mem_new_request;

    // WB signals
    logic [31:0] wb_data;

    // control logic
    logic ltu_hazard_rs1;
    logic ltu_hazard_rs2;
    logic ltu_hazard;

    logic if_stall;
    logic id_stall;
    logic ex_stall;
    logic mem_stall;
    logic wb_stall;

    logic raw_rs1_ex;
    logic raw_rs2_ex;
    logic raw_rs1_mem;
    logic raw_rs2_mem;
    logic raw_rs1_wb;
    logic raw_rs2_wb;
    logic bypass;

    logic annul;

    // probes for testbenching
`ifndef TOPLEVEL
    logic [4:0]     DEBUG0_STALL;
    logic           DEBUG0_BYPASS;
    logic           DEBUG0_ANNUL;

    logic [31:0]    DEBUG1_IF_PC;

    logic [31:0]    DEBUG2_ID0_PC;
    logic [31:0]    DEBUG2_ID1_INSTR;
    logic [4:0]     DEBUG2_ID2_RS1;
    logic [4:0]     DEBUG2_ID3_RS2;
    logic [4:0]     DEBUG2_ID4_RD;
    logic [31:0]    DEBUG2_ID5_X1;
    logic [31:0]    DEBUG2_ID6_X2;
    logic [31:0]    DEBUG2_ID7_IMM;

    logic [31:0]    DEBUG3_EX0_PC;
    logic [31:0]    DEBUG3_EX1_A;
    logic [31:0]    DEBUG3_EX2_B;
    logic [31:0]    DEBUG3_EX3_RESULT;
    logic [3:0]     DEBUG3_EX4_ALU_FUNC;
    logic           DEBUG3_EX5_BRANCH_TAKEN;

    logic [31:0]    DEBUG4_MEM0_PC;
    logic [31:0]    DEBUG4_MEM1_ADDR;
    logic [31:0]    DEBUG4_MEM2_DATA;
    logic           DEBUG4_MEM3_READ_ENABLE;
    logic           DEBUG4_MEM4_WRITE_ENABLE;

    logic [31:0]    DEBUG5_WB0_PC;
    logic [4:0]     DEBUG5_WB1_RD;
    logic [31:0]    DEBUG5_WB2_RESULT;
    logic           DEBUG5_WB3_WERF;

    assign DEBUG0_STALL = {if_stall,id_stall,ex_stall,mem_stall,wb_stall};
    assign DEBUG0_BYPASS = bypass;
    assign DEBUG0_ANNUL = annul;

    assign DEBUG1_IF_PC = PC;

    assign DEBUG2_ID0_PC = ID.pc;
    assign DEBUG2_ID1_INSTR = ID.instr;
    assign DEBUG2_ID2_RS1 = id_rs1;
    assign DEBUG2_ID3_RS2 = id_rs2;
    assign DEBUG2_ID4_RD  = id_rd;
    assign DEBUG2_ID5_X1  = id_rd1;
    assign DEBUG2_ID6_X2  = id_rd2;
    assign DEBUG2_ID7_IMM = id_imm;

    assign DEBUG3_EX0_PC = EX.pc;
    assign DEBUG3_EX1_A   = EX.a;
    assign DEBUG3_EX2_B   = EX.b;
    assign DEBUG3_EX3_RESULT = ex_alu_result;
    assign DEBUG3_EX4_ALU_FUNC = EX.alu_func;
    assign DEBUG3_EX5_BRANCH_TAKEN = ex_br_taken;

    assign DEBUG4_MEM0_PC = MEM.pc;
    assign DEBUG4_MEM1_ADDR = MEM.addr;
    assign DEBUG4_MEM2_DATA = MEM.alu_result;
    assign DEBUG4_MEM3_READ_ENABLE = MEM.dmem_read_enable;
    assign DEBUG4_MEM4_WRITE_ENABLE = MEM.dmem_write_enable;

    assign DEBUG5_WB0_PC = WB.pc;
    assign DEBUG5_WB1_RD = WB.rd;
    assign DEBUG5_WB2_RESULT = wb_data;
    assign DEBUG5_WB3_WERF = WB.werf;
`endif // TOPLEVEL


    //////////////////////////////////////////////////////////////////////
    //
    // TOP LEVEL DEBUG
    //
    //////////////////////////////////////////////////////////////////////

    always_comb begin
        reg_debug_in = debug_in[14:11];
        case (debug_in[3:0])
            4'b0000:     debug_out = ID.pc;
            4'b0001:     debug_out = ID.instr;
            4'b0010:     debug_out = reg_debug_out;
            4'b0011:     debug_out = MEM.addr;
            4'b0100:     debug_out = MEM.alu_result;
            4'b0101:     debug_out = dmem_data_in;
            4'b0110:     debug_out = wb_data;
            4'b0111:     debug_out = WB.pc;
            default:     debug_out = 32'hDEADBEEF;
        endcase

        led_out[15] = if_stall;
        led_out[14] = id_stall;
        led_out[13] = ex_stall;
        led_out[12] = mem_stall;
        led_out[11] = wb_stall;

        led_out[ 0] = bypass;
        led_out[ 1] = annul;
        led_out[ 2] = WB.werf;
        led_out[ 3] = MEM.dmem_read_enable;
        led_out[ 4] = MEM.dmem_write_enable;
    end

    //////////////////////////////////////////////////////////////////////
    //
    // CONTROL LOGIC
    //
    //////////////////////////////////////////////////////////////////////

    assign annul = (EX.pc_sel === `PC_SEL_BRJMP && ex_br_taken) || (EX.pc_sel === `PC_SEL_ALU);

    // Load-to-use hazard is active when:
    //  - The incident register cannot be x0
    //  - The current instruction is actually using RS1/RS2
    //  - There is a load instruction in EX or MEM
    //  - Said load instruction has an RD equal to RS1/RS2
    //  - ENSURE THERE IS A BYPASS FROM WB

    assign ltu_hazard_rs1 = id_rs1 != 5'b0 && (id_op1_sel === `OP1_RS1) && ((EX.wb_sel === `WRITEBACK_DATA && EX.rd === id_rs1) || (MEM.wb_sel === `WRITEBACK_DATA && MEM.rd === id_rs1));
    assign ltu_hazard_rs2 = id_rs2 != 5'b0 && (id_op2_sel === `OP2_RS2) && ((EX.wb_sel === `WRITEBACK_DATA && EX.rd === id_rs2) || (MEM.wb_sel === `WRITEBACK_DATA && MEM.rd === id_rs2));

    assign ltu_hazard     = ltu_hazard_rs1 || ltu_hazard_rs2;

    assign if_stall     = ltu_hazard || if_cache_miss || mem_cache_miss;
    assign id_stall     = ltu_hazard || mem_cache_miss;
    assign ex_stall     = mem_cache_miss;
    assign mem_stall    = mem_cache_miss;
    assign wb_stall     = mem_cache_miss;

    // Read-after-write hazard is active when:
    //  - The incident register cannot be x0
    //  - The current instruction is actually using RS1/RS2
    //  - There is an instruction further in the pipeline which writebacks to register file (WERF)
    //  - Destination register of writeback instruction matches RS1 (or RS2)

    assign raw_rs1_ex  = id_rs1 != 5'b0 && (id_op1_sel === `OP1_RS1) && (EX.werf  && EX.rd  === id_rs1);
    assign raw_rs1_mem = id_rs1 != 5'b0 && (id_op1_sel === `OP1_RS1) && (MEM.werf && MEM.rd === id_rs1);
    assign raw_rs1_wb  = id_rs1 != 5'b0 && (id_op1_sel === `OP1_RS1) && (WB.werf  && WB.rd  === id_rs1);

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

    //////////////////////////////////////////////////////////////////////
    //
    // INSTRUCTION FETCH (IF)
    //
    //////////////////////////////////////////////////////////////////////

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            PC <= 0;
        end else if (cpu_step_in) begin
            if (annul) begin
                PC <= ex_next_pc;
            end else if (!if_stall) begin
                PC <= PC + 4;
            end
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
        end else if (cpu_step_in) begin
            if (annul) begin
                ID.pc <= `ZERO;
                ID.instr <= `NOP;
            end else if (id_stall) begin
                ID <= ID;
            end else if (if_stall) begin
                ID.pc <= `ZERO;
                ID.instr <= `NOP;
            end else begin
                ID.pc <= PC;
                ID.instr <= if_instruction;
            end
        end
    end

    //////////////////////////////////////////////////////////////////////
    //
    // EXECUTE (EX)
    //
    //////////////////////////////////////////////////////////////////////

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            EX <= '0;
        end else if (cpu_step_in) begin
            if (annul) begin
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
            end else if (ex_stall) begin
                EX <= EX;
            end else if (id_stall) begin
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

    assign ex_next_pc = (EX.pc_sel == `PC_SEL_BRJMP)    ? EX.br_target :
                        (EX.pc_sel == `PC_SEL_ALU)      ? ex_alu_result :
                        PC + 4;

    //////////////////////////////////////////////////////////////////////
    //
    // MEMORY (MEM)
    //
    //////////////////////////////////////////////////////////////////////

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            MEM <= '0;
            mem_new_request <= 0;
        end else if (cpu_step_in) begin
            if (!mem_stall) begin
                MEM.pc <= EX.pc;
                MEM.rd <= EX.rd;
                MEM.alu_result <= ex_alu_result;
                MEM.addr <= EX.imm + EX.a;
                MEM.wb_sel <= EX.wb_sel;
                MEM.werf <= EX.werf;
                MEM.dmem_size <= EX.dmem_size;
                MEM.dmem_read_enable <= EX.dmem_read_enable;
                MEM.dmem_write_enable <= EX.dmem_write_enable;
                mem_new_request <= 1;
            end else begin
                mem_new_request <= 0;
            end
        end
    end

    //////////////////////////////////////////////////////////////////////
    //
    // WRITEBACK (WB)
    //
    //////////////////////////////////////////////////////////////////////

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            WB <= '0;
        end else if (cpu_step_in) begin
            if (!wb_stall) begin
                WB.pc <= MEM.pc;
                WB.rd <= MEM.rd;
                WB.result <= MEM.alu_result;
                WB.data <= mem_data_out;
                WB.werf <= MEM.werf;
                WB.wb_sel <= MEM.wb_sel;
            end
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

    riscv_icache icache (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .annul_in(annul),
        .pc_in(PC),
        .instruction_out(if_instruction),
        .cache_miss_out(if_cache_miss),
        .imem_data_in(imem_data_in),
        .imem_addr_out(imem_addr_out)
    );

    riscv_decode decode_unit (
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
        .rd_in(WB.rd),
        .wd_in(wb_data),
        .write_enable_in(WB.werf),
        .reg_debug_in(reg_debug_in),
        .reg_debug_out(reg_debug_out)
    );

    riscv_alu alu_unit (
        .alu_func_in(EX.alu_func),
        .br_func_in(EX.br_func),
        .a_in(EX.a),
        .b_in(EX.b),
        .result_out(ex_alu_result),
        .branch_taken_out(ex_br_taken)
    );

    riscv_dcache dcache (
        .clk_in(clk_in),
        .rst_in(rst_in),

        .cpu_addr_in(MEM.addr),
        .cpu_data_in(MEM.alu_result),
        .cpu_size_in(MEM.dmem_size),
        .cpu_read_enable_in(MEM.dmem_read_enable),
        .cpu_write_enable_in(MEM.dmem_write_enable),
        .cpu_data_out(mem_data_out),

        .new_request_in(mem_new_request),
        .cache_miss_out(mem_cache_miss),

        .mem_addr_out(dmem_addr_out),
        .mem_data_out(dmem_data_out),
        .mem_write_enable(dmem_write_enable_out),
        .mem_data_in(dmem_data_in)
    );
endmodule
`default_nettype wire