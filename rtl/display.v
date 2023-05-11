module display
(
    input   [1:0]   i_Select,

    input   [3:0]   i_Enable_Digits,
    input           i_Enable_Dot,

    input   [3:0]   i_Data_Dig1,
    input   [3:0]   i_Data_Dig2,
    input   [3:0]   i_Data_Dig3,
    input   [3:0]   i_Data_Dig4,

    output  [7:0]   o_Segments,
    output  [3:0]   o_Digits
);

    reg     [3:0]   r_Data_Mux;
    reg     [6:0]   r_Segments;
    reg     [3:0]   r_Digits;

    wire    [3:0]   w_Enable_Digits;

    // 4-bit Multiplexer 4 to 1
    always @(*) begin
        case(i_Select)
            2'b00:  r_Data_Mux = i_Data_Dig1;
            2'b01:  r_Data_Mux = i_Data_Dig2;
            2'b10:  r_Data_Mux = i_Data_Dig3;
            2'b11:  r_Data_Mux = i_Data_Dig4;
        endcase
    end

    // BCD to 7-Seg decoder
    always @(*) begin
        case(r_Data_Mux)
            4'b0000: r_Segments = 7'b011_1111;
            4'b0001: r_Segments = 7'b000_0110;
            4'b0010: r_Segments = 7'b101_1011;
            4'b0011: r_Segments = 7'b100_1111;
            4'b0100: r_Segments = 7'b110_0110;
            4'b0101: r_Segments = 7'b110_1101;
            4'b0110: r_Segments = 7'b111_1101;
            4'b0111: r_Segments = 7'b000_0111;
            4'b1000: r_Segments = 7'b111_1111;
            4'b1001: r_Segments = 7'b110_1111;
            default: r_Segments = 7'b000_0000;
        endcase
    end

    // Enable dot
    assign o_Segments[7]    = i_Enable_Dot & i_Select[0] & ~i_Select[1];

    // Assign output segments
    assign o_Segments[6:0]  = r_Segments[6:0];

    // Decoder 2 to 4
    always @(*) begin
        case(i_Select)
            2'b00:      r_Digits = 4'b0001;
            2'b01:      r_Digits = 4'b0010;
            2'b10:      r_Digits = 4'b0100;
            2'b11:      r_Digits = 4'b1000;
            default:    r_Digits = 4'b0000;
        endcase
    end

    // Enable digits
    assign w_Enable_Digits[0] = i_Enable_Digits[3] & r_Digits[0];
    assign w_Enable_Digits[1] = i_Enable_Digits[2] & r_Digits[1];
    assign w_Enable_Digits[2] = i_Enable_Digits[1] & r_Digits[2];
    assign w_Enable_Digits[3] = i_Enable_Digits[0] & r_Digits[3];

    // Assign output digits
    assign o_Digits[3:0]    = w_Enable_Digits[3:0];

endmodule