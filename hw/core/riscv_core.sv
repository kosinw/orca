`timescale 1ns / 1ps
`default_nettype none
`include "riscv_defs.sv"

module riscv_core (
  input wire clk_100mhz,
  input wire rst_in,
  input wire [31:0] inst_in,
  input wire [31:0] ram_data_in,
  output logic [13:0] pc_out            // 16_000 entries for Program ROM
  output logic [31:0] mem_addr_out,
  output logic [31:0] ram_data_out,
  output logic mem_we_out,
);
  
  logic [13:0] temp_pc;
  logic [13:0] temp_next_pc;
  logic [4:0] rd, ra, rb;
  logic [31:0] inst_imm, ra_val, rb_val;
  logic [6:0] inst_op;
  logic [31:0] temp_data;
  logic [31:0] ram_base_addr;
  logic reg_we;

  enum { ROM_FETCH_1, ROM_FETCH_2 } rom_fetch_state;
  enum { IDLE, RAM_FETCH_1, RAM_FETCH_2 } ram_fetch_state;
  enum { IF, ID, EX, MEM, WB } stage;

  assign pc_out = temp_pc;

  always_ff @(posedge clk_100mhz) begin : core
    if (rst_in) begin
      pc_out <= 0;
      stage <= IF;
      rom_fetch_state <= ROM_FETCH_1;
      ram_fetch_state <= IDLE;
      ram_base_addr <= 15'd16000;
    end else begin
      case (stage)
        IF: begin
          case (rom_fetch_state)
            ROM_FETCH_1: begin
              rom_fetch_state <= ROM_FETCH_2;
            end
            ROM_FETCH_2: begin
              rom_fetch_state <= ROM_FETCH_1;
              stage <= ID;
            end
          endcase
        end
        ID: begin
          stage <= EX;
        end
        EX: begin
          stage <= MEM;
        end
        MEM: begin
          case (ram_fetch_state)
            IDLE: begin
              case (inst_op)
                `LB, `LH, `LW, `LBU, `LHU: begin
                  mem_we_out <= 1'b0;
                  mem_addr_out <= ram_base_addr + temp_data;
                end
                `SB: begin
                  mem_we_out <= 1'b1;
                  mem_addr_out <= ram_base_addr + temp_data;
                  ram_data_out <= rb[7:0];
                end
                `SH: begin
                  mem_we_out <= 1'b1;
                  mem_addr_out <= ram_base_addr + temp_data;
                  ram_data_out <= rb[15:0];
                end
                `SW: begin
                  mem_we_out <= 1'b1;
                  mem_addr_out <= ram_base_addr + temp_data;
                  ram_data_out <= rb[31:0];
                end
              endcase
              ram_fetch_state <= RAM_FETCH_1;
            end

            RAM_FETCH_1: begin
              ram_fetch_state <= RAM_FETCH_2;
            end
            
            RAM_FETCH_2: begin
              case (inst_op)
                `LB: begin
                  temp_data <= ram_data_in[7:0];
                end
                `LH: begin
                  temp_data <= ram_data_in[15:0];
                end
                `LW: begin
                  temp_data <= ram_data_in[31:0];
                end
                `LBU: begin
                  temp_data <= ram_data_in[7:0];
                end
                `LHU: begin
                  temp_data <= ram_data_in[15:0];
                end
              endcase
              ram_fetch_state <= IDLE;
              stage <= WB;
            end 
          endcase
        end
        WB: begin
          case (inst_op)
            `ADD, `SUB, `XOR, `OR, `AND, `SLL, `SRL, `SRA, `SLT, `SLTU, `ADDI, `XORI, `ORI, `ANDI, `SLLI, `SRLI, `SRAI, `SLTI, `SLTIU, `LB, `LH, `LW, `LBU, `LHU, `JAL, `JALR, `LUI, `AUIPC, `MUL, `DIV: begin
              reg_we <= 1'b1;
            end
            temp_pc <= temp_next_pc;
          endcase
        end
      endcase
    end
  end

  riscv_decode riscv_decoder (
    .inst_in(inst_in),
    .rd_out(rd),
    .rs1_out(ra),
    .rs2_out(rb),
    .imm_out(inst_imm),
    .op_out(inst_op)
  );

  riscv_execute riscv_execute (
    .rs1_val_in(ra_val),
    .rs2_val_in(rb_val),
    .pc_in(temp_pc),
    .op_in(inst_op),
    .imm_in(inst_imm),
    .next_pc_out(temp_next_pc),
    .data_out(temp_data)
  );

  riscv_registers riscv_registers (
    .clk_in(clk_100mhz),
    .rst_in(rst_in),
    .rd_in(rd),
    .rd_val_in(temp_data),
    .we_in(reg_we),
    .ra_in(ra),
    .rb_in(rb),
    .ra_val_out(ra_val),
    .rb_val_out(rb_val),
  );

endmodule