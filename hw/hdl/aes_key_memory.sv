`default_nettype none
`include "hdl/aes_defs.sv"

module aes_key_memory (
    input wire clk_in,
    input wire rst_in,
    input wire init_in,
    input wire [3:0] round_rd_in,
    input wire [127:0] key_in,
    output logic [127:0] key_out,
    output logic key_expanded_out
);
  logic [3:0] round;
  logic key_expanding;
  logic [127:0] key_memory [10:0];
  
  logic [127:0] temp_key, temp_next_key, temp_key_rd_out;
  assign key_out = temp_key_rd_out;
  
  aes_key_schedule aes_key_schedule(
    .round_in(round),
    .key_in(temp_key),
    .key_out(temp_next_key)
  );

  always_comb begin
    case (round_rd_in)
      4'd0: temp_key_rd_out = key_memory[0];
      4'd1: temp_key_rd_out = key_memory[1];
      4'd2: temp_key_rd_out = key_memory[2];
      4'd3: temp_key_rd_out = key_memory[3];
      4'd4: temp_key_rd_out = key_memory[4];
      4'd5: temp_key_rd_out = key_memory[5];
      4'd6: temp_key_rd_out = key_memory[6];
      4'd7: temp_key_rd_out = key_memory[7];
      4'd8: temp_key_rd_out = key_memory[8];
      4'd9: temp_key_rd_out = key_memory[9];
      4'd10: temp_key_rd_out = key_memory[10];
    endcase
  end

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      for (int i = 0; i < 11; i = i + 1) begin
        key_memory[i] <= 128'h0;
      end
      key_expanded_out <= 1'b0;
      key_expanding <= 1'b0;
      round <= `ROUND_INIT;
    end else begin
      if (init_in) begin
        key_expanding <= 1'b1;
        temp_key <= key_in;
        round <= `ROUND_INIT;
      end else begin
        if (key_expanding) begin
          case (round)
            `ROUND_INIT: begin
              key_memory[0] <= temp_key;
              round <= round + 1;
            end
            `ROUND_1, `ROUND_2, `ROUND_3, `ROUND_4, `ROUND_5, `ROUND_6, `ROUND_7, `ROUND_8, `ROUND_9, `ROUND_10: begin
              key_memory[round] <= temp_next_key;
              temp_key <= temp_next_key;
              if (round == `ROUND_10) begin
                key_expanded_out <= 1'b1;
                key_expanding <= 1'b0;
              end
              round <= round + 1;
            end
          endcase
        end else begin
          key_expanded_out <= 1'b0;
        end
      end
    end
  end

endmodule
