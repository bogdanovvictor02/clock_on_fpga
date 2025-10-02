// UART transmitter (8N1 by default)
// Drives 'txd' line. Handshake: present data with tx_valid when tx_ready=1.

module uart_tx #(
    parameter integer DATA_BITS = 8
) (
    input  wire                  clk,
    input  wire                  reset,
    // One tick per baud
    input  wire                  baud_tick,

    // Handshake for data input
    input  wire [DATA_BITS-1:0]  tx_data,
    input  wire                  tx_valid,
    output wire                  tx_ready,

    // Serial output
    output reg                   txd,
    output wire                  tx_busy
);

    localparam [1:0]
        ST_IDLE  = 2'd0,
        ST_START = 2'd1,
        ST_DATA  = 2'd2,
        ST_STOP  = 2'd3;

    reg [1:0] state = ST_IDLE;
    reg [DATA_BITS-1:0] shift_reg = {DATA_BITS{1'b0}};
    reg [$clog2(DATA_BITS):0] bit_index = 0;

    assign tx_busy  = (state != ST_IDLE);
    assign tx_ready = (state == ST_IDLE);

    always @(posedge clk) begin
        if (reset) begin
            state <= ST_IDLE;
            shift_reg <= {DATA_BITS{1'b0}};
            bit_index <= 0;
            txd <= 1'b1; // idle line is high
        end else begin
            case (state)
                ST_IDLE: begin
                    txd <= 1'b1;
                    if (tx_valid) begin
                        shift_reg <= tx_data;
                        bit_index <= 0;
                        state <= ST_START;
                    end
                end

                ST_START: begin
                    if (baud_tick) begin
                        txd <= 1'b0; // start bit
                        state <= ST_DATA;
                    end
                end

                ST_DATA: begin
                    if (baud_tick) begin
                        txd <= shift_reg[0];
                        shift_reg <= {1'b0, shift_reg[DATA_BITS-1:1]};
                        if (bit_index == DATA_BITS - 1) begin
                            bit_index <= 0;
                            state <= ST_STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end
                end

                ST_STOP: begin
                    if (baud_tick) begin
                        txd <= 1'b1; // stop bit
                        state <= ST_IDLE;
                    end
                end
                default: begin
                    state <= ST_IDLE;
                    txd <= 1'b1;
                end
            endcase
        end
    end

endmodule

