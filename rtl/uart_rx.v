// UART receiver (8N1 by default) with oversampling
// Uses mid-bit sampling based on an oversample_tick (e.g., 16x BAUD)

module uart_rx #(
    parameter integer DATA_BITS  = 8,
    parameter integer OVERSAMPLE = 16
) (
    input  wire                  clk,
    input  wire                  reset,
    // Oversample tick at BAUD*OVERSAMPLE
    input  wire                  oversample_tick,

    // Serial input
    input  wire                  rxd,

    // Output byte and status
    output reg  [DATA_BITS-1:0]  rx_data,
    output reg                   rx_valid,
    output reg                   framing_error
);

    // Synchronize RXD to clk domain to reduce metastability risk
    reg rxd_sync_0 = 1'b1;
    reg rxd_sync_1 = 1'b1;
    always @(posedge clk) begin
        if (reset) begin
            rxd_sync_0 <= 1'b1;
            rxd_sync_1 <= 1'b1;
        end else begin
            rxd_sync_0 <= rxd;
            rxd_sync_1 <= rxd_sync_0;
        end
    end

    localparam [2:0]
        ST_IDLE   = 3'd0,
        ST_START  = 3'd1,
        ST_DATA   = 3'd2,
        ST_STOP   = 3'd3,
        ST_WAIT   = 3'd4;

    reg [2:0] state = ST_IDLE;
    reg [$clog2(OVERSAMPLE):0] sample_counter = 0;
    reg [$clog2(DATA_BITS):0]  bit_index = 0;
    reg [DATA_BITS-1:0]        shift_reg = {DATA_BITS{1'b0}};

    always @(posedge clk) begin
        if (reset) begin
            state <= ST_IDLE;
            sample_counter <= 0;
            bit_index <= 0;
            shift_reg <= {DATA_BITS{1'b0}};
            rx_data <= {DATA_BITS{1'b0}};
            rx_valid <= 1'b0;
            framing_error <= 1'b0;
        end else begin
            rx_valid <= 1'b0;
            framing_error <= 1'b0;

            if (oversample_tick) begin
                case (state)
                    ST_IDLE: begin
                        if (rxd_sync_1 == 1'b0) begin
                            // Detected potential start bit edge; wait half a bit then confirm
                            sample_counter <= (OVERSAMPLE >> 1);
                            state <= ST_START;
                        end
                    end

                    ST_START: begin
                        if (sample_counter == 0) begin
                            // Midpoint of start bit
                            if (rxd_sync_1 == 1'b0) begin
                                // Valid start bit; set up to sample first data bit after one full bit period
                                sample_counter <= OVERSAMPLE - 1;
                                bit_index <= 0;
                                state <= ST_DATA;
                            end else begin
                                // False start; return to idle
                                state <= ST_IDLE;
                            end
                        end else begin
                            sample_counter <= sample_counter - 1'b1;
                        end
                    end

                    ST_DATA: begin
                        if (sample_counter == 0) begin
                            // Sample data bit in the middle of its bit period
                            shift_reg <= {rxd_sync_1, shift_reg[DATA_BITS-1:1]};
                            if (bit_index == DATA_BITS - 1) begin
                                bit_index <= 0;
                                sample_counter <= OVERSAMPLE - 1;
                                state <= ST_STOP;
                            end else begin
                                bit_index <= bit_index + 1'b1;
                                sample_counter <= OVERSAMPLE - 1;
                            end
                        end else begin
                            sample_counter <= sample_counter - 1'b1;
                        end
                    end

                    ST_STOP: begin
                        if (sample_counter == 0) begin
                            // Sample stop bit
                            if (rxd_sync_1 == 1'b1) begin
                                rx_data <= shift_reg;
                                rx_valid <= 1'b1;
                            end else begin
                                framing_error <= 1'b1;
                            end
                            state <= ST_WAIT;
                            sample_counter <= OVERSAMPLE - 1; // small gap to ensure line returns to idle
                        end else begin
                            sample_counter <= sample_counter - 1'b1;
                        end
                    end

                    ST_WAIT: begin
                        if (sample_counter == 0) begin
                            state <= ST_IDLE;
                        end else begin
                            sample_counter <= sample_counter - 1'b1;
                        end
                    end

                    default: begin
                        state <= ST_IDLE;
                    end
                endcase
            end
        end
    end

endmodule

