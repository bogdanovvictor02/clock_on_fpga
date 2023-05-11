module control_unit
(
    input           i_Clock,
    input           i_Switch,

    output          o_Counters_Reset,
    output          o_Counters_Enable_Increment,
    output  [2:0]   o_Counters_Enable_Count,

    output  [1:0]   o_Display_Enable_Digits,
    output          o_Display_Enable_Dot
);

    localparam IDLE         = 2'b00;
    localparam RESET_SEC    = 2'b01;
    localparam SET_MIN      = 2'b10;
    localparam SET_HOUR     = 2'b11;

    reg [1:0]   r_State         = 2'b0;
    reg [1:0]   r_Next_State    = 2'b0;

    reg         r_Counters_Reset;
    reg         r_Counters_Enable_Increment;
    reg [2:0]   r_Counters_Enable_Count;

    reg [1:0]   r_Display_Enable_Digits;
    reg         r_Display_Enable_Dot;

    always @(posedge i_Clock) begin
        r_State <= r_Next_State;
    end

    always @(*) begin
        case(r_State)
            IDLE: begin

                r_Counters_Reset            = 1'b0;
                r_Counters_Enable_Increment = 1'b0;
                r_Counters_Enable_Count     = 3'b111;

                r_Display_Enable_Digits     = 2'b00;
                r_Display_Enable_Dot        = 1'b1;

                if (i_Switch)
                    r_Next_State = RESET_SEC;
                else
                    r_Next_State = IDLE;
            end
            RESET_SEC: begin
                
                r_Counters_Reset            = 1'b1;
                r_Counters_Enable_Increment = 1'b0;
                r_Counters_Enable_Count     = 3'b000;

                r_Display_Enable_Digits     = 2'b00;
                r_Display_Enable_Dot        = 1'b0;
                
                r_Next_State = SET_MIN;
                
            end
            SET_MIN: begin

                r_Counters_Reset            = 1'b0;
                r_Counters_Enable_Increment = 1'b1;
                r_Counters_Enable_Count     = 3'b010;

                r_Display_Enable_Digits     = 2'b01;
                r_Display_Enable_Dot        = 1'b0;

                if (i_Switch)
                    r_Next_State = SET_HOUR;
                else
                    r_Next_State = SET_MIN;
 
            end
            SET_HOUR: begin

                r_Counters_Reset            = 1'b0;
                r_Counters_Enable_Increment = 1'b1;
                r_Counters_Enable_Count     = 3'b100;

                r_Display_Enable_Digits     = 2'b10;
                r_Display_Enable_Dot        = 1'b0;

                if (i_Switch)
                    r_Next_State = IDLE;
                else
                    r_Next_State = SET_HOUR;
                
            end
        endcase
    end

    assign o_Counters_Enable_Increment  = r_Counters_Enable_Increment;
    assign o_Counters_Reset             = r_Counters_Reset;
    assign o_Counters_Enable_Count[2:0] = r_Counters_Enable_Count[2:0];

    assign o_Display_Enable_Digits[1:0] = r_Display_Enable_Digits[1:0];
    assign o_Display_Enable_Dot         = r_Display_Enable_Dot;

endmodule