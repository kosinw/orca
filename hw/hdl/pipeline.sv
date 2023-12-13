`timescale 1ns / 1ps
`default_nettype none

module pipeline #(
    parameter PIPELINE_STAGES = 1,
    parameter PIPELINE_WIDTH  = 1
) (
    input wire clk_in,
    input wire rst_in,
    input wire [PIPELINE_WIDTH-1:0] signal_in,
    output logic [PIPELINE_WIDTH-1:0] signal_out
);
  logic [PIPELINE_WIDTH-1:0] signal_pipe[PIPELINE_STAGES-1:0];
  assign signal_out = signal_pipe[PIPELINE_STAGES-1];

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      for (int i = 0; i < PIPELINE_STAGES; i = i + 1) begin
        signal_pipe[i] <= 0;
      end
    end else begin
      signal_pipe[0] <= signal_in;
      for (int i = 1; i < PIPELINE_STAGES; i = i + 1) begin
        signal_pipe[i] <= signal_pipe[i-1];
      end
    end
  end
endmodule
`default_nettype wire
