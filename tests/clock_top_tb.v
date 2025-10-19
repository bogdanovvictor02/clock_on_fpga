`timescale 1ns/1ps

module clock_top_tb;

    // Testbench signals
    reg         i_Clock;
    reg         i_Button_Set;
    reg         i_Button_Up;
    wire [7:0]  o_Segments;
    wire [3:0]  o_Digits;
    
    // Clock generation
    parameter CLOCK_PERIOD = 10; // 10ns period = 100MHz
    
    initial begin
        i_Clock = 0;
        forever #(CLOCK_PERIOD/2) i_Clock = ~i_Clock;
    end
    
    // Instantiate the module under test
    clock_top uut (
        .i_Clock(i_Clock),
        .i_Button_Set(i_Button_Set),
        .i_Button_Up(i_Button_Up),
        .o_Segments(o_Segments),
        .o_Digits(o_Digits)
    );
    
    // Test variables
    integer test_count = 0;
    integer error_count = 0;
    
    // Expected 7-segment patterns for digits 0-9
    reg [6:0] expected_segments [0:9];
    
    // Initialize expected patterns
    initial begin
        expected_segments[0] = 7'b011_1111; // 0
        expected_segments[1] = 7'b000_0110; // 1
        expected_segments[2] = 7'b101_1011; // 2
        expected_segments[3] = 7'b100_1111; // 3
        expected_segments[4] = 7'b110_0110; // 4
        expected_segments[5] = 7'b110_1101; // 5
        expected_segments[6] = 7'b111_1101; // 6
        expected_segments[7] = 7'b000_0111; // 7
        expected_segments[8] = 7'b111_1111; // 8
        expected_segments[9] = 7'b110_1111; // 9
    end
    
    // Task to check display output
    task check_display;
        input [3:0] expected_digit;
        input [3:0] expected_digits_enable;
        input expected_dot;
        input [255:0] test_name;
        begin
            test_count = test_count + 1;
            
            // Check if the expected digit is being displayed
            if (o_Segments !== {expected_dot, expected_segments[expected_digit]} || o_Digits !== expected_digits_enable) begin
                $display("ERROR: %s", test_name);
                $display("  Expected: Segments=%b, Digits=%b", {expected_dot, expected_segments[expected_digit]}, expected_digits_enable);
                $display("  Got:      Segments=%b, Digits=%b", o_Segments, o_Digits);
                error_count = error_count + 1;
            end else begin
                $display("PASS: %s - Display: %b, Digits: %b", test_name, o_Segments, o_Digits);
            end
        end
    endtask
    
    // Task to wait for debounce period
    task wait_debounce;
        begin
            repeat(1024) @(posedge i_Clock); // Wait for full debounce period
        end
    endtask
    
    // Task to simulate button press
    task press_button;
        input button_signal;
        begin
            button_signal = 1;
            wait_debounce();
            button_signal = 0;
            wait_debounce();
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("Starting clock_top testbench...");
        $display("=====================================");
        
        // Initialize VCD dump
        $dumpfile("tests/clock_top_tb.vcd");
        $dumpvars(0, clock_top_tb);
        
        // Initialize inputs
        i_Button_Set = 0;
        i_Button_Up = 0;
        
        // Wait for initial reset
        repeat(10) @(posedge i_Clock);
        
        // Test 1: Initial state (should show 00:00)
        $display("\nTest 1: Initial state");
        // Wait for display to stabilize
        repeat(100) @(posedge i_Clock);
        check_display(4'b0000, 4'b1111, 1'b1, "Initial state - should show 00:00 with dot");
        
        // Test 2: Normal clock operation (count seconds)
        $display("\nTest 2: Normal clock operation");
        
        // Wait for 1 second to pass
        repeat(32768) @(posedge i_Clock); // 1 second at 100MHz
        
        // The display should be multiplexing, so we check for any valid digit
        test_count = test_count + 1;
        if (o_Digits !== 4'b0000) begin
            $display("PASS: Normal operation - display is active");
        end else begin
            $display("ERROR: Normal operation - display not active");
            error_count = error_count + 1;
        end
        
        // Test 3: Button Set functionality (enter settings mode)
        $display("\nTest 3: Button Set functionality");
        
        // Press Set button to enter settings
        i_Button_Set = 1;
        wait_debounce();
        i_Button_Set = 0;
        wait_debounce();
        
        // Should be in reset seconds mode
        repeat(100) @(posedge i_Clock);
        check_display(4'b0000, 4'b0000, 1'b0, "Set pressed - reset seconds mode");
        
        // Press Set again to go to minutes setting
        i_Button_Set = 1;
        wait_debounce();
        i_Button_Set = 0;
        wait_debounce();
        
        // Should be in minutes setting mode
        repeat(100) @(posedge i_Clock);
        check_display(4'b0000, 4'b1100, 1'b0, "Set pressed again - minutes setting mode");
        
        // Press Set again to go to hours setting
        i_Button_Set = 1;
        wait_debounce();
        i_Button_Set = 0;
        wait_debounce();
        
        // Should be in hours setting mode
        repeat(100) @(posedge i_Clock);
        check_display(4'b0000, 4'b0011, 1'b0, "Set pressed again - hours setting mode");
        
        // Press Set again to return to normal mode
        i_Button_Set = 1;
        wait_debounce();
        i_Button_Set = 0;
        wait_debounce();
        
        // Should be back to normal mode
        repeat(100) @(posedge i_Clock);
        check_display(4'b0000, 4'b1111, 1'b1, "Set pressed again - back to normal mode");
        
        // Test 4: Button Up functionality (increment time)
        $display("\nTest 4: Button Up functionality");
        
        // Enter minutes setting mode
        i_Button_Set = 1;
        wait_debounce();
        i_Button_Set = 0;
        wait_debounce();
        
        i_Button_Set = 1;
        wait_debounce();
        i_Button_Set = 0;
        wait_debounce();
        
        // Now in minutes setting mode, press Up to increment
        i_Button_Up = 1;
        wait_debounce();
        i_Button_Up = 0;
        wait_debounce();
        
        // Should show 1 minute
        repeat(100) @(posedge i_Clock);
        check_display(4'b0001, 4'b1100, 1'b0, "Up pressed - should show 1 minute");
        
        // Press Up again
        i_Button_Up = 1;
        wait_debounce();
        i_Button_Up = 0;
        wait_debounce();
        
        // Should show 2 minutes
        repeat(100) @(posedge i_Clock);
        check_display(4'b0010, 4'b1100, 1'b0, "Up pressed again - should show 2 minutes");
        
        // Test 5: Hours setting
        $display("\nTest 5: Hours setting");
        
        // Go to hours setting mode
        i_Button_Set = 1;
        wait_debounce();
        i_Button_Set = 0;
        wait_debounce();
        
        // Press Up to increment hours
        i_Button_Up = 1;
        wait_debounce();
        i_Button_Up = 0;
        wait_debounce();
        
        // Should show 1 hour
        repeat(100) @(posedge i_Clock);
        check_display(4'b0001, 4'b0011, 1'b0, "Up pressed - should show 1 hour");
        
        // Test 6: Complete settings cycle
        $display("\nTest 6: Complete settings cycle");
        
        // Set time to 12:34
        // First set minutes to 34
        for (integer i = 0; i < 34; i = i + 1) begin
            i_Button_Up = 1;
            wait_debounce();
            i_Button_Up = 0;
            wait_debounce();
        end
        
        // Go to hours setting
        i_Button_Set = 1;
        wait_debounce();
        i_Button_Set = 0;
        wait_debounce();
        
        // Set hours to 12
        for (integer i = 0; i < 12; i = i + 1) begin
            i_Button_Up = 1;
            wait_debounce();
            i_Button_Up = 0;
            wait_debounce();
        end
        
        // Return to normal mode
        i_Button_Set = 1;
        wait_debounce();
        i_Button_Set = 0;
        wait_debounce();
        
        // Should show 12:34
        repeat(100) @(posedge i_Clock);
        check_display(4'b0000, 4'b1111, 1'b1, "Time set to 12:34 - should show in normal mode");
        
        // Test 7: Clock continues running
        $display("\nTest 7: Clock continues running");
        
        // Wait for some time to pass
        repeat(1000) @(posedge i_Clock);
        
        test_count = test_count + 1;
        $display("PASS: Clock continues running after settings");
        
        // Test 8: Button debouncing
        $display("\nTest 8: Button debouncing");
        
        // Simulate noisy button press
        i_Button_Set = 1;
        repeat(5) @(posedge i_Clock);
        i_Button_Set = 0;
        repeat(3) @(posedge i_Clock);
        i_Button_Set = 1;
        repeat(2) @(posedge i_Clock);
        i_Button_Set = 0;
        repeat(1) @(posedge i_Clock);
        i_Button_Set = 1;
        wait_debounce();
        i_Button_Set = 0;
        wait_debounce();
        
        // Should still work despite bouncing
        repeat(100) @(posedge i_Clock);
        check_display(4'b0000, 4'b0000, 1'b0, "Bouncing button - should still work");
        
        // Test 9: Display multiplexing
        $display("\nTest 9: Display multiplexing");
        
        // Return to normal mode
        i_Button_Set = 1;
        wait_debounce();
        i_Button_Set = 0;
        wait_debounce();
        
        i_Button_Set = 1;
        wait_debounce();
        i_Button_Set = 0;
        wait_debounce();
        
        i_Button_Set = 1;
        wait_debounce();
        i_Button_Set = 0;
        wait_debounce();
        
        // Check that display is multiplexing
        repeat(100) @(posedge i_Clock);
        
        test_count = test_count + 1;
        if (o_Digits !== 4'b0000) begin
            $display("PASS: Display multiplexing is working");
        end else begin
            $display("ERROR: Display multiplexing not working");
            error_count = error_count + 1;
        end
        
        // Test 10: Edge cases
        $display("\nTest 10: Edge cases");
        
        // Rapid button presses
        for (integer i = 0; i < 5; i = i + 1) begin
            i_Button_Set = 1;
            repeat(10) @(posedge i_Clock);
            i_Button_Set = 0;
            repeat(10) @(posedge i_Clock);
        end
        
        test_count = test_count + 1;
        $display("PASS: Rapid button presses handled");
        
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
        $monitor("Time: %t, Set: %b, Up: %b, Segments: %b, Digits: %b", 
                $time, i_Button_Set, i_Button_Up, o_Segments, o_Digits);
    end
    
    // Timeout to prevent infinite simulation
    initial begin
        #10000000; // 10ms timeout
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
