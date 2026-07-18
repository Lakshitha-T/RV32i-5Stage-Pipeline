// =============================================================
// rv32i_uart_debug.sv
//
// Adds a UART "register trace" output to Lakki's RV32I pipeline.
// Every time WB_RegWrite fires, prints:  xNN=DDDDDDDD\r\n
//   NN = destination register number in hex (00-1F)
//   DDDDDDDD = 32-bit write-back value in hex
//
// Drop this file into your Vivado project alongside your
// existing sources. Requires PipelinedCPU to expose:
//   WB_RegWrite_dbg, WB_WriteAddr_dbg, WB_WriteData_dbg
// (see chat message for the two-line patch to PipelinedCPU.sv)
// =============================================================

// -----------------------------------------------------------
// Simple 8N1 UART transmitter
// -----------------------------------------------------------
module UartTx #(
    parameter int CLK_FREQ_HZ = 125_000_000,
    parameter int BAUD_RATE   = 115200
)(
    input  logic       clk,
    input  logic       rst,
    input  logic       start,     // pulse 1 cycle to send tx_data
    input  logic [7:0] tx_data,
    output logic       tx,        // serial line, idle = 1
    output logic       busy
);
    localparam int CLKS_PER_BIT = CLK_FREQ_HZ / BAUD_RATE;

    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state;

    logic [$clog2(CLKS_PER_BIT+1)-1:0] clk_count;
    logic [2:0] bit_index;
    logic [7:0] data_reg;

    assign busy = (state != IDLE);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            tx        <= 1'b1;
            clk_count <= 0;
            bit_index <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    clk_count <= 0;
                    bit_index <= 0;
                    if (start) begin
                        data_reg <= tx_data;
                        state    <= START;
                    end
                end
                START: begin
                    tx <= 1'b0;
                    if (clk_count == CLKS_PER_BIT-1) begin
                        clk_count <= 0;
                        state <= DATA;
                    end else clk_count <= clk_count + 1;
                end
                DATA: begin
                    tx <= data_reg[bit_index];
                    if (clk_count == CLKS_PER_BIT-1) begin
                        clk_count <= 0;
                        if (bit_index == 3'd7) begin
                            bit_index <= 0;
                            state <= STOP;
                        end else bit_index <= bit_index + 1;
                    end else clk_count <= clk_count + 1;
                end
                STOP: begin
                    tx <= 1'b1;
                    if (clk_count == CLKS_PER_BIT-1) begin
                        clk_count <= 0;
                        state <= IDLE;
                    end else clk_count <= clk_count + 1;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule


// -----------------------------------------------------------
// On each register writeback, format and send:
//   x<2-hex-addr>=<8-hex-data>\r\n
// -----------------------------------------------------------
module RegDumpFSM #(
    parameter int CLK_FREQ_HZ = 125_000_000,
    parameter int BAUD_RATE   = 115200
)(
    input  logic        clk,
    input  logic        rst,
    input  logic        we,        // pulse: a register write happened
    input  logic [4:0]  waddr,
    input  logic [31:0] wdata,
    output logic        uart_tx
);
    localparam int MSG_LEN = 14; // 'x' + 2 hex + '=' + 8 hex + CR + LF

    logic [7:0] msg [0:MSG_LEN-1];
    logic [3:0] byte_idx;
    logic       start_tx, tx_busy;
    logic [7:0] tx_byte;

    function automatic [7:0] hex2ascii(input [3:0] nibble);
        hex2ascii = (nibble < 10) ? (8'h30 + nibble) : (8'h41 + nibble - 10);
    endfunction

    UartTx #(.CLK_FREQ_HZ(CLK_FREQ_HZ), .BAUD_RATE(BAUD_RATE)) tx_inst (
        .clk(clk), .rst(rst),
        .start(start_tx), .tx_data(tx_byte),
        .tx(uart_tx), .busy(tx_busy)
    );

    typedef enum logic [1:0] {IDLE, SEND, WAIT} state_t;
    state_t state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state    <= IDLE;
            byte_idx <= 0;
            start_tx <= 1'b0;
        end else begin
            start_tx <= 1'b0; // default: single-cycle pulse
            case (state)
                IDLE: begin
                    if (we) begin
                        msg[0]  <= "x";
                        msg[1]  <= hex2ascii({3'b0, waddr[4]});
                        msg[2]  <= hex2ascii(waddr[3:0]);
                        msg[3]  <= "=";
                        msg[4]  <= hex2ascii(wdata[31:28]);
                        msg[5]  <= hex2ascii(wdata[27:24]);
                        msg[6]  <= hex2ascii(wdata[23:20]);
                        msg[7]  <= hex2ascii(wdata[19:16]);
                        msg[8]  <= hex2ascii(wdata[15:12]);
                        msg[9]  <= hex2ascii(wdata[11:8]);
                        msg[10] <= hex2ascii(wdata[7:4]);
                        msg[11] <= hex2ascii(wdata[3:0]);
                        msg[12] <= 8'h0D; // CR
                        msg[13] <= 8'h0A; // LF
                        byte_idx <= 0;
                        state    <= SEND;
                    end
                end
                SEND: begin
                    if (!tx_busy) begin
                        tx_byte  <= msg[byte_idx];
                        start_tx <= 1'b1;
                        state    <= WAIT;
                    end
                end
                WAIT: begin
                    if (!tx_busy) begin
                        if (byte_idx == MSG_LEN-1) begin
                            state <= IDLE;
                        end else begin
                            byte_idx <= byte_idx + 1;
                            state    <= SEND;
                        end
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule


// -----------------------------------------------------------
// Top-level wrapper: CPU + UART register trace
// -----------------------------------------------------------
module RV32I_UART_Top #(
    parameter int CLK_FREQ_HZ = 125_000_000,
    parameter int BAUD_RATE   = 115200
)(
    input  logic sysclk,    // 125 MHz PYNQ-Z2 board clock
    input  logic btn_rst,   // active-high reset button
    output logic uart_txd
);

    logic wb_regwrite;
    logic [4:0]  wb_waddr;
    logic [31:0] wb_wdata;

    PipelinedCPU cpu_inst (
        .clk(sysclk),
        .rst(btn_rst),
        .WB_RegWrite_dbg(wb_regwrite),
        .WB_WriteAddr_dbg(wb_waddr),
        .WB_WriteData_dbg(wb_wdata)
    );

    RegDumpFSM #(.CLK_FREQ_HZ(CLK_FREQ_HZ), .BAUD_RATE(BAUD_RATE)) dump_inst (
        .clk(sysclk),
        .rst(btn_rst),
        .we(wb_regwrite),
        .waddr(wb_waddr),
        .wdata(wb_wdata),
        .uart_tx(uart_txd)
    );

endmodule
