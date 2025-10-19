`timescale 1ns/1ps

module clock_counters_tb;

    // Testbench signals
    reg         i_Clock;
    reg         i_Reset_Sec;
    reg         i_Enable_Increment;
    reg         i_Enable_Count_Sec;
    reg         i_Enable_Count_Min;
    reg         i_Enable_Count_Hour;
    wire [3:0]  o_Units_Sec;
    wire [2:0]  o_Tens_Sec;
    wire [3:0]  o_Units_Min;
    wire [2:0]  o_Tens_Min;
    wire [3:0]  o_Units_Hour;
    wire [1:0]  o_Tens_Hour;
    
    // Clock generation
    parameter CLOCK_PERIOD = 10; // 10ns period = 100MHz
    
    initial begin
        i_Clock = 0;
        forever #(CLOCK_PERIOD/2) i_Clock = ~i_Clock;
    end
    
    // Instantiate the module under test
    clock_counters uut (
        .i_Clock(i_Clock),
        .i_Reset_Sec(i_Reset_Sec),
        .i_Enable_Increment(i_Enable_Increment),
        .i_Enable_Count_Sec(i_Enable_Count_Sec),
        .i_Enable_Count_Min(i_Enable_Count_Min),
        .i_Enable_Count_Hour(i_Enable_Count_Hour),
        .o_Units_Sec(o_Units_Sec),
        .o_Tens_Sec(o_Tens_Sec),
        .o_Units_Min(o_Units_Min),
        .o_Tens_Min(o_Tens_Min),
        .o_Units_Hour(o_Units_Hour),
        .o_Tens_Hour(o_Tens_Hour)
    );
    
    // Test variables
    integer test_count = 0;
    integer error_count = 0;
    
    // Task to check expected output
    task check_time;
        input [3:0] expected_units_sec;
        input [2:0] expected_tens_sec;
        input [3:0] expected_units_min;
        input [2:0] expected_tens_min;
        input [3:0] expected_units_hour;
        input [1:0] expected_tens_hour;
        input [255:0] test_name;
        begin
            test_count = test_count + 1;
            if (o_Units_Sec !== expected_units_sec || 
                o_Tens_Sec !== expected_tens_sec ||
                o_Units_Min !== expected_units_min ||
                o_Tens_Min !== expected_tens_min ||
                o_Units_Hour !== expected_units_hour ||
                o_Tens_Hour !== expected_tens_hour) begin
                $display("ERROR: %s", test_name);
                $display("  Expected: %02d:%02d:%02d (HH:MM:SS)", 
                        {expected_tens_hour, expected_units_hour}, 
                        {expected_tens_min, expected_units_min}, 
                        {expected_tens_sec, expected_units_sec});
                $display("  Got:      %02d:%02d:%02d (HH:MM:SS)", 
                        {o_Tens_Hour, o_Units_Hour}, 
                        {o_Tens_Min, o_Units_Min}, 
                        {o_Tens_Sec, o_Units_Sec});
                error_count = error_count + 1;
            end else begin
                $display("PASS: %s - Time: %02d:%02d:%02d", test_name,
                        {o_Tens_Hour, o_Units_Hour}, 
                        {o_Tens_Min, o_Units_Min}, 
                        {o_Tens_Sec, o_Units_Sec});
            end
        end
    endtask
    
    // Task to count seconds
    task count_seconds;
        input integer num_seconds;
        begin
            for (integer i = 0; i < num_seconds; i = i + 1) begin
                @(posedge i_Clock);
            end
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("Starting clock_counters testbench...");
        $display("=====================================");
        
        // Initialize VCD dump
        $dumpfile("tests/clock_counters_tb.vcd");
        $dumpvars(0, clock_counters_tb);
        
        // Initialize inputs
        i_Reset_Sec = 0;
        i_Enable_Increment = 0;
        i_Enable_Count_Sec = 0;
        i_Enable_Count_Min = 0;
        i_Enable_Count_Hour = 0;
        
        // Wait for initial reset
        repeat(5) @(posedge i_Clock);
        
        // Test 1: Initial state
        $display("\nTest 1: Initial state");
        check_time(4'b0000, 3'b000, 4'b0000, 3'b000, 4'b0000, 2'b00, "Initial state - all zeros");
        
        // Test 2: Reset seconds
        $display("\nTest 2: Reset seconds");
        i_Reset_Sec = 1;
        @(posedge i_Clock);
        check_time(4'b0000, 3'b000, 4'b0000, 3'b000, 4'b0000, 2'b00, "Reset seconds - all should be zero");
        
        i_Reset_Sec = 0;
        @(posedge i_Clock);
        check_time(4'b0000, 3'b000, 4'b0000, 3'b000, 4'b0000, 2'b00, "Reset released - should stay zero");
        
        // Test 3: Count seconds only
        $display("\nTest 3: Count seconds only");
        i_Enable_Count_Sec = 1;
        
        // Count to 5 seconds
        repeat(5) @(posedge i_Clock);
        check_time(4'b0101, 3'b000, 4'b0000, 3'b000, 4'b0000, 2'b00, "Count to 5 seconds");
        
        // Count to 10 seconds
        repeat(5) @(posedge i_Clock);
        check_time(4'b0000, 3'b001, 4'b0000, 3'b000, 4'b0000, 2'b00, "Count to 10 seconds");
        
        // Count to 15 seconds
        repeat(5) @(posedge i_Clock);
        check_time(4'b0101, 3'b001, 4'b0000, 3'b000, 4'b0000, 2'b00, "Count to 15 seconds");
        
        // Test 4: Seconds overflow to minutes
        $display("\nTest 4: Seconds overflow to minutes");
        i_Enable_Count_Min = 1;
        
        // Count to 59 seconds
        repeat(44) @(posedge i_Clock); // 15 + 44 = 59
        check_time(4'b1001, 3'b101, 4'b0000, 3'b000, 4'b0000, 2'b00, "Count to 59 seconds");
        
        // Next second should overflow to 1 minute
        @(posedge i_Clock);
        check_time(4'b0000, 3'b000, 4'b0001, 3'b000, 4'b0000, 2'b00, "Overflow to 1 minute");
        
        // Test 5: Count minutes
        $display("\nTest 5: Count minutes");
        
        // Count to 5 minutes
        repeat(59) @(posedge i_Clock); // 1 minute
        check_time(4'b0000, 3'b000, 4'b0001, 3'b000, 4'b0000, 2'b00, "1 minute");
        
        repeat(59) @(posedge i_Clock); // 2 minutes
        check_time(4'b0000, 3'b000, 4'b0010, 3'b000, 4'b0000, 2'b00, "2 minutes");
        
        repeat(59) @(posedge i_Clock); // 3 minutes
        check_time(4'b0000, 3'b000, 4'b0011, 3'b000, 4'b0000, 2'b00, "3 minutes");
        
        repeat(59) @(posedge i_Clock); // 4 minutes
        check_time(4'b0000, 3'b000, 4'b0100, 3'b000, 4'b0000, 2'b00, "4 minutes");
        
        repeat(59) @(posedge i_Clock); // 5 minutes
        check_time(4'b0000, 3'b000, 4'b0101, 3'b000, 4'b0000, 2'b00, "5 minutes");
        
        // Test 6: Minutes overflow to hours
        $display("\nTest 6: Minutes overflow to hours");
        i_Enable_Count_Hour = 1;
        
        // Count to 59 minutes
        repeat(54 * 60) @(posedge i_Clock); // 54 more minutes
        check_time(4'b0000, 3'b000, 4'b1001, 3'b101, 4'b0000, 2'b00, "Count to 59 minutes");
        
        // Next minute should overflow to 1 hour
        repeat(60) @(posedge i_Clock);
        check_time(4'b0000, 3'b000, 4'b0000, 3'b000, 4'b0001, 2'b00, "Overflow to 1 hour");
        
        // Test 7: Count hours
        $display("\nTest 7: Count hours");
        
        // Count to 5 hours
        repeat(59 * 60) @(posedge i_Clock); // 1 hour
        check_time(4'b0000, 3'b000, 4'b0000, 3'b000, 4'b0001, 2'b00, "1 hour");
        
        repeat(59 * 60) @(posedge i_Clock); // 2 hours
        check_time(4'b0000, 3'b000, 4'b0000, 3'b000, 4'b0010, 2'b00, "2 hours");
        
        repeat(59 * 60) @(posedge i_Clock); // 3 hours
        check_time(4'b0000, 3'b000, 4'b0000, 3'b000, 4'b0011, 2'b00, "3 hours");
        
        // Test 8: Hours overflow (23:59:59 -> 00:00:00)
        $display("\nTest 8: Hours overflow (23:59:59 -> 00:00:00)");
        
        // Count to 23:59:59
        repeat(20 * 60 * 60) @(posedge i_Clock); // 20 more hours
        check_time(4'b0000, 3'b000, 4'b0000, 3'b000, 4'b0011, 2'b10, "23 hours");
        
        // Count to 23:59:59
        repeat(59 * 60) @(posedge i_Clock); // 59 minutes
        check_time(4'b0000, 3'b000, 4'b1001, 3'b101, 4'b0011, 2'b10, "23:59:00");
        
        repeat(59) @(posedge i_Clock); // 59 seconds
        check_time(4'b1001, 3'b101, 4'b1001, 3'b101, 4'b0011, 2'b10, "23:59:59");
        
        // Next second should overflow to 00:00:00
        @(posedge i_Clock);
        check_time(4'b0000, 3'b000, 4'b0000, 3'b000, 4'b0000, 2'b00, "Overflow to 00:00:00");
        
        // Test 9: Manual increment mode
        $display("\nTest 9: Manual increment mode");
        
        // Reset to known state
        i_Reset_Sec = 1;
        @(posedge i_Clock);
        i_Reset_Sec = 0;
        @(posedge i_Clock);
        
        // Enable manual increment
        i_Enable_Increment = 1;
        i_Enable_Count_Sec = 0;
        i_Enable_Count_Min = 1;
        i_Enable_Count_Hour = 1;
        
        // Increment minutes
        @(posedge i_Clock);
        check_time(4'b0000, 3'b000, 4'b0001, 3'b000, 4'b0000, 2'b00, "Manual increment - 1 minute");
        
        @(posedge i_Clock);
        check_time(4'b0000, 3'b000, 4'b0010, 3'b000, 4'b0000, 2'b00, "Manual increment - 2 minutes");
        
        // Increment hours
        i_Enable_Count_Min = 0;
        i_Enable_Count_Hour = 1;
        
        @(posedge i_Clock);
        check_time(4'b0000, 3'b000, 4'b0010, 3'b000, 4'b0001, 2'b00, "Manual increment - 1 hour");
        
        @(posedge i_Clock);
        check_time(4'b0000, 3'b000, 4'b0010, 3'b000, 4'b0010, 2'b00, "Manual increment - 2 hours");
        
        // Test 10: Hours overflow in manual mode
        $display("\nTest 10: Hours overflow in manual mode");
        
        // Set to 23:00:00
        i_Reset_Sec = 1;
        @(posedge i_Clock);
        i_Reset_Sec = 0;
        @(posedge i_Clock);
        
        // Count to 23 hours manually
        for (integer i = 0; i < 23; i = i + 1) begin
            @(posedge i_Clock);
        end
        check_time(4'b0000, 3'b000, 4'b0000, 3'b000, 4'b0011, 2'b10, "Manual count to 23 hours");
        
        // Next increment should overflow to 0
        @(posedge i_Clock);
        check_time(4'b0000, 3'b000, 4'b0000, 3'b000, 4'b0000, 2'b00, "Manual overflow to 0 hours");
        
        // Test 11: Complex time sequences
        $display("\nTest 11: Complex time sequences");
        
        // Reset and count normally
        i_Reset_Sec = 1;
        i_Enable_Increment = 0;
        i_Enable_Count_Sec = 1;
        i_Enable_Count_Min = 1;
        i_Enable_Count_Hour = 1;
        @(posedge i_Clock);
        i_Reset_Sec = 0;
        
        // Count to 12:34:56
        repeat(12 * 60 * 60 + 34 * 60 + 56) @(posedge i_Clock);
        check_time(4'b0110, 3'b101, 4'b0100, 3'b011, 4'b0010, 2'b01, "Count to 12:34:56");
        
        // Test 12: Edge cases
        $display("\nTest 12: Edge cases");
        
        // Test with all enables off
        i_Enable_Count_Sec = 0;
        i_Enable_Count_Min = 0;
        i_Enable_Count_Hour = 0;
        repeat(100) @(posedge i_Clock);
        check_time(4'b0110, 3'b101, 4'b0100, 3'b011, 4'b0010, 2'b01, "All enables off - should not change");
        
        // Test with only seconds enabled
        i_Enable_Count_Sec = 1;
        repeat(10) @(posedge i_Clock);
        check_time(4'b0000, 3'b110, 4'b0100, 3'b011, 4'b0010, 2'b01, "Only seconds enabled");
        
        // Final summary
        $display("\n=====================================");
        $display("Test Summary:");
        $display("Total tests: %d", test_count);
        $display("Errors: %d", error_count);
        if (error_count == 0) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("SOME TESTS FAILED!");
        end
        $display("=====================================");
        
        $finish;
    end
    
    // Monitor for debugging
    initial begin
        $monitor("Time: %t, Reset: %b, Inc: %b, En_Sec: %b, En_Min: %b, En_Hour: %b, Time: %02d:%02d:%02d", 
                $time, i_Reset_Sec, i_Enable_Increment, i_Enable_Count_Sec, i_Enable_Count_Min, i_Enable_Count_Hour,
                {o_Tens_Hour, o_Units_Hour}, {o_Tens_Min, o_Units_Min}, {o_Tens_Sec, o_Units_Sec});
    end
    
    // Timeout to prevent infinite simulation
    initial begin
        #10000000; // 10ms timeout
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
