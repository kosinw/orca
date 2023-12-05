`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

module program_ram (
    input wire clk_in,
    input wire rst_in,
    input wire [31:0] pc_in,
    output logic [31:0] instr_out,
    input wire [31:0] cpu_addr_in,
    input wire [31:0] cpu_data_in,
    input wire [3:0] cpu_write_enable_in,
    output logic [31:0] cpu_data_out,
    input wire uart_rx_in
);
    logic [3:0] cpu_write_enable;
    logic [31:0] doutb;
    logic cpu_addr_in_range;

    logic [7:0] urx_brx_data;
    logic urx_brx_valid;

    logic [31:0] brx_mem_addr;
    logic [31:0] brx_mem_data;
    logic brx_mem_valid;

    assign cpu_addr_in_range = (cpu_addr_in[19:16] < 4'h2);
    assign cpu_write_enable = (cpu_addr_in_range) ? cpu_write_enable_in : 4'b0000;

    uart_rx #(.CLOCKS_PER_BAUD(33)) urx (
        .clk(clk_in),
        .rx(uart_rx_in),
        .data_o(urx_brx_data),
        .valid_o(urx_brx_valid)
    );

    ram_bridge_rx brx (
        .clk_in(clk_in),
        .data_in(urx_brx_data),
        .addr_out(brx_mem_addr),
        .data_out(brx_mem_data),
        .valid_out(brx_mem_valid)
    );

    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(32),
        .RAM_DEPTH(16384),
        .RAM_PERFORMANCE("LOW_LATENCY"),
        .INIT_FILE(`FPATH(program.mem))
    ) imem (
        .addra(pc_in[13:2]),
        .dina(32'h0),
        .clka(clk_in),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(instr_out),

        .addrb(brx_mem_addr[11:0]),
        .dinb(brx_mem_data),
        .clkb(clk_in),
        .web(brx_mem_valid),
        .enb(1'b1),
        .rstb(rst_in),
        .regceb(1'b1),
        .doutb()
    );

    xilinx_true_dual_port_read_first_byte_write_2_clock_ram #(
        .NB_COL(4),
        .COL_WIDTH(8),
        .RAM_DEPTH(16384),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE")
    ) dmem (
        .addra(brx_mem_addr[11:0]),
        .dina(brx_mem_data),
        .clka(clk_in),
        .wea({4{brx_mem_valid}}),
        .ena(1'b1),
        .rsta(rst_in),
        .regcea(1'b1),
        .douta(),

        .addrb(cpu_addr_in[13:2]),
        .dinb(cpu_data_in),
        .clkb(clk_in),
        .web(cpu_write_enable),
        .enb(1'b1),
        .rstb(rst_in),
        .regceb(1'b1),
        .doutb(doutb)
    );
endmodule

module ram_bridge_rx (
    input wire clk_in,

    input wire [7:0] data_in,
    input wire valid_in,

    output logic [31:0] addr_out,
    output logic [31:0] data_out,
    output logic valid_out
);
    initial addr_out = 0;
    initial data_out = 0;
    initial valid_out = 0;

    logic [7:0] buffer [7:0];

    localparam IDLE = 0;
    localparam WRITE = 1;

    logic state;
    logic [3:0] byte_num;

    always_ff @(posedge clk_in) begin
        addr_out <= 0;
        data_out <= 0;
        valid_out <= 0;

        if (state == IDLE) begin
            byte_num <= 0;
            if (valid_in) begin
                if (data_in == "W")     state <= WRITE;
            end
        end else if (valid_in) begin
            byte_num <= byte_num + 1;
            buffer[byte_num] <= data_in;

            if (byte_num == 8) begin
                state <= IDLE;

                addr_out <= {buffer[3],buffer[2],buffer[1],buffer[0]};
                data_out <= {buffer[7],buffer[6],buffer[5],buffer[4]};
                valid_out <= 1'b1;
            end
        end
    end

endmodule

`default_nettype wire