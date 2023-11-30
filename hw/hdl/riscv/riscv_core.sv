`timescale 1ns / 1ps
`default_nettype none
`include "riscv_types.sv"

module riscv_core
(
    input wire              clk_in,
    input wire              rst_in,

    input wire              hlt_in,
    input wire              step_in,

    input  wire   [31:0]    inst_data_in,
    output logic  [31:0]    inst_addr_out,

    output MemoryRequest    data_mem_in,
    input  MemoryResponse   data_mem_out
);
    InstructionFetchState       ifr, ifn; // instruction fetch register, next
    InstructionDecodeState      idr, idn; // instruction decode register, next
    ExecuteState                exr, exn; // execute register, next

    logic halt;
    assign halt = hlt_in || (hlt_in && !step_in);

    ///////////////////////////////////////////////////////////
    //
    //  INSTRUCTION FETCH (IF)
    //
    ///////////////////////////////////////////////////////////

    always_comb begin
        ifn = ifr;

        if (!halt) begin
            // TODO(kosinw): Comeback and implement controlpath + branches
            ifn.pc = ifn.pc + 4;
        end
    end

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            ifr <= '0;
        end else begin
            ifr <= ifn;
        end
    end

    assign inst_addr_out = ifr.pc;


    ///////////////////////////////////////////////////////////
    //
    //  INSTRUCTION DECODE (ID)
    //
    ///////////////////////////////////////////////////////////

    always_comb begin
        idn = idr;

        if (!halt) begin
            idn.instr = inst_data_in;
            idn.pc = ifr.pc;
        end
    end

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            idr <= '0;
        end else begin
            idr <= idn;
        end
    end

    ///////////////////////////////////////////////////////////
    //
    //  EXECUTE (EX)
    //
    ///////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////
    //
    //  MEMORY (MEM)
    //
    ///////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////
    //
    //  WRITEBACK (WB)
    //
    ///////////////////////////////////////////////////////////

endmodule