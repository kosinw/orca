`timescale 1ns / 1ps
`default_nettype none

module ps2_rx(
    input wire clk_in,
    input wire rst_in,

    input wire ps2_clk_in,
    input wire ps2_data_in,

    output logic valid_out,
    output logic error_out,
    output logic [7:0] scancode_out
);
    logic ps2_clk_s, ps2_data_s;
    logic ps2_clk, ps2_data;
    logic ps2_clk_negedge, ps2_last_clk;

    logic [2:0] counter;
    logic [7:0] scancode_int;

    enum { IDLE, RECEIVE, PARITY, STOP } state;

    synchronizer clk_sync(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .us_in(ps2_clk_in),
        .s_out(ps2_clk_s)
    );

    synchronizer data_sync(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .us_in(ps2_data_in),
        .s_out(ps2_data_s)
    );

    debouncer clk_db(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .dirty_in(ps2_clk_s),
        .clean_out(ps2_clk)
    );

    debouncer data_db(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .dirty_in(ps2_data_s),
        .clean_out(ps2_data)
    );

    assign ps2_clk_negedge = ({ps2_clk,ps2_last_clk} == 2'b01);

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            valid_out <= 1'b0;
            error_out <= 1'b0;
            scancode_out <= 8'h0;
            counter <= 3'h0;
            scancode_int <= 8'h0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    valid_out <= 1'b0;
                    error_out <= 1'b0;
                    // start bit present
                    if (ps2_clk_negedge && !ps2_data) begin
                        counter <= 3'h0;
                        scancode_int <= 8'h0;
                        state <= RECEIVE;
                    end
                end
                RECEIVE: begin
                    if (ps2_clk_negedge) begin
                        scancode_int[counter] <= ps2_data;
                        counter <= counter + 1;
                        if (counter === 3'd7) begin
                            state <= PARITY;
                        end
                    end
                end
                PARITY: begin
                    if (ps2_clk_negedge) begin
                        // parity bit correct
                        if ((^scancode_int) ^ ps2_data) begin
                            state <= STOP;
                        end

                        // parity bit incorrect
                        else begin
                            valid_out <= 1'b0;
                            error_out <= 1'b1;
                            state <= IDLE;
                        end
                    end
                end
                STOP: begin
                    if (ps2_clk_negedge) begin
                        // stop bit present
                        if (ps2_data) begin
                            scancode_out <= scancode_int;
                            valid_out <= 1'b1;
                            error_out <= 1'b0;
                            state <= IDLE;
                        end
                        // stop bit not present
                        else begin
                            scancode_out <= 8'h0;
                            valid_out <= 1'b0;
                            error_out <= 1'b1;
                            state <= IDLE;
                        end
                    end
                end
            endcase

            ps2_last_clk <= ps2_clk;
        end
    end
endmodule