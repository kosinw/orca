`timescale 1ns / 1ps
`default_nettype none
`include "riscv_types.sv"

module riscv_core(
    input wire              clk_in,
    input wire              rst_in,
    input wire              hlt_in,
    input wire              step_in,
    input  wire   [31:0]    inst_mem_in,
    output logic  [31:0]    inst_mem_out,
    output MemoryRequest    data_mem_out,
    input  MemoryResponse   data_mem_in
);
    InstructionFetchState       ifr, ifn; // instruction fetch register, next
    InstructionDecodeState      idr, idn; // instruction decode register, next

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

    assign inst_mem_out = ifr.pc;


    ///////////////////////////////////////////////////////////
    //
    //  INSTRUCTION DECODE (ID)
    //
    ///////////////////////////////////////////////////////////

    DecodeOut   id_dec_out;

    always_comb begin
        idn = idr;

        if (!halt) begin
            idn.instr = inst_mem_in;
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