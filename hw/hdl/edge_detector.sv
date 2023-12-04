module edge_detector(   input wire          clk_in,
                        input wire          level_in,
                        output logic        level_out
                    );

    logic prev_level_reg;

    initial prev_level_reg <= 1'b0;
    initial level_out <= 1'b0;

    always_ff @(posedge clk_in) begin
        if (({prev_level_reg, level_in}) === 1'b01) begin
            level_out <= 1;
        end else begin
            level_out <= 0;
        end

        prev_level_reg <= level_in;
    end
endmodule
