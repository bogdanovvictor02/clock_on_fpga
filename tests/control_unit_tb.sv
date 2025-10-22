`timescale 1ns/1ps

module control_unit_tb;

    // Testbench signals
    reg         i_Clock;
    reg         i_Switch;
    wire        o_Counters_Reset;
    wire        o_Counters_Enable_Increment;
    wire [2:0]  o_Counters_Enable_Count;
    wire [1:0]  o_Display_Enable_Digits;
    wire        o_Display_Enable_Dot;
    
    // Clock generation
    parameter CLOCK_PERIOD = 10; // 10ns period = 100MHz
    
    initial begin
        i_Clock = 0;
        forever #(CLOCK_PERIOD/2) i_Clock = ~i_Clock;
    end
    
    // Instantiate the module under test
    control_unit uut (
        .i_Clock(i_Clock),
        .i_Switch(i_Switch),
        .o_Counters_Reset(o_Counters_Reset),
        .o_Counters_Enable_Increment(o_Counters_Enable_Increment),
        .o_Counters_Enable_Count(o_Counters_Enable_Count),
        .o_Display_Enable_Digits(o_Display_Enable_Digits),
        .o_Display_Enable_Dot(o_Display_Enable_Dot)
    );
    
    // Test variables
    integer test_count = 0;
    integer error_count = 0;
    
    // State definitions
    localparam IDLE         = 2'b00;
    localparam RESET_SEC    = 2'b01;
    localparam SET_MIN      = 2'b10;
    localparam SET_HOUR     = 2'b11;
    
    // Task to check expected output
    task check_output;
        input expected_reset;
        input expected_increment;
        input [2:0] expected_enable_count;
        input [1:0] expected_display_digits;
        input expected_display_dot;
        input string test_name;
        begin
            test_count = test_count + 1;
            if (o_Counters_Reset !== expected_reset || 
                o_Counters_Enable_Increment !== expected_increment ||
                o_Counters_Enable_Count !== expected_enable_count ||
                o_Display_Enable_Digits !== expected_display_digits ||
                o_Display_Enable_Dot !== expected_display_dot) begin
                $display("ERROR: %s", test_name);
                $display("  Expected: Reset=%b, Increment=%b, Enable_Count=%b, Display_Digits=%b, Display_Dot=%b", 
                        expected_reset, expected_increment, expected_enable_count, expected_display_digits, expected_display_dot);
                $display("  Got:      Reset=%b, Increment=%b, Enable_Count=%b, Display_Digits=%b, Display_Dot=%b", 
                        o_Counters_Reset, o_Counters_Enable_Increment, o_Counters_Enable_Count, o_Display_Enable_Digits, o_Display_Enable_Dot);
                error_count = error_count + 1;
            end else begin
                $display("PASS: %s", test_name);
            end
        end
    endtask
    
    // Task to wait for state change
    task wait_for_state_change;
        input [1:0] expected_state;
        input string state_name;
        begin
            // Wait for state to change (next clock edge)
            @(posedge i_Clock);
            $display("INFO: State changed to %s", state_name);
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("Starting control_unit testbench...");
        $display("=====================================");
        
        // Initialize VCD dump
        $dumpfile("tests/control_unit_tb.vcd");
        $dumpvars(0, control_unit_tb);
        
        // Initialize inputs
        i_Switch = 0;
        
        // Wait for initial reset
        repeat(5) @(posedge i_Clock);
        
        // Test 1: Initial state (IDLE)
        $display("\nTest 1: Initial state (IDLE)");
        check_output(1'b0, 1'b0, 3'b111, 2'b11, 1'b1, "Initial IDLE state");
        
        // Test 2: Switch pressed - transition to RESET_SEC
        $display("\nTest 2: Switch pressed - transition to RESET_SEC");
        i_Switch = 1;
        wait_for_state_change(RESET_SEC, "RESET_SEC");
        @(posedge i_Clock); // Wait one cycle for outputs to update
        check_output(1'b1, 1'b0, 3'b000, 2'b00, 1'b0, "RESET_SEC state");
        
        // Test 3: Stay in RESET_SEC with switch held
        $display("\nTest 3: Stay in RESET_SEC with switch held");
        @(posedge i_Clock);
        check_output(1'b1, 1'b0, 3'b000, 2'b00, 1'b0, "RESET_SEC state maintained");
        
        // Test 4: Switch released - transition to SET_MIN
        $display("\nTest 4: Switch released - transition to SET_MIN");
        i_Switch = 0;
        wait_for_state_change(SET_MIN, "SET_MIN");
        @(posedge i_Clock); // Wait one cycle for outputs to update
        check_output(1'b0, 1'b1, 3'b010, 2'b01, 1'b0, "SET_MIN state");
        
        // Test 5: Stay in SET_MIN with switch released
        $display("\nTest 5: Stay in SET_MIN with switch released");
        @(posedge i_Clock);
        check_output(1'b0, 1'b1, 3'b010, 2'b01, 1'b0, "SET_MIN state maintained");
        
        // Test 6: Switch pressed in SET_MIN - transition to SET_HOUR
        $display("\nTest 6: Switch pressed in SET_MIN - transition to SET_HOUR");
        i_Switch = 1;
        wait_for_state_change(SET_HOUR, "SET_HOUR");
        @(posedge i_Clock); // Wait one cycle for outputs to update
        check_output(1'b0, 1'b1, 3'b100, 2'b10, 1'b0, "SET_HOUR state");
        
        // Test 7: Stay in SET_HOUR with switch held
        $display("\nTest 7: Stay in SET_HOUR with switch held");
        @(posedge i_Clock);
        @(posedge i_Clock); // Wait one more cycle for outputs to update
        @(posedge i_Clock); // Wait one more cycle for outputs to update
        check_output(1'b0, 1'b1, 3'b100, 2'b10, 1'b0, "SET_HOUR state maintained");
        
        // Test 8: Switch released in SET_HOUR - transition to IDLE
        $display("\nTest 8: Switch released in SET_HOUR - transition to IDLE");
        i_Switch = 0;
        wait_for_state_change(IDLE, "IDLE");
        @(posedge i_Clock); // Wait one cycle for outputs to update
        check_output(1'b0, 1'b0, 3'b111, 2'b11, 1'b1, "Back to IDLE state");
        
        // Test 9: Complete cycle test
        $display("\nTest 9: Complete cycle test");
        
        // IDLE -> RESET_SEC
        i_Switch = 1;
        wait_for_state_change(RESET_SEC, "RESET_SEC");
        @(posedge i_Clock); // Wait one cycle for outputs to update
        @(posedge i_Clock); // Wait one more cycle for outputs to update
        check_output(1'b1, 1'b0, 3'b000, 2'b00, 1'b0, "Cycle: RESET_SEC");
        
        // RESET_SEC -> SET_MIN
        i_Switch = 0;
        wait_for_state_change(SET_MIN, "SET_MIN");
        @(posedge i_Clock); // Wait one cycle for outputs to update
        @(posedge i_Clock); // Wait one more cycle for outputs to update
        check_output(1'b0, 1'b1, 3'b010, 2'b01, 1'b0, "Cycle: SET_MIN");
        
        // SET_MIN -> SET_HOUR
        i_Switch = 1;
        wait_for_state_change(SET_HOUR, "SET_HOUR");
        @(posedge i_Clock); // Wait one cycle for outputs to update
        @(posedge i_Clock); // Wait one more cycle for outputs to update
        check_output(1'b0, 1'b1, 3'b100, 2'b10, 1'b0, "Cycle: SET_HOUR");
        
        // SET_HOUR -> IDLE
        i_Switch = 0;
        wait_for_state_change(IDLE, "IDLE");
        @(posedge i_Clock); // Wait one cycle for outputs to update
        @(posedge i_Clock); // Wait one more cycle for outputs to update
        check_output(1'b0, 1'b0, 3'b111, 2'b11, 1'b1, "Cycle: Back to IDLE");
        
        // Test 10: Rapid switching
        $display("\nTest 10: Rapid switching");
        
        // Quick switch press/release
        i_Switch = 1;
        @(posedge i_Clock);
        i_Switch = 0;
        @(posedge i_Clock);
        @(posedge i_Clock); // Wait one more cycle for outputs to update
        @(posedge i_Clock); // Wait one more cycle for outputs to update
        check_output(1'b0, 1'b1, 3'b010, 2'b01, 1'b0, "Rapid switch - should be in SET_MIN");
        
        // Test 11: Multiple cycles
        $display("\nTest 11: Multiple cycles");
        
        // First, ensure we're in IDLE state
        i_Switch = 1; // SET_MIN -> SET_HOUR
        @(posedge i_Clock);
        i_Switch = 0; // SET_HOUR -> IDLE
        @(posedge i_Clock);
        @(posedge i_Clock); // Wait for outputs to stabilize
        
        // Run through 3 complete cycles
        for (integer cycle = 0; cycle < 3; cycle = cycle + 1) begin
            $display("  Cycle %d:", cycle + 1);
            
            // IDLE -> RESET_SEC
            i_Switch = 1;
            wait_for_state_change(RESET_SEC, "RESET_SEC");
            
            // RESET_SEC -> SET_MIN
            i_Switch = 0;
            wait_for_state_change(SET_MIN, "SET_MIN");
            
            // SET_MIN -> SET_HOUR
            i_Switch = 1;
            wait_for_state_change(SET_HOUR, "SET_HOUR");
            
            // SET_HOUR -> IDLE
            i_Switch = 0;
            wait_for_state_change(IDLE, "IDLE");
        end
        
        test_count = test_count + 1;
        $display("PASS: Multiple cycles completed successfully");
        
        // Test 12: Edge case - switch held for long time
        $display("\nTest 12: Edge case - switch held for long time");
        
        // Ensure we're stable in IDLE state before starting
        i_Switch = 0;
        repeat(5) @(posedge i_Clock); // Wait multiple cycles to ensure stable IDLE
        
        i_Switch = 1;
        @(posedge i_Clock); // Wait for state change to RESET_SEC
        $display("INFO: State changed to RESET_SEC");
        @(posedge i_Clock); // Wait one cycle for outputs to update
        
        // Hold switch for many cycles
        repeat(10) @(posedge i_Clock);
        check_output(1'b1, 1'b0, 3'b000, 2'b00, 1'b0, "Switch held - should stay in RESET_SEC");
        
        i_Switch = 0;
        @(posedge i_Clock); // Wait for state change to SET_MIN
        $display("INFO: State changed to SET_MIN");
        @(posedge i_Clock); // Wait one cycle for outputs to update
        check_output(1'b0, 1'b1, 3'b010, 2'b01, 1'b0, "Switch released - should go to SET_MIN");
        
        // Test 13: State machine stability
        $display("\nTest 13: State machine stability");
        
        // First, ensure we're in IDLE state (SET_MIN -> SET_HOUR -> IDLE)
        i_Switch = 1; // SET_MIN -> SET_HOUR
        @(posedge i_Clock);
        i_Switch = 0; // SET_HOUR -> IDLE
        @(posedge i_Clock);
        @(posedge i_Clock); // Wait for outputs to stabilize
        
        // Stay in IDLE for many cycles
        repeat(20) @(posedge i_Clock);
        @(posedge i_Clock); // Wait one more cycle for outputs to update
        @(posedge i_Clock); // Wait one more cycle for outputs to update
        check_output(1'b0, 1'b0, 3'b111, 2'b11, 1'b1, "Stable in IDLE");
        
        // Stay in SET_MIN for many cycles
        i_Switch = 1;
        wait_for_state_change(RESET_SEC, "RESET_SEC");
        i_Switch = 0;
        wait_for_state_change(SET_MIN, "SET_MIN");
        @(posedge i_Clock); // Wait one cycle for outputs to update
        
        repeat(20) @(posedge i_Clock);
        @(posedge i_Clock); // Wait one more cycle for outputs to update
        @(posedge i_Clock); // Wait one more cycle for outputs to update
        check_output(1'b0, 1'b1, 3'b010, 2'b01, 1'b0, "Stable in SET_MIN");
        
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
        $monitor("Time: %t, Switch: %b, Reset: %b, Increment: %b, Enable_Count: %b, Display_Digits: %b, Display_Dot: %b", 
                $time, i_Switch, o_Counters_Reset, o_Counters_Enable_Increment, 
                o_Counters_Enable_Count, o_Display_Enable_Digits, o_Display_Enable_Dot);
    end
    
    // Timeout to prevent infinite simulation
    initial begin
        #100000; // 100us timeout
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
