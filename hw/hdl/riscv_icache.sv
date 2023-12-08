`timescale 1ns / 1ps
`default_nettype none

module riscv_icache (
    input wire clk_in,
    input wire rst_in,
    input wire annul_in,
    input wire [31:0] pc_in,
    output logic [31:0] instruction_out,
    output logic cache_miss_out,
    input wire [31:0] imem_data_in,
    output logic [31:0] imem_addr_out
);
    parameter int SETS = 32;
    parameter int WAYS = 2;

    // addresses are 16-bits wide
    // 5 bit set index
    // 9 bit tag
    // 2 bit offset
    // TTTTTTTTTIIIIIXX
    // FEDCBA9876543210

    logic [31:0] cache [0:SETS-1][0:WAYS-1];
    logic [ 8:0] tags  [0:SETS-1][0:WAYS-1];
    logic        valid [0:SETS-1][0:WAYS-1];
    logic [31:0] lru;

    logic [ 4:0]    set_idx;
    logic           way_idx;
    logic [ 8:0]    tag;
    logic           cache_hit;
    logic           which_hit;
    logic [31:0]    instruction_data;

    enum { IDLE, WAIT, WAIT2 } state;

    assign cache_miss_out = !(cache_hit || (state == WAIT2));
    assign imem_addr_out = pc_in;
    assign instruction_out = (state == WAIT2) ? imem_data_in : instruction_data;

    // Cache reading logic
    always_comb begin
        set_idx = pc_in[6:2];
        tag = pc_in[15:7];

        // Check if current PC is available in way 0
        if (valid[set_idx][0] && tags[set_idx][0] == tag) begin
            cache_hit = 1'b1;
            instruction_data = cache[set_idx][0];
            which_hit = 1'b0;
        end else if (valid[set_idx][1] && tags[set_idx][1] == tag) begin
            cache_hit = 1'b1;
            instruction_data = cache[set_idx][0];
            which_hit = 1'b1;
        end else begin
            cache_hit = 1'b0;
            instruction_data = 32'h0;
        end
    end

    assign way_idx = lru[set_idx];

    // Cache writing logic
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            for (int i = 0; i < SETS; i = i + 1) begin
                lru[i] <= 0;
                for (int j = 0; j < WAYS; j = j + 1) begin
                    valid[i][j] <= 0;
                end
            end
            state <= IDLE;
        end else if (!cache_hit) begin
            // Update cache on a miss
            case (state)
                IDLE:   state <= (annul_in) ? IDLE : WAIT;
                WAIT:   state <= (annul_in) ? IDLE : WAIT2;
                WAIT2:  begin
                    valid[set_idx][way_idx] <= 1;
                    tags[set_idx][way_idx] <= tag;
                    cache[set_idx][way_idx] <= imem_data_in;
                    state <= IDLE;
                end
            endcase
        end else begin
            lru[set_idx] <= !which_hit;
        end
    end
endmodule
`default_nettype wire