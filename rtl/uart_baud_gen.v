// Simple UART baud and oversample tick generator
// Generates:
//  - oversample_tick: ticks at BAUD_RATE * OVERSAMPLE
//  - baud_tick: ticks at BAUD_RATE (every OVERSAMPLE oversample ticks)
// Parameters allow synthesizable integer divider based on input clock.

module uart_baud_gen #(
    parameter integer CLOCK_FREQ_HZ = 50_000_000,
    parameter integer BAUD_RATE     = 115_200,
    parameter integer OVERSAMPLE    = 16
) (
    input  wire clk,
    input  wire reset,
    output reg  oversample_tick,
    output reg  baud_tick
);

    // Divider to generate oversample ticks
    localparam integer OVERSAMPLE_FREQ = BAUD_RATE * OVERSAMPLE;
    // Ensure divider is at least 1
    localparam integer DIVIDER = (CLOCK_FREQ_HZ + (OVERSAMPLE_FREQ/2)) / OVERSAMPLE_FREQ;

    // Protect against zero divider for very high requested rates
    localparam integer SAFE_DIVIDER = (DIVIDER < 1) ? 1 : DIVIDER;

    reg [$clog2(SAFE_DIVIDER):0] clock_div_counter = 0;
    reg [$clog2(OVERSAMPLE):0]   oversample_counter = 0;

    always @(posedge clk) begin
        if (reset) begin
            clock_div_counter <= 0;
            oversample_counter <= 0;
            oversample_tick <= 1'b0;
            baud_tick <= 1'b0;
        end else begin
            oversample_tick <= 1'b0;
            baud_tick <= 1'b0;

            if (clock_div_counter == SAFE_DIVIDER - 1) begin
                clock_div_counter <= 0;
                oversample_tick <= 1'b1;

                if (oversample_counter == OVERSAMPLE - 1) begin
                    oversample_counter <= 0;
                    baud_tick <= 1'b1;
                end else begin
                    oversample_counter <= oversample_counter + 1'b1;
                end
            end else begin
                clock_div_counter <= clock_div_counter + 1'b1;
            end
        end
    end

endmodule

