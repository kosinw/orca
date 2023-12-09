`timescale 1ns / 1ps
`default_nettype none

module ram_bridge_rx (
    input wire clk_in,

    input wire [7:0] data_in,
    input wire valid_in,

    output logic [31:0] addr_out,
    output logic [31:0] data_out,
    output logic valid_out,

    output logic halt_out,
    output logic reset_out,
    output logic start_out
);
    enum { IDLE, WRITE, RESET, HALT, START } state;
    logic [7:0] buffer [7:0];
    logic [3:0] byte_num;

    initial addr_out = 0;
    initial data_out = 0;
    initial valid_out = 0;

    assign halt_out = (state == HALT);
    assign start_out = (state == START);
    assign reset_out = (state == RESET);

    always_ff @(posedge clk_in) begin
        if (state == IDLE) begin
            addr_out <= 0;
            data_out <= 0;
            valid_out <= 0;
            byte_num <= 0;
            if (valid_in) begin
                if      (data_in == "W")     state <= WRITE;
                else if (data_in == "R")     state <= RESET;
                else if (data_in == "H")     state <= HALT;
                else if (data_in == "S")     state <= START;
            end
        end else if (valid_in) begin
            buffer[byte_num] <= data_in;
            byte_num <= byte_num + 1;

            if (byte_num == 8) begin
                state <= IDLE;

                addr_out <= {buffer[3],buffer[2],buffer[1],buffer[0]};
                data_out <= {buffer[7],buffer[6],buffer[5],buffer[4]};
                valid_out <= 1'b1;
                byte_num <= 0;
            end else begin
                addr_out <= 0;
                data_out <= 0;
                valid_out <= 0;
            end
        end else begin
            if      (state == RESET)    state <= IDLE;
            else if (state == HALT)     state <= IDLE;
            else if (state == START)    state <= IDLE;
        end
    end
endmodule
`default_nettype wire
