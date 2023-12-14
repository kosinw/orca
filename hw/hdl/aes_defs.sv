// Round definitions
`define ROUND_INIT        4'd0
`define ROUND_1           4'd1
`define ROUND_2           4'd2
`define ROUND_3           4'd3
`define ROUND_4           4'd4  
`define ROUND_5           4'd5
`define ROUND_6           4'd6
`define ROUND_7           4'd7
`define ROUND_8           4'd8
`define ROUND_9           4'd9
`define ROUND_10          4'd10

// Stage definitions
`define IDLE              3'd0

`define SUB_BYTES         3'd1
`define SHIFT_ROWS        3'd2  
`define MIX_COLUMNS       3'd3  
`define ADD_ROUND_KEY     3'd4
`define INV_SUB_BYTES     3'd5
`define INV_SHIFT_ROWS    3'd6
`define INV_MIX_COLUMNS   3'd7

// AES Mode
`define ENCRYPT           1'b1
`define DECRYPT           1'b0

// AES Memory Read Stage
`define CYCLE_1           2'd1
`define CYCLE_2           2'd2
`define READ_RESULT       2'd3

// AES Processing Stage
`define RD_DWORD_1            4'd0
`define RD_DWORD_2            4'd1
`define RD_DWORD_3            4'd2
`define RD_DWORD_4            4'd3
`define START_AES             4'd4
`define WAIT_FOR_AES_RESULT   4'd5
`define WB_DWORD_1            4'd6
`define WB_DWORD_2            4'd7
`define WB_DWORD_3            4'd8
`define WB_DWORD_4            4'd9