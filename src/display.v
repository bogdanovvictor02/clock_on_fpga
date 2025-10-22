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

    // 4-bit Multiplexer 4 to 1 - selects which digit to display
    // i_Select: 00=Dig1(Tens_Hour), 01=Dig2(Units_Hour), 10=Dig3(Tens_Min), 11=Dig4(Units_Min)
    always @(*) begin
        case(i_Select)
            2'b00:  r_Data_Mux = i_Data_Dig1; // Tens of hours (0-2)
            2'b01:  r_Data_Mux = i_Data_Dig2; // Units of hours (0-9)
            2'b10:  r_Data_Mux = i_Data_Dig3; // Tens of minutes (0-5)
            2'b11:  r_Data_Mux = i_Data_Dig4; // Units of minutes (0-9)
        endcase
    end

    // BCD to 7-Seg decoder with ASCII representation
    // 7-segment layout:  aaa
    //                   f   b
    //                   f   b
    //                    ggg
    //                   e   c
    //                   e   c
    //                    ddd
    // Segment bits: [6:0] = [a,b,c,d,e,f,g]
    always @(*) begin
        case(r_Data_Mux)
            4'b0000: r_Segments = 7'b011_1111; // 0:  (all segments except g)
            4'b0001: r_Segments = 7'b000_0110; // 1:  (only b and c)
            4'b0010: r_Segments = 7'b101_1011; // 2:  (a,b,g,e,d)
            4'b0011: r_Segments = 7'b100_1111; // 3:  (a,b,g,c,d)
            4'b0100: r_Segments = 7'b110_0110; // 4:  (f,g,b,c)
            4'b0101: r_Segments = 7'b110_1101; // 5:  (a,f,g,c,d)
            4'b0110: r_Segments = 7'b111_1101; // 6:  (a,f,g,e,c,d)
            4'b0111: r_Segments = 7'b000_0111; // 7:  (only a,b,c)
            4'b1000: r_Segments = 7'b111_1111; // 8:  (all segments)
            4'b1001: r_Segments = 7'b110_1111; // 9:  (all except e)
            default: r_Segments = 7'b000_0000; // --: (blank)
        endcase
    end

    // Enable dot
    assign o_Segments[7]    = i_Enable_Dot & i_Select[0] & ~i_Select[1];

    // Assign output segments - only show segments if any digit is enabled
    assign o_Segments[6:0]  = (|i_Enable_Digits) ? r_Segments[6:0] : 7'b0000000;

    // Decoder 2 to 4 - enables the selected digit position
    // r_Digits[3:0] = [Dig4, Dig3, Dig2, Dig1] (Units_Min, Tens_Min, Units_Hour, Tens_Hour)
    always @(*) begin
        case(i_Select)
            2'b00:      r_Digits = 4'b0001; // Enable Dig1 (Tens_Hour)
            2'b01:      r_Digits = 4'b0010; // Enable Dig2 (Units_Hour)
            2'b10:      r_Digits = 4'b0100; // Enable Dig3 (Tens_Min)
            2'b11:      r_Digits = 4'b1000; // Enable Dig4 (Units_Min)
            default:    r_Digits = 4'b0000; // No digits enabled
        endcase
    end

    // Enable digits - combines control unit enable with multiplexer selection
    // i_Enable_Digits[3:0] comes from control_unit (which digits to show based on mode)
    // r_Digits[3:0] comes from multiplexer (which digit is currently selected)
    assign w_Enable_Digits[0] = i_Enable_Digits[3] & r_Digits[0]; // Dig1 (Tens_Hour)
    assign w_Enable_Digits[1] = i_Enable_Digits[2] & r_Digits[1]; // Dig2 (Units_Hour)
    assign w_Enable_Digits[2] = i_Enable_Digits[1] & r_Digits[2]; // Dig3 (Tens_Min)
    assign w_Enable_Digits[3] = i_Enable_Digits[0] & r_Digits[3]; // Dig4 (Units_Min)

    // Assign output digits
    assign o_Digits[3:0]    = w_Enable_Digits[3:0];

endmodule