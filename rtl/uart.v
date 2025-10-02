// Top-level UART (8N1) combining baud generator, transmitter, and receiver

module uart #(
    parameter integer CLOCK_FREQ_HZ = 50_000_000,
    parameter integer BAUD_RATE     = 115_200,
    parameter integer OVERSAMPLE    = 16,
    parameter integer DATA_BITS     = 8
) (
    input  wire                  clk,
    input  wire                  reset,

    // Transmit interface
    input  wire [DATA_BITS-1:0]  tx_data,
    input  wire                  tx_valid,
    output wire                  tx_ready,
    output wire                  tx_busy,
    output wire                  txd,

    // Receive interface
    input  wire                  rxd,
    output wire [DATA_BITS-1:0]  rx_data,
    output wire                  rx_valid,
    output wire                  rx_error
);

    wire oversample_tick;
    wire baud_tick;

    uart_baud_gen #(
        .CLOCK_FREQ_HZ(CLOCK_FREQ_HZ),
        .BAUD_RATE(BAUD_RATE),
        .OVERSAMPLE(OVERSAMPLE)
    ) u_baud (
        .clk(clk),
        .reset(reset),
        .oversample_tick(oversample_tick),
        .baud_tick(baud_tick)
    );

    uart_tx #(
        .DATA_BITS(DATA_BITS)
    ) u_tx (
        .clk(clk),
        .reset(reset),
        .baud_tick(baud_tick),
        .tx_data(tx_data),
        .tx_valid(tx_valid),
        .tx_ready(tx_ready),
        .txd(txd),
        .tx_busy(tx_busy)
    );

    wire [DATA_BITS-1:0] rx_data_int;
    wire rx_valid_int;
    wire rx_framing_error;

    uart_rx #(
        .DATA_BITS(DATA_BITS),
        .OVERSAMPLE(OVERSAMPLE)
    ) u_rx (
        .clk(clk),
        .reset(reset),
        .oversample_tick(oversample_tick),
        .rxd(rxd),
        .rx_data(rx_data_int),
        .rx_valid(rx_valid_int),
        .framing_error(rx_framing_error)
    );

    assign rx_data  = rx_data_int;
    assign rx_valid = rx_valid_int;
    assign rx_error = rx_framing_error;

endmodule

