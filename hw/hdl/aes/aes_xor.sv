module aes_xor (
  input wire clk_in,
  input wire init_in,
  input wire [127:0] data_in,
  input wire [127:0] key_in,
  output logic [127:0] data_out
);

  always_ff @(posedge clk_in) begin
    if (init_in) begin
      data_out <= data_in ^ key_in;
    end
  end
  
endmodule