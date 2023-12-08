`timescale 1ns / 1ps
`default_nettype none

`include "hdl/riscv_constants.sv"

module riscv_memory_iface(
    input wire clk_in,
    input wire rst_in,
    input wire step_in,

    input wire [31:0] cpu_addr_in,
    input wire [31:0] cpu_data_in,
    input wire [2:0] cpu_size_in,
    input wire cpu_write_enable_in,
    input wire cpu_read_enable_in,
    output logic [31:0] cpu_data_out,
    output logic cpu_data_ready_out,

    output logic [31:0] mem_addr_out,
    output logic [31:0] mem_data_out,
    output logic [3:0] mem_write_enable,
    input wire [31:0] mem_data_in
);
    logic [2:0] cpu_size_read;
    logic cpu_enable_read;
    logic [31:0] cpu_read_addr;
    enum { READY, WAIT, FINISH } state;

    // pipeline#(
    //     .PIPELINE_STAGES(2),
    //     .PIPELINE_WIDTH(36)
    // ) read_ctrl_pipeline (
    //     .clk_in(clk_in),
    //     .rst_in(rst_in),
    //     .signal_in({cpu_addr_in,cpu_size_in,cpu_read_enable_in}),
    //     .signal_out({cpu_read_addr,cpu_size_read,cpu_enable_read})
    // );

    assign mem_addr_out = cpu_addr_in;
    assign cpu_data_ready_out = (state == FINISH) || !cpu_read_enable_in;

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            cpu_size_read <= 0;
            cpu_read_addr <= 0;
            cpu_enable_read <= 0;
            state <= READY;
        end else if (step_in) begin
            if (cpu_read_enable_in && state == READY) begin
                cpu_size_read <= cpu_size_in;
                cpu_enable_read <= cpu_read_enable_in;
                cpu_read_addr <= cpu_addr_in;
                state <= WAIT;
            end else if (state == READY) begin
                cpu_size_read <= 0;
                cpu_enable_read <= 0;
                cpu_read_addr <= 0;
                state <= READY;
            end else if (state == WAIT) begin
                state <= FINISH;
            end else if (state == FINISH) begin
                state <= READY;
            end
        end
    end


    always_comb begin
        if (cpu_write_enable_in) begin
            // mem_data_out = cpu_data_in;
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
        if (cpu_enable_read) begin
            case (cpu_size_read)
                `MASK_B: begin
                    case (cpu_read_addr[1:0])
                        2'b00:      cpu_data_out = {{24{mem_data_in[7]}},mem_data_in[7:0]};
                        2'b01:      cpu_data_out = {{24{mem_data_in[15]}},mem_data_in[15:8]};
                        2'b10:      cpu_data_out = {{24{mem_data_in[23]}},mem_data_in[23:16]};
                        2'b11:      cpu_data_out = {{24{mem_data_in[31]}},mem_data_in[31:24]};
                    endcase
                end
                `MASK_BU: begin
                    case (cpu_read_addr[1:0])
                        2'b00:      cpu_data_out = {24'b0,mem_data_in[7:0]};
                        2'b01:      cpu_data_out = {24'b0,mem_data_in[15:8]};
                        2'b10:      cpu_data_out = {24'b0,mem_data_in[23:16]};
                        2'b11:      cpu_data_out = {24'b0,mem_data_in[31:24]};
                    endcase
                end
                `MASK_H: begin
                    case (cpu_read_addr[1:0])
                        2'b00:      cpu_data_out = {{16{mem_data_in[15]}},mem_data_in[15:0]};
                        2'b10:      cpu_data_out = {{16{mem_data_in[31]}},mem_data_in[31:16]};
                        default:    cpu_data_out = 32'h0;
                    endcase
                end
                `MASK_HU: begin
                    case (cpu_read_addr[1:0])
                        2'b00:      cpu_data_out = {16'b0,mem_data_in[15:0]};
                        2'b10:      cpu_data_out = {16'b0,mem_data_in[31:16]};
                        default:    cpu_data_out = 32'h0;
                    endcase
                end
                `MASK_W: begin
                    case (cpu_read_addr[1:0])
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