module clock_counters
(
    input           i_Clock,

    input           i_Reset_Sec,
    input           i_Enable_Increment,

    input           i_Enable_Count_Sec,
    input           i_Enable_Count_Min,
    input           i_Enable_Count_Hour,

    output  [3:0]   o_Units_Sec,
    output  [2:0]   o_Tens_Sec,

    output  [3:0]   o_Units_Min,
    output  [2:0]   o_Tens_Min,
    
    output  [3:0]   o_Units_Hour,
    output  [1:0]   o_Tens_Hour
);

    localparam c_WIDTH_COUNTER_MOD9 = 4;
    localparam c_WIDTH_COUNTER_MOD5 = 3;
    localparam c_WIDTH_COUNTER_MOD3 = 2;

    //--------------------COUNTERS_SEC--------------------//

    localparam c_RESET_UNITS_SEC = 4'd9;
    localparam c_RESET_TENS_SEC  = 3'd5;

    wire w_Carry_Units_Sec;
    wire w_Carry_Tens_Sec;

    counter
    #(
        .c_WIDTH            (c_WIDTH_COUNTER_MOD9),
        .c_RESET_VALUE      (c_RESET_UNITS_SEC)
    ) UNITS_SEC (
        .i_Clock            (i_Clock),
        .i_Reset            (i_Reset_Sec),
        .i_Enable_Count     (i_Enable_Count_Sec),

        .o_Data             (o_Units_Sec),
        .o_Carry            (w_Carry_Units_Sec)
    );

    counter
    #(
        .c_WIDTH            (c_WIDTH_COUNTER_MOD5),
        .c_RESET_VALUE      (c_RESET_TENS_SEC)
    ) TENS_SEC (
        .i_Clock            (i_Clock),
        .i_Reset            (i_Reset_Sec),
        .i_Enable_Count     (w_Carry_Units_Sec),

        .o_Data             (o_Tens_Sec),
        .o_Carry            (w_Carry_Tens_Sec)
    );

    //--------------------COUNTERS_MIN--------------------//

    localparam c_RESET_UNITS_MIN = 4'd9;
    localparam c_RESET_TENS_MIN  = 3'd5;

    wire w_Carry_Units_Min;
    wire w_Carry_Tens_Min;
    wire w_Enable_Count_Units_Min;

    // Carry from seconds counters to minutes counters
	assign w_Enable_Count_Units_Min = i_Enable_Count_Min & (w_Carry_Tens_Sec | i_Enable_Increment);

    counter
    #(
        .c_WIDTH            (c_WIDTH_COUNTER_MOD9),
        .c_RESET_VALUE      (c_RESET_UNITS_MIN)
    ) UNITS_MIN (
        .i_Clock            (i_Clock),
        .i_Enable_Count     (w_Enable_Count_Units_Min),

        .o_Data             (o_Units_Min),
        .o_Carry            (w_Carry_Units_Min)
    );

    counter
    #(
        .c_WIDTH            (c_WIDTH_COUNTER_MOD5),
        .c_RESET_VALUE      (c_RESET_TENS_MIN)
    ) TENS_MIN (
        .i_Clock            (i_Clock),
        .i_Enable_Count     (w_Carry_Units_Min),

        .o_Data             (o_Tens_Min),
        .o_Carry            (w_Carry_Tens_Min)
    );

    //--------------------COUNTERS_HOUR--------------------//

    localparam c_RESET_UNITS_HOUR = 4'd9;
    localparam c_RESET_TENS_HOUR  = 2'd3;

    wire w_Carry_Units_Hour;
    wire w_Enable_Count_Units_Hour;

    wire w_Reset_Compare_Units_Hours;
    wire w_Reset_Compare_Tens_Hours;
    wire w_Reset_Compare_Hours;

    wire w_Reset_Hours_Normal_Count;
    wire w_Reset_Hours_Settings_Count;
    wire w_Reset_Hours;

    // Carry from minutes counters to hours counters
    assign w_Enable_Count_Units_Hour = i_Enable_Count_Hour & (w_Carry_Tens_Min | i_Enable_Increment);

    // Compare Units Hour with 2'd3
    assign w_Reset_Compare_Units_Hours = o_Units_Hour[1] & o_Units_Hour[0];

    // Compare Tens Hour with 2'd2
    assign w_Reset_Compare_Tens_Hours = o_Tens_Hour[1] & ~o_Tens_Hour[0];

    // Combined Compare Hours
    assign w_Reset_Compare_Hours = w_Reset_Compare_Tens_Hours & w_Reset_Compare_Units_Hours;

    // Reset overflow together seconds, minutes and hours counters
    assign w_Reset_Hours_Normal_Count = ~i_Enable_Increment & w_Reset_Compare_Hours & w_Carry_Tens_Min & w_Carry_Units_Min & w_Carry_Tens_Sec & w_Carry_Units_Sec;

    // Reset only overflow hours
    assign w_Reset_Hours_Settings_Count = i_Enable_Increment & w_Reset_Compare_Hours;

    // Combined Reset Hours
    assign w_Reset_Hours = w_Reset_Hours_Normal_Count | w_Reset_Hours_Settings_Count;

    counter
    #(
        .c_WIDTH            (c_WIDTH_COUNTER_MOD9),
        .c_RESET_VALUE      (c_RESET_UNITS_HOUR)
    ) UNITS_HOUR (
        .i_Clock            (i_Clock),
        .i_Reset            (w_Reset_Hours),
        .i_Enable_Count     (w_Enable_Count_Units_Hour),

        .o_Data             (o_Units_Hour),
        .o_Carry            (w_Carry_Units_Hour)
    );

    counter
    #(
        .c_WIDTH            (c_WIDTH_COUNTER_MOD3),
        .c_RESET_VALUE      (c_RESET_TENS_HOUR)
    ) TENS_HOUR (
        .i_Clock            (i_Clock),
        .i_Reset            (w_Reset_Hours),
        .i_Enable_Count     (w_Carry_Units_Hour),

        .o_Data             (o_Tens_Hour)
    );

endmodule