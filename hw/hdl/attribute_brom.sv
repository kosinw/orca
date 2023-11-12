`timescale 1ns / 1ps
`default_nettype none

module attribute_brom(
    input wire clk_hdmi_in,
    input wire rst_in,
    input wire pixel_in,
    input wire valid_in,
    input wire [7:0] attribute_in,
    input wire [5:0] frame_count_in,
    output logic [7:0] red_out,
    output logic [7:0] green_out,
    output logic [7:0] blue_out
);
    logic [3:0] fg_color_req, bg_color_req;
    logic [7:0] fg_red, fg_green, fg_blue, bg_red, bg_green, bg_blue;
    logic valid, pixel, blink;

    always_comb begin
        case ({valid,pixel,blink})
            3'b0??: begin red_out = 0; green_out = 0; blue_out = 0; end
            3'b110: begin red_out = fg_red; green_out = fg_green; blue_out = fg_blue; end
            3'b111: begin red_out = bg_red; green_out = bg_green; blue_out = bg_blue; end
            3'b100: begin red_out = bg_red; green_out = bg_green; blue_out = bg_blue; end
            3'b101: begin red_out = fg_red; green_out = fg_green; blue_out = fg_blue; end
        endcase
    end

    always_ff @(posedge clk_hdmi_in) begin
        if (rst_in) begin
            valid <= 0;
            pixel <= 0;
            blink <= 0;
        end else begin
            valid <= valid_in;
            pixel <= pixel_in;
            blink <= (frame_count_in < 6'd30) & attribute_in[7];
        end
    end

    palette_lut fg_lut (
        .clk_in(clk_hdmi_in),
        .entry_in(attribute_in[3:0]),
        .red_out(fg_red),
        .green_out(fg_green),
        .blue_out(fg_blue)
    );

    palette_lut bg_lut (
        .clk_in(clk_hdmi_in),
        .entry_in({1'b0, attribute_in[6:4]}),
        .red_out(bg_red),
        .green_out(bg_green),
        .blue_out(bg_blue)
    );
endmodule

module palette_lut(
    input wire clk_in,
    input wire [3:0] entry_in,
    output logic [7:0] red_out,
    output logic [7:0] green_out,
    output logic [7:0] blue_out
);
    always_ff @(posedge clk_in) begin
        case (entry_in)
            4'h0: begin red_out <= 8'h00; green_out <= 8'h00; blue_out <= 8'h00; end
            4'h1: begin red_out <= 8'h80; green_out <= 8'h00; blue_out <= 8'h00; end
            4'h2: begin red_out <= 8'h00; green_out <= 8'h80; blue_out <= 8'h00; end
            4'h3: begin red_out <= 8'h80; green_out <= 8'h80; blue_out <= 8'h00; end
            4'h4: begin red_out <= 8'h00; green_out <= 8'h00; blue_out <= 8'h80; end
            4'h5: begin red_out <= 8'h80; green_out <= 8'h00; blue_out <= 8'h80; end
            4'h6: begin red_out <= 8'h00; green_out <= 8'h80; blue_out <= 8'h80; end
            4'h7: begin red_out <= 8'hc0; green_out <= 8'hc0; blue_out <= 8'hc0; end
            4'h8: begin red_out <= 8'h80; green_out <= 8'h80; blue_out <= 8'h80; end
            4'h9: begin red_out <= 8'hff; green_out <= 8'h00; blue_out <= 8'h00; end
            4'ha: begin red_out <= 8'h00; green_out <= 8'hff; blue_out <= 8'h00; end
            4'hb: begin red_out <= 8'hff; green_out <= 8'hff; blue_out <= 8'h00; end
            4'hc: begin red_out <= 8'h00; green_out <= 8'h00; blue_out <= 8'hff; end
            4'hd: begin red_out <= 8'hff; green_out <= 8'h00; blue_out <= 8'hff; end
            4'he: begin red_out <= 8'h00; green_out <= 8'hff; blue_out <= 8'hff; end
            4'hf: begin red_out <= 8'hff; green_out <= 8'hff; blue_out <= 8'hff; end
        endcase
    end
endmodule

`default_nettype wire