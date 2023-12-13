`timescale 1ns / 1ps
`default_nettype none

`define TOPLEVEL 1

module top_level(
    input wire clk_board,
    input wire [15:0] sw,
    input wire [3:0] btn,
    input wire [2:0] pmodb,
    input wire uart_rxd,
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
    // turn off bright LEDs
    assign rgb1 = 0;
    assign rgb0 = 0;

    // have btn[0] control resetting system
    logic sys_rst;
    assign sys_rst = btn[0];

    // clock domains
    logic clk_74mhz, clk_371mhz;         // 74.25 MHz hdmi clock and 371.25 MHz
    logic clk_100mhz;                    // on board clock
    logic clk_50mhz;                     // cpu clock
    logic locked_unused;                 // locked signal (unused)
    logic locked_unused2;

    // tmds
    logic [9:0] tmds_10b [0:2];     // output of TMDS encoder
    logic tmds_signal [2:0];        // output of TMDS serializer

    // video controller
    logic video_vsync, video_hsync, video_active_draw, video_new_frame;
    logic [7:0] video_red, video_green, video_blue;

    // cpu
    logic [31:0] pc;
    logic [31:0] instr;

    // uart
    logic [7:0] urx_brx_data;
    logic urx_brx_valid;

    logic urx_halt;
    logic urx_reset;
    logic urx_start;

    logic [31:0] brx_mem_addr;
    logic [31:0] brx_mem_data;
    logic brx_mem_valid;

    logic brx_cpu_hlt;
    logic brx_cpu_rst;
    logic brx_cpu_start;

    // data bus
    logic [31:0] cpu_addr_out;
    logic [31:0] cpu_data_out;
    logic [3:0]  cpu_write_enable_out;
    logic [31:0] cpu_data_in;
    logic [31:0] cpu_debug_out;

    logic [31:0] video_addr_in;
    logic [31:0] video_data_in;
    logic [3:0]  video_write_enable_in;
    logic [31:0] video_data_out;

    logic [31:0] ram_addr_in;
    logic [31:0] ram_data_in;
    logic [3:0]  ram_write_enable_in;
    logic [31:0] ram_data_out;

    logic [31:0] keyboard_addr_in;
    logic [31:0] keyboard_data_in;
    logic [3:0]  keyboard_write_enable_in;
    logic [31:0] keyboard_data_out;

    ////////////////////////////////////////////////////////////
    //
    //  CLOCK STUFF
    //
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

    cpu_clk_wiz cpucw (
        .clk_out1(clk_50mhz),
        .reset(0),
        .locked(locked_unused2),
        .clk_in1(clk_100mhz)
    );

    ////////////////////////////////////////////////////////////
    //
    //  CPU
    //
    ////////////////////////////////////////////////////////////

    logic cpu_step;
    logic btn_db_out;
    logic btn2_press;
    logic cpu_halt;

    enum { HALT, RUN } cpu_state;

    initial cpu_state = HALT;

    always_ff @(posedge clk_50mhz) begin
        if (brx_cpu_start) begin
            cpu_state <= RUN;
        end else if (brx_cpu_hlt) begin
            cpu_state <= HALT;
        end
    end

    debouncer       btn2_db (.clk_in(clk_50mhz), .rst_in(sys_rst), .dirty_in(btn[3]), .clean_out(btn_db_out));
    edge_detector   btn2_det (.clk_in(clk_50mhz), .level_in(btn_db_out), .level_out(btn2_press));

    assign cpu_halt = (cpu_state == HALT) || sw[15];
    initial cpu_step = 1'b0;

    always_ff @(posedge clk_100mhz) begin
        cpu_step <= cpu_halt ? btn2_press : 1'b1;
    end

    riscv_core core (
        .clk_in(clk_50mhz),
        .rst_in(btn[1] || brx_cpu_rst),
        .cpu_step_in(cpu_step),
        .imem_data_in(instr),
        .imem_addr_out(pc),
        .dmem_addr_out(cpu_addr_out),
        .dmem_data_out(cpu_data_out),
        .dmem_write_enable_out(cpu_write_enable_out),
        .dmem_data_in(cpu_data_in),
        .debug_in(sw[15:0]),
        .debug_out(cpu_debug_out),
        .led_out(led)
    );

    ////////////////////////////////////////////////////////////
    //
    //  MEMORY + PERIPHERALS
    //
    ////////////////////////////////////////////////////////////

    memory_controller memory_ctrl (
        .clk_cpu_in(clk_50mhz),
        .rst_in(sys_rst),

        .cpu_addr_in(cpu_addr_out),
        .cpu_data_in(cpu_data_out),
        .cpu_write_enable_in(cpu_write_enable_out),
        .cpu_data_out(cpu_data_in),

        .video_addr_out(video_addr_in),
        .video_data_out(video_data_in),
        .video_write_enable_out(video_write_enable_in),
        .video_data_in(video_data_out),

        .ram_addr_out(ram_addr_in),
        .ram_data_out(ram_data_in),
        .ram_write_enable_out(ram_write_enable_in),
        .ram_data_in(ram_data_out),

        .keyboard_addr_out(keyboard_addr_in),
        .keyboard_data_out(keyboard_data_in),
        .keyboard_write_enable_out(keyboard_write_enable_in),
        .keyboard_data_in(keyboard_data_out)
    );

    logic kb_valid;
    logic [7:0] kb_scancode;

    ps2_rx kb (
        .clk_in(clk_100mhz),
        .rst_in(sys_rst),
        .ps2_clk_in(pmodb[2]),
        .ps2_data_in(pmodb[0]),
        .valid_out(kb_valid),
        .error_out(),
        .scancode_out(kb_scancode)
    );

    keyboard_ram kb_memory (
        .clk_in(),
        .rst_in(),
        
    );

    uart_rx #(.CLOCKS_PER_BAUD(17)) urx (
        .clk(clk_50mhz),
        .rx(uart_rxd),
        .data_o(urx_brx_data),
        .valid_o(urx_brx_valid)
    );

    ram_bridge_rx brx (
        .clk_in(clk_50mhz),
        .data_in(urx_brx_data),
        .valid_in(urx_brx_valid),
        .addr_out(brx_mem_addr),
        .data_out(brx_mem_data),
        .valid_out(brx_mem_valid),
        .halt_out(brx_cpu_hlt),
        .reset_out(brx_cpu_rst),
        .start_out(brx_cpu_start)
    );

    program_ram program_memory (
        .clk_in(clk_50mhz),
        .rst_in(sys_rst),

        .pc_in(pc),
        .instr_out(instr),

        .cpu_addr_in(ram_addr_in),
        .cpu_data_in(ram_data_in),
        .cpu_write_enable_in(ram_write_enable_in),
        .cpu_data_out(ram_data_out),

        .brx_addr_in(brx_mem_addr),
        .brx_data_in(brx_mem_data),
        .brx_valid_in(brx_mem_valid)
    );

    video_controller mvc (
        .clk_hdmi_in(clk_74mhz),
        .rst_in(sys_rst),
        .vsync_out(video_vsync),
        .hsync_out(video_hsync),
        .active_draw_out(video_active_draw),
        .new_frame_out(video_new_frame),
        .red_out(video_red),
        .green_out(video_green),
        .blue_out(video_blue),
        .clk_cpu_in(clk_50mhz),
        .cpu_addr_in(video_addr_in),
        .cpu_data_in(video_data_in),
        .cpu_write_enable_in(video_write_enable_in),
        .cpu_data_out(video_data_out)
    );

    logic [6:0] ss_c;

    seven_segment_controller mssc (
        .clk_in(clk_50mhz),
        .rst_in(sys_rst),
        .val_in(cpu_debug_out),
        .cat_out(ss_c),
        .an_out({ss0_an,ss1_an})
    );

    assign ss0_c = ss_c;
    assign ss1_c = ss_c;

    ////////////////////////////////////////////////////////////
    //
    //  HDMI
    //
    ////////////////////////////////////////////////////////////

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
