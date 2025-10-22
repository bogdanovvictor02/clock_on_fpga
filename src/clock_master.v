module clock_master
(
    input   i_Clock,

    output  o_Clock_1024Hz,
    output  o_Clock_512Hz,
    output  o_Clock_2Hz,
    output  o_Clock_1Hz,
    output  o_Enable_Clock_1Hz
);

    reg [14:0]  r_Counter = 15'b0;

    always @(posedge i_Clock) begin
        r_Counter <= r_Counter + 1'b1;
    end

    assign  o_Clock_1024Hz      = r_Counter[4];
    assign  o_Clock_512Hz       = r_Counter[5];
    assign  o_Clock_2Hz         = r_Counter[13];
    assign  o_Clock_1Hz         = r_Counter[14];
    assign  o_Enable_Clock_1Hz  = r_Counter == 15'b111111111111111;

endmodule