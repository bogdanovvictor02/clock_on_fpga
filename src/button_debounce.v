module button_debounce
(
    input   i_Clock,
    input   i_Button,

    output  o_Released_Button
);

    localparam c_DEBOUNCE_LIMIT = 10'b1111111111;

    reg [9:0]   r_Counter           = 10'b0;
    reg         r_State             = 1'b0;
    reg         r_Released_Button   = 1'b0;

    always @(posedge i_Clock) begin
        if(i_Button !== r_State && r_Counter < c_DEBOUNCE_LIMIT)
            r_Counter <= r_Counter + 1'b1;
        else if(r_Counter == 10'b1111111111) begin
            r_State <= i_Button;
            r_Counter <= 0;
        end else
            r_Counter <= 0;
    end

    always @(posedge i_Clock) begin
        r_Released_Button <= r_State;
    end

    assign o_Released_Button = r_Released_Button & ~r_State;

endmodule