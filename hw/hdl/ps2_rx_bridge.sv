`timescale 1ns / 1ps
`default_nettype none

module ps2_rx_bridge (
    input wire clk_in,
    input wire rst_in,
    input wire [7:0] scancode_in,
    input wire valid_in,
    input wire error_in,
    output logic [7:0] scancode_out,
    output logic valid_out
);
    enum { HOLDING, IDLE } state;

    assign scancode_out = scancode_in;
    assign valid_out = !error_in && (state == HOLDING) && valid_in;

    always_ff @(posedge clk_in) begin
        if (rst_in || error_in) begin
            state <= IDLE;
        end else if (valid_in) begin
            case (state)
                IDLE: begin
                    if (scancode_in == 8'hF0) begin
                        state <= HOLDING;
                    end
                end
                HOLDING: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
`default_nettype wire
