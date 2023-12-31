`timescale 1ns / 1ps
`default_nettype none
`include "hdl/aes_defs.sv"

// typedef enum logic [1:0] {
//   IDLE,
//   CYCLE_1,
//   CYCLE_2,
//   READ_RESULT
// } AESMemReadStage;

// typedef enum logic [3:0] {
//   RD_DWORD_1,
//   RD_DWORD_2,
//   RD_DWORD_3,
//   RD_DWORD_4,
//   START_AES,
//   WAIT_FOR_AES_RESULT,
//   WB_DWORD_1,
//   WB_DWORD_2,
//   WB_DWORD_3,
//   WB_DWORD_4
// } AESProcessingStage;

module aes(
  input wire clk_in,
  input wire rst_in,

  input wire [ 2:0] aes_ctrl_in,
  input wire [31:0] data_in,

  output logic [ 3:0] aes_mem_we_out,
  output logic [ 9:0] aes_addr_out,

  output logic [31:0] data_out,
  output logic aes_complete_out,

  output logic [3:0] aes_processing_stage_out,
  output logic aes_ctrl_init_out
);

  localparam AES_INPUT_BASE_ADDR = 0;
  localparam AES_OUTPUT_BASE_ADDR = 255 + 1 + 1;

  // enum {
  //   IDLE,
  //   CYCLE_1,
  //   CYCLE_2,
  //   READ_RESULT
  // } aes_mem_rd_stage;

  // enum {
  //   RD_DWORD_1,
  //   RD_DWORD_2,
  //   RD_DWORD_3,
  //   RD_DWORD_4,
  //   START_AES,
  //   WAIT_FOR_AES_RESULT,
  //   WB_DWORD_1,
  //   WB_DWORD_2,
  //   WB_DWORD_3,
  //   WB_DWORD_4
  // } aes_processing_stage;

  // AESMemReadStage aes_mem_rd_stage;
  // AESProcessingStage aes_processing_stage;

  logic [1:0] aes_mem_rd_stage;
  logic [3:0] aes_processing_stage;

  logic [127:0] temp_aes_data_in, temp_aes_data_out;
  logic [2:0] DEBUG_FLAG;

  // counter to access the mem to read or write data
  logic [9:0] aes_mem_rd_ctr, aes_mem_wb_ctr;

  logic [31:0] temp_aes_data_out_dword_1, temp_aes_data_out_dword_2, temp_aes_data_out_dword_3, temp_aes_data_out_dword_4;

  assign temp_aes_data_out_dword_1 = temp_aes_data_out[127:96];
  assign temp_aes_data_out_dword_2 = temp_aes_data_out[95:64];
  assign temp_aes_data_out_dword_3 = temp_aes_data_out[63:32];
  assign temp_aes_data_out_dword_4 = temp_aes_data_out[31:0];

  logic aes_valid_result;
  logic init_aes, aes_ctrl_init, mode_decrypt, mode_encrypt;
  logic mode;

  // get individual aes control register flags
  assign mode_encrypt = aes_ctrl_in[0];
  assign mode_decrypt = aes_ctrl_in[1];
  assign aes_ctrl_init = (mode_encrypt || mode_decrypt) ? 1'b1 : 1'b0;
  assign aes_ctrl_init_out = aes_ctrl_init;
  assign aes_processing_stage_out = aes_processing_stage;

  // get the aes mode
  always_comb begin
    case ({mode_decrypt, mode_encrypt})
      2'b01: begin
        mode = `ENCRYPT;
      end
      2'b10: begin
        mode = `DECRYPT;
      end
      default: begin
        mode = `ENCRYPT;
      end
    endcase
  end


  // combination logic to handle aes_addr_out and aes_mem_we_out
  // used to read/write for aes_core to access input buffer or write to output buffer after encryption/decryption
  always_comb begin
    case (aes_processing_stage)
      `RD_DWORD_1, `RD_DWORD_2, `RD_DWORD_3, `RD_DWORD_4: begin
        aes_addr_out = AES_INPUT_BASE_ADDR + aes_mem_rd_ctr;
        aes_mem_we_out = 4'h0;
      end
      `WB_DWORD_1, `WB_DWORD_2, `WB_DWORD_3, `WB_DWORD_4: begin
        aes_addr_out = AES_OUTPUT_BASE_ADDR + aes_mem_wb_ctr;
        aes_mem_we_out = 4'hf;
      end
      default: begin
        aes_addr_out = AES_INPUT_BASE_ADDR + aes_mem_rd_ctr;
        aes_mem_we_out = 4'h0;
      end
    endcase
  end

  // combination logic to handle data_out
  // used to write to output buffer
  always_comb begin
    case (aes_processing_stage)
      `WB_DWORD_1, `WB_DWORD_2, `WB_DWORD_3, `WB_DWORD_4: begin 
        if (aes_mem_wb_ctr == aes_mem_rd_ctr) begin
          data_out = 32'hdeadbeef;
        end else begin
          if (aes_processing_stage == `WB_DWORD_1) data_out = temp_aes_data_out_dword_1;
          else if (aes_processing_stage == `WB_DWORD_2) data_out = temp_aes_data_out_dword_2;
          else if (aes_processing_stage == `WB_DWORD_3) data_out = temp_aes_data_out_dword_3;
          else if (aes_processing_stage == `WB_DWORD_4) data_out = temp_aes_data_out_dword_4;
          else data_out = 32'h0;
        end
      end 
      default: data_out = 32'h0;
    endcase
  end

  // assign mode = mode_encrypt ? `ENCRYPT : `DECRYPT;

  aes_core aes_core(
    .clk_in(clk_in),
    .rst_in(rst_in),

    .mode_in(mode),
    .init_in(init_aes),
    .data_in(temp_aes_data_in),

    // Hard set AES key
    .key_in(128'h2b28ab097eaef7cf15d2154f16a6883c),
    .data_out(temp_aes_data_out),
    .valid_out(aes_valid_result)
  );

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      aes_mem_rd_ctr <= 0;
      aes_mem_wb_ctr <= 0;

      aes_complete_out <= 0;

      aes_processing_stage <= `RD_DWORD_1;
      aes_mem_rd_stage <= `IDLE;

      temp_aes_data_in <= 0;
      // aes_addr_out <= 0;
      // aes_mem_we_out <= 0;

      init_aes <= 0;

      // temp_data_out <= 0;
    end else begin
      if (aes_ctrl_init) begin
        case (aes_processing_stage)
          `RD_DWORD_1, `RD_DWORD_2, `RD_DWORD_3, `RD_DWORD_4: begin
            // aes_mem_we_out <= 4'h0;
            case (aes_mem_rd_stage)
              `IDLE: begin
                // aes_addr_out <= AES_INPUT_BASE_ADDR + aes_mem_rd_ctr;
                aes_mem_rd_stage <= `CYCLE_1;
              end
              `CYCLE_1: begin
                // aes_mem_rd_stage <= `CYCLE_2;
                aes_mem_rd_stage <= `READ_RESULT;
              end
              // `CYCLE_2: begin
              //   aes_mem_rd_stage <= `READ_RESULT;
              // end
              `READ_RESULT: begin
                if (data_in == 32'hDEADBEEF) begin
                  aes_processing_stage <= `START_AES;
                end else begin
                  if (aes_processing_stage == `RD_DWORD_1) begin
                    temp_aes_data_in[127:96] <= data_in;
                    DEBUG_FLAG = 3'd1;
                  end else if  (aes_processing_stage == `RD_DWORD_2) begin
                    temp_aes_data_in[95:64] <= data_in;
                    DEBUG_FLAG = 3'd2;
                  end else if (aes_processing_stage == `RD_DWORD_3) begin
                    temp_aes_data_in[63:32] <= data_in;
                    DEBUG_FLAG = 3'd3;
                  end else if (aes_processing_stage == `RD_DWORD_4) begin
                    temp_aes_data_in[31:0] <= data_in;
                    DEBUG_FLAG = 3'd4;
                  end
                  aes_mem_rd_ctr <= aes_mem_rd_ctr + 1;
                  aes_processing_stage <= aes_processing_stage + 1;
                end
                aes_mem_rd_stage <= `IDLE;
              end
            endcase
          end
          `START_AES: begin
            init_aes <= 1;
            aes_processing_stage <= `WAIT_FOR_AES_RESULT;
          end
          `WAIT_FOR_AES_RESULT: begin
            temp_aes_data_in <= 0;
            init_aes <= 0;
            // once we have a valid result
            if (aes_valid_result) begin
              aes_processing_stage <= aes_processing_stage + 1;
              // aes_addr_out <= AES_OUTPUT_BASE_ADDR + aes_mem_wb_ctr;
            end
          end
          `WB_DWORD_1, `WB_DWORD_2, `WB_DWORD_3, `WB_DWORD_4: begin
            // aes_mem_we_out <= 4'hf;
            // aes_addr_out <= AES_OUTPUT_BASE_ADDR + aes_mem_wb_ctr;
            if (aes_mem_wb_ctr == aes_mem_rd_ctr) begin
              // temp_data_out <= 32'hDEADBEEF;
              aes_complete_out <= 1;
              aes_processing_stage <= `RD_DWORD_1;
            end else begin
              // if (aes_processing_stage == `WB_DWORD_1) begin
              //   temp_data_out <= temp_aes_data_out[127:96];
              // end else if (aes_processing_stage == `WB_DWORD_2) begin
              //   temp_data_out <= temp_aes_data_out[95:64];
              // end else if (aes_processing_stage == `WB_DWORD_3) begin
              //   temp_data_out <= temp_aes_data_out[63:32];
              // end else if (aes_processing_stage == `WB_DWORD_4) begin
              //   temp_data_out <= temp_aes_data_out[31:0];
              // end
              aes_mem_wb_ctr <= aes_mem_wb_ctr + 1;
              if (aes_processing_stage == `WB_DWORD_4) begin
                aes_processing_stage <= `RD_DWORD_1;
              end else begin
                aes_processing_stage <= aes_processing_stage + 1;
              end
            end
          end
        endcase
      end else begin
        aes_mem_rd_ctr <= 0;
        aes_mem_wb_ctr <= 0;

        aes_complete_out <= 0;

        aes_processing_stage <= `RD_DWORD_1;
        aes_mem_rd_stage <= `IDLE;

        temp_aes_data_in <= 0;
        // aes_addr_out <= 0;
        // aes_mem_we_out <= 0;

        init_aes <= 0;

        // temp_data_out <= 0;
      end
    end
  end

endmodule
