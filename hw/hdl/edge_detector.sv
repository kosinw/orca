module edge_detector(   input wire          clk_in,
                        input wire          level_in,
                        output logic        level_out
                    );

    logic prev_level_reg;

    logic [31:0] counter;

    initial counter <= 32'b0;
    initial prev_level_reg <= 1'b0;
    initial level_out <= 1'b0;

    always_ff @(posedge clk_in) begin
        if (counter == 0) begin
            if (({prev_level_reg, level_in}) === 1'b01) begin
                counter <= 1;
                level_out <= 1;
            end else begin
                level_out <= 0;
            end
            prev_level_reg <= level_in;
        end else begin
            level_out <= 0;
            counter <= (counter >= 32'd15_000_000) ? 0 : (counter + 1);
            prev_level_reg <= 1;
        end


    end
endmodule
