`timescale 1ns / 1ps
`default_nettype none

module top_level(
    input wire clk_board,
    input wire [15:0] sw,
    input wire [3:0] btn,
    input wire [2:0] pmodb,
    output logic [15:0] led,
    output logic [2:0] hdmi_tx_p,           // hdmi output signals (blue, green, red)
    output logic [2:0] hdmi_tx_n,           // hdmi output signals (negatives)
    output logic hdmi_clk_p, hdmi_clk_n,    // differential hdmi clock
    output logic [2:0] rgb0,
    output logic [2:0] rgb1,
    output logic [3:0] ss0_an,              // anode control for upper 4 digits
    output logic [3:0] ss1_an,              // anode control for lower 4 digits
    output logic [6:0] ss0_c,               // cathode control for upper 4 digits
    output logic [6:0] ss1_c                // cathode control for upper 4 digits
);
    ////////////////////////////////////////////////////////////
    // DECLARATIONS
    ////////////////////////////////////////////////////////////

    // turn off bright LEDs
    assign rgb1 = 0;
    assign rgb0 = 0;
    assign led = sw;

    // have btn[0] control resetting system
    logic sys_rst;
    assign sys_rst = btn[0];

    // clock domains
    logic clk_74mhz, clk_371mhz;         // 74.25 MHz hdmi clock and 371.25 MHz
    logic clk_100mhz;
    logic locked_unused;                 // locked signal (unused)

    // tmds
    logic [9:0] tmds_10b [0:2];     // output of TMDS encoder
    logic tmds_signal [2:0];        // output of TMDS serializer

    // video controller
    logic video_vsync, video_hsync, video_active_draw, video_new_frame;
    logic [7:0] video_red, video_green, video_blue;

    ////////////////////////////////////////////////////////////
    // RISC-V CORE
    ////////////////////////////////////////////////////////////

    logic [31:0] inst;
    logic [31:0] ram_data_rd;
    logic [13:0] pc;
    logic [31:0] mem_addr, ram_data_wr;
    logic mem_we;

    riscv_core riscv_core (
        .clk_100mhz(clk_100mhz),
        .rst_in(sys_rst),
        .inst_in(inst),
        .ram_data_in(ram_data_rd),
        .pc_out(pc),
        .mem_addr_out(mem_addr),
        .ram_data_out(ram_data_wr),
        .mem_we_out(mem_we),
    );

    ////////////////////////////////////////////////////////////
    // BRAM FOR PROGRAM
    // Program ROM: 32 * 16000 = 512 Kb = 64 KB
    // Program RAM: 32 * 32000 = 1024 kb = 128 KB
    ////////////////////////////////////////////////////////////

    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(32),
        .RAM_DEPTH(16000 + 32000),
        // .INIT_FILE(TEXT_INIT_FILE)
    ) bram (
        .addra(pc),
        .clka(clk_100mhz),
        .wea(1'b0),
        .dina(16'b0),
        .ena(1'b1),
        .regcea(1'b1),
        .rsta(rst_in),
        .douta(inst),

        .addrb(mem_addr),
        .dinb(ram_data_wr),
        .clkb(clk_100mhz),
        .web(mem_we),
        .enb(1'b1),
        .rstb(rst_in),
        .regceb(1'b1),
        .doutb()
    );

    ////////////////////////////////////////////////////////////
    // BLOCKS
    ////////////////////////////////////////////////////////////

    BUFG mbf (
        .I(clk_board),
        .O(clk_100mhz)
    );

    hdmi_clk_wiz_720p hdmicw (
        .clk_pixel(clk_74mhz),
        .clk_tmds(clk_371mhz),
        .reset(0),
        .locked(locked_unused),
        .clk_ref(clk_100mhz)
    );

    // TODO(kosinw): Remove me, just for testing keyboard logic
    logic [7:0] mkb_scancode;
    logic mkb_valid;

    ps2_rx mkb (
        .clk_in(clk_100mhz),
        .rst_in(sys_rst),
        .ps2_clk_in(pmodb[2]),
        .ps2_data_in(pmodb[0]),
        .valid_out(mkb_valid),
        .error_out(),
        .scancode_out(mkb_scancode)
    );

    logic [31:0] scancode_buffer;
    logic [6:0] ss_c;

    always_ff @(posedge clk_100mhz) begin
        if (sys_rst) begin
            scancode_buffer <= 32'h0;
        end else begin
            if (mkb_valid) begin
                scancode_buffer <= {scancode_buffer[23:0],mkb_scancode};
            end
        end
    end

    seven_segment_controller mssc (
        .clk_in(clk_100mhz),
        .rst_in(sys_rst),
        .val_in(scancode_buffer),
        .cat_out(ss_c),
        .an_out({ss0_an,ss1_an})
    );

    assign ss0_c = ss_c;
    assign ss1_c = ss_c;

    video_controller mvc (
        .clk_hdmi_in(clk_74mhz),
        .rst_in(sys_rst),
        .vsync_out(video_vsync),
        .hsync_out(video_hsync),
        .active_draw_out(video_active_draw),
        .new_frame_out(video_new_frame),
        .red_out(video_red),
        .green_out(video_green),
        .blue_out(video_blue)
    );

    tmds_encoder tmds_encoder_red (
        .clk_in(clk_74mhz),
        .rst_in(sys_rst),
        .data_in(video_red),
        .control_in(2'b0),
        .ve_in(video_active_draw),
        .tmds_out(tmds_10b[2])
    );

    tmds_encoder tmds_encoder_green (
        .clk_in(clk_74mhz),
        .rst_in(sys_rst),
        .data_in(video_green),
        .control_in(2'b0),
        .ve_in(video_active_draw),
        .tmds_out(tmds_10b[1])
    );

    tmds_encoder tmds_encoder_blue (
        .clk_in(clk_74mhz),
        .rst_in(sys_rst),
        .data_in(video_blue),
        .control_in({video_vsync, video_hsync}),
        .ve_in(video_active_draw),
        .tmds_out(tmds_10b[0])
    );

    tmds_serializer tmds_serializer_red (
        .clk_pixel_in(clk_74mhz),
        .clk_5x_in(clk_371mhz),
        .rst_in(sys_rst),
        .tmds_in(tmds_10b[2]),
        .tmds_out(tmds_signal[2])
    );

    tmds_serializer tmds_serializer_green (
        .clk_pixel_in(clk_74mhz),
        .clk_5x_in(clk_371mhz),
        .rst_in(sys_rst),
        .tmds_in(tmds_10b[1]),
        .tmds_out(tmds_signal[1])
    );

    tmds_serializer tmds_serializer_blue (
        .clk_pixel_in(clk_74mhz),
        .clk_5x_in(clk_371mhz),
        .rst_in(sys_rst),
        .tmds_in(tmds_10b[0]),
        .tmds_out(tmds_signal[0])
    );

    OBUFDS OBUFDS_blue (.I(tmds_signal[0]), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));
    OBUFDS OBUFDS_green(.I(tmds_signal[1]), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
    OBUFDS OBUFDS_red  (.I(tmds_signal[2]), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
    OBUFDS OBUFDS_clock(.I(clk_74mhz), .O(hdmi_clk_p), .OB(hdmi_clk_n));

endmodule

`default_nettype wire
