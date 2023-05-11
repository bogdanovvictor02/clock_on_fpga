module counter
#(
    parameter               c_WIDTH         = 4,
    parameter               c_RESET_VALUE   = 4'b1111
)(
    input                   i_Clock,
    input                   i_Reset,
    input                   i_Enable_Count,

    output  [c_WIDTH-1:0]   o_Data,
    output                  o_Carry
);

    reg [c_WIDTH-1:0] r_Counter = 0;

    always @(posedge i_Clock) begin
        if(i_Reset)
            r_Counter <= 0;
        else begin
            if(i_Enable_Count) begin
                if(r_Counter == c_RESET_VALUE)
                    r_Counter <= 0;
                else
                    r_Counter <= r_Counter + 1'b1;
            end
        end
    end

    assign o_Data[c_WIDTH-1:0]  = r_Counter[c_WIDTH-1:0];
    assign o_Carry              = i_Enable_Count & (r_Counter == c_RESET_VALUE);

endmodule