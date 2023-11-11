module tmds_encoder(
    input wire clk_in,
    input wire rst_in,
    input wire [7:0] data_in,  // video data (red, green or blue)
    input wire [1:0] control_in, //for blue set to {vs,hs}, else will be 0
    input wire ve_in,  // video data enable, to choose between control or video signal
    output logic [9:0] tmds_out
);

    logic [9:0] next_tmds_out;
    logic [8:0] q_m;
    logic [4:0] tally, next_tally;
    logic [3:0] num_ones, num_zeroes;

    tm_choice mtm(
        .data_in(data_in),
        .qm_out(q_m));

    always_comb begin
        num_ones   = 4'd0;
        num_zeroes = 4'd0;

        for (integer i = 0; i < 8; i = i + 1) begin
            num_ones = num_ones + q_m[i];
            num_zeroes = num_zeroes + ~q_m[i];
        end

        if ((tally === 0) || (num_ones === num_zeroes)) begin
            next_tmds_out = {~q_m[8], q_m[8], (q_m[8] ? q_m[7:0] : ~q_m[7:0])};
            next_tally = (q_m[8] === 0) ? (tally+(num_zeroes-num_ones)) : (tally+(num_ones-num_zeroes));
        end else begin
            if (
                ((!tally[4]) && (num_ones>num_zeroes))  ||
                ((tally[4]) && (num_zeroes>num_ones))
            ) begin
                next_tmds_out = {1'b1, q_m[8], ~q_m[7:0]};
                next_tally = tally + {q_m[8], 1'b0} + (num_zeroes-num_ones);
            end else begin
                next_tmds_out = {1'b0, q_m[8], q_m[7:0]};
                next_tally = tally - {~q_m[8], 1'b0} + (num_ones-num_zeroes);
            end
        end
    end

    always_ff @(posedge clk_in) begin
        tally <= (rst_in || !ve_in) ? 0 : next_tally;

        if (ve_in) begin
            tmds_out <= (rst_in) ? 0 : next_tmds_out;
        end else begin
            case (control_in)
                2'b00: tmds_out <= 10'b1101010100;
                2'b01: tmds_out <= 10'b0010101011;
                2'b10: tmds_out <= 10'b0101010100;
                2'b11: tmds_out <= 10'b1010101011;
            endcase
        end
    end
endmodule