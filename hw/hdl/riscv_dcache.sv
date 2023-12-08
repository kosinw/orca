`timescale 1ns / 1ps
`default_nettype none

`include "hdl/riscv_constants.sv"

module riscv_dcache (
    input wire clk_in,
    input wire rst_in,

    input wire [31:0] cpu_addr_in,
    input wire [31:0] cpu_data_in,
    input wire [2:0] cpu_size_in,
    input wire cpu_write_enable_in,
    input wire cpu_read_enable_in,
    output logic [31:0] cpu_data_out,
    output logic cache_miss_out,

    output logic [31:0] mem_addr_out,
    output logic [31:0] mem_data_out,
    output logic [3:0] mem_write_enable,
    input wire [31:0] mem_data_in
);
    enum { IDLE, WAIT, WAIT2 } state;
    logic [31:0] addr;
    logic valid;
    logic cache_hit;

    assign mem_addr_out = cpu_addr_in;
    assign cache_miss_out = !((state == WAIT2) || cache_hit);
    assign cache_hit = (addr == cpu_addr_in && valid);

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            addr <= 0;
            valid <= 0;
        end else if (!cache_hit) begin
            case (state)
                IDLE:       state <= WAIT;
                WAIT:       state <= WAIT2;
                WAIT2:      begin
                    state <= IDLE;
                    valid <= 1;
                    addr <= cpu_addr_in;
                end
            endcase
        end
    end


    always_comb begin
        if (cpu_write_enable_in) begin
            case (cpu_size_in)
                `MASK_B: begin
                    case (cpu_addr_in[1:0])
                        2'b00: begin
                            mem_data_out = {24'b0, cpu_data_in[7:0]};
                            mem_write_enable = 4'b0001;
                        end
                        2'b01: begin
                            mem_data_out = {16'b0, cpu_data_in[7:0], 8'b0};
                            mem_write_enable = 4'b0010;
                        end
                        2'b10: begin
                            mem_data_out = {8'b0, cpu_data_in[7:0], 16'b0};
                            mem_write_enable = 4'b0100;
                        end
                        2'b11: begin
                            mem_data_out = {cpu_data_in[7:0], 24'b0};
                            mem_write_enable = 4'b1000;
                        end
                    endcase
                end
                `MASK_H: begin
                    case (cpu_addr_in[1:0])
                        2'b00: begin
                            mem_data_out = {16'b0, cpu_data_in[15:0]};
                            mem_write_enable = 4'b0011;
                        end
                        2'b10: begin
                            mem_data_out = {cpu_data_in[15:0], 16'b0};
                            mem_write_enable = 4'b1100;
                        end
                        default: begin
                            mem_data_out = cpu_data_in;
                            mem_write_enable = 4'b0000; // NOTE(kosinw): Cannot do unaligned memory writes
                        end
                    endcase
                end
                `MASK_W: begin
                    case (cpu_addr_in[1:0])
                        2'b00: begin
                            mem_data_out = cpu_data_in;
                            mem_write_enable = 4'b1111;
                        end
                        default: begin
                            mem_data_out = cpu_data_in;
                            mem_write_enable = 4'b0000;
                        end
                    endcase
                end
                default: begin
                    mem_data_out = 32'h0;
                    mem_write_enable = 4'b0000;
                end
            endcase
        end else begin
            mem_data_out = 32'h0;
            mem_write_enable = 4'b0000;
        end
    end

    always_comb begin
        if (cpu_read_enable_in) begin
            case (cpu_size_in)
                `MASK_B: begin
                    case (cpu_addr_in[1:0])
                        2'b00:      cpu_data_out = {{24{mem_data_in[7]}},mem_data_in[7:0]};
                        2'b01:      cpu_data_out = {{24{mem_data_in[15]}},mem_data_in[15:8]};
                        2'b10:      cpu_data_out = {{24{mem_data_in[23]}},mem_data_in[23:16]};
                        2'b11:      cpu_data_out = {{24{mem_data_in[31]}},mem_data_in[31:24]};
                    endcase
                end
                `MASK_BU: begin
                    case (cpu_addr_in[1:0])
                        2'b00:      cpu_data_out = {24'b0,mem_data_in[7:0]};
                        2'b01:      cpu_data_out = {24'b0,mem_data_in[15:8]};
                        2'b10:      cpu_data_out = {24'b0,mem_data_in[23:16]};
                        2'b11:      cpu_data_out = {24'b0,mem_data_in[31:24]};
                    endcase
                end
                `MASK_H: begin
                    case (cpu_addr_in[1:0])
                        2'b00:      cpu_data_out = {{16{mem_data_in[15]}},mem_data_in[15:0]};
                        2'b10:      cpu_data_out = {{16{mem_data_in[31]}},mem_data_in[31:16]};
                        default:    cpu_data_out = 32'h0;
                    endcase
                end
                `MASK_HU: begin
                    case (cpu_addr_in[1:0])
                        2'b00:      cpu_data_out = {16'b0,mem_data_in[15:0]};
                        2'b10:      cpu_data_out = {16'b0,mem_data_in[31:16]};
                        default:    cpu_data_out = 32'h0;
                    endcase
                end
                `MASK_W: begin
                    case (cpu_addr_in[1:0])
                        2'b00:      cpu_data_out = mem_data_in;
                        default:    cpu_data_out = 32'h0;
                    endcase
                end
                default:    cpu_data_out = 32'h0;
            endcase
        end else begin
            cpu_data_out = 32'h0;
        end
    end
endmodule