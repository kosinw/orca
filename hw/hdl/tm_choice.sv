module tm_choice (
  input wire [7:0] data_in,
  output logic [8:0] qm_out
  );

  logic [3:0] popcnt;
  logic option2;

  always_comb begin
    popcnt = 4'd0;

    foreach (data_in[i]) begin
        popcnt = popcnt + data_in[i];
    end

    qm_out[0] = data_in[0];

    option2 = ((popcnt > 4) || (popcnt === 4'd4 && !data_in[0]));

    for (integer j = 1; j <= 7; j = j + 1) begin
        qm_out[j] = option2
                    ? ~(qm_out[j - 1] ^ data_in[j])
                    : (qm_out[j - 1] ^ data_in[j]);
    end

    qm_out[8] = option2 ? 1'b0 : 1'b1;
  end
endmodule
