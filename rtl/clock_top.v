module clock_top
(
    input           i_Clock,
    input           i_Button_Set,
    input           i_Button_Up,

    output  [7:0]   o_Segments,
    output  [3:0]   o_Digits
);

    //--------------------BUTTON_SET--------------------//

    wire            w_Released_Button_Set;

    button_debounce                     BUTTON_SET
    (
        .i_Clock                        (i_Clock),
        .i_Button                       (i_Button_Set),

        .o_Released_Button              (w_Released_Button_Set)
    );

    //--------------------BUTTON_UP--------------------//

    wire            w_Released_Button_Up;

    button_debounce                     BUTTON_UP
    (
        .i_Clock                        (i_Clock),
        .i_Button                       (i_Button_Up),

        .o_Released_Button              (w_Released_Button_Up)
    );

    //--------------------CLOCK_MASTER--------------------//

    wire    [1:0]   w_Display_Clock;
    wire            w_Display_Blink_Digits;
    wire            w_Display_Blink_Dot;
    wire            w_Enable_Clock_Count_Sec;

    clock_master                        CLOCK_MASTER
    (
        .i_Clock                        (i_Clock),

        .o_Clock_1024Hz                 (w_Display_Clock[0]),
        .o_Clock_512Hz                  (w_Display_Clock[1]),
        .o_Clock_2Hz                    (w_Display_Blink_Digits),
        .o_Clock_1Hz                    (w_Display_Blink_Dot),
        .o_Enable_Clock_1Hz             (w_Enable_Clock_Count_Sec)
    );

    //--------------------CONTROL_UNIT--------------------//

    wire            w_Counters_Reset_Sec;
    wire            w_Counters_Enable_Increment;
    wire    [2:0]   w_Counters_Enable_Count;
    wire    [1:0]   w_Display_Enable_Digits;
    wire            w_Display_Enable_Dot;

    control_unit                        CONTROL_UNIT
    (
        .i_Clock                        (i_Clock),
        .i_Switch                       (w_Released_Button_Set),

        .o_Counters_Reset               (w_Counters_Reset_Sec),
        .o_Counters_Enable_Increment    (w_Counters_Enable_Increment),
        .o_Counters_Enable_Count        (w_Counters_Enable_Count),

        .o_Display_Enable_Digits        (w_Display_Enable_Digits),
        .o_Display_Enable_Dot           (w_Display_Enable_Dot)
    );

    assign w_Enable_Count_Sec = w_Counters_Enable_Count[0] & w_Enable_Clock_Count_Sec;

	assign w_Enable_Increment = w_Counters_Enable_Increment & w_Released_Button_Up;

    //--------------------CLOCK_COUNTERS--------------------//

    wire            w_Enable_Increment;
    wire            w_Enable_Count_Sec;
    wire    [3:0]   w_Units_Sec;
    wire    [2:0]   w_Tens_Sec;
    wire    [3:0]   w_Units_Min;
    wire    [2:0]   w_Tens_Min;
    wire    [3:0]   w_Units_Hour;
    wire    [1:0]   w_Tens_Hour;

    clock_counters                      CLOCK_COUNTERS
    (
        .i_Clock                        (i_Clock),

        .i_Reset_Sec                    (w_Counters_Reset_Sec),
        .i_Enable_Increment             (w_Enable_Increment),

        .i_Enable_Count_Sec             (w_Enable_Count_Sec),
        .i_Enable_Count_Min             (w_Counters_Enable_Count[1]),
        .i_Enable_Count_Hour            (w_Counters_Enable_Count[2]),

        .o_Units_Sec                    (w_Units_Sec),
        .o_Tens_Sec                     (w_Tens_Sec),

        .o_Units_Min                    (w_Units_Min),
        .o_Tens_Min                     (w_Tens_Min),
        
        .o_Units_Hour                   (w_Units_Hour),
        .o_Tens_Hour                    (w_Tens_Hour)
    );

    //--------------------DISPLAY--------------------//

    wire    [3:0]   w_Enable_Digits;
    wire            w_Enable_Dot;

    assign w_Enable_Digits[0]   = ~(w_Display_Blink_Digits & w_Display_Enable_Digits[0]);
    assign w_Enable_Digits[1]   = ~(w_Display_Blink_Digits & w_Display_Enable_Digits[0]);
    assign w_Enable_Digits[2]   = ~(w_Display_Blink_Digits & w_Display_Enable_Digits[1]);
    assign w_Enable_Digits[3]   = ~(w_Display_Blink_Digits & w_Display_Enable_Digits[1]);

    assign w_Enable_Dot         = w_Display_Blink_Dot & w_Display_Enable_Dot;

    display                             DISPLAY
    (
        .i_Select                       (w_Display_Clock),

        .i_Enable_Digits                (w_Enable_Digits),
        .i_Enable_Dot                   (w_Enable_Dot),

        .i_Data_Dig1                    (w_Tens_Hour),
        .i_Data_Dig2                    (w_Units_Hour),
        .i_Data_Dig3                    (w_Tens_Min),
        .i_Data_Dig4                    (w_Units_Min),

        .o_Segments                     (o_Segments),
        .o_Digits                       (o_Digits)
    );

endmodule