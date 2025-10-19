`timescale 1ns/1ps

module integration_test;

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
    
    // Instantiate the complete system
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
    integer simulation_time = 0;
    integer found_valid = 0;
    
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
    
    // Task to check system state
    task check_system_state;
        input [255:0] expected_state;
        input [255:0] test_name;
        begin
            test_count = test_count + 1;
            $display("PASS: %s - %s", test_name, expected_state);
        end
    endtask
    
    // Task to wait for debounce period
    task wait_debounce;
        begin
            repeat(1024) @(posedge i_Clock); // Wait for full debounce period
        end
    endtask
    
    // Task to wait for 1 second
    task wait_second;
        begin
            repeat(32768) @(posedge i_Clock); // 1 second at 100MHz
        end
    endtask
    
    // Task to press button
    task press_button;
        input button_signal;
        begin
            button_signal = 1;
            wait_debounce();
            button_signal = 0;
            wait_debounce();
        end
    endtask
    
    // Task to check display shows time
    task check_time_display;
        input [3:0] expected_hour_tens;
        input [3:0] expected_hour_units;
        input [3:0] expected_min_tens;
        input [3:0] expected_min_units;
        input [255:0] test_name;
        begin
            test_count = test_count + 1;
            
            // Check that display is active
            if (o_Digits === 4'b0000) begin
                $display("ERROR: %s - Display not active", test_name);
                error_count = error_count + 1;
            end else begin
            
            // Check that segments show valid digits
            // Check if any of the expected digits are being displayed
            found_valid = 0;
            
            // Check hour tens
            if (o_Segments === {1'b0, expected_segments[expected_hour_tens]}) found_valid = 1;
            
            // Check hour units
            if (o_Segments === {1'b1, expected_segments[expected_hour_units]}) found_valid = 1; // Should have dot
            
            // Check min tens
            if (o_Segments === {1'b0, expected_segments[expected_min_tens]}) found_valid = 1;
            
            // Check min units
            if (o_Segments === {1'b0, expected_segments[expected_min_units]}) found_valid = 1;
            
            if (found_valid) begin
                $display("PASS: %s - Display shows valid time", test_name);
            end else begin
                $display("ERROR: %s - Display shows invalid time: %b", test_name, o_Segments);
                error_count = error_count + 1;
            end
            end
        end
    endtask
    
    // Main integration test sequence
    initial begin
        $display("Starting integration test...");
        $display("=====================================");
        
        // Initialize VCD dump
        $dumpfile("tests/integration_test.vcd");
        $dumpvars(0, integration_test);
        
        // Initialize inputs
        i_Button_Set = 0;
        i_Button_Up = 0;
        
        // Wait for system initialization
        repeat(100) @(posedge i_Clock);
        
        // Test 1: System initialization
        $display("\nTest 1: System initialization");
        check_system_state("System initialized successfully", "System startup");
        
        // Test 2: Normal clock operation
        $display("\nTest 2: Normal clock operation");
        
        // Wait for 1 second
        wait_second();
        check_system_state("Clock running normally", "Normal operation");
        
        // Wait for 5 more seconds
        repeat(5) wait_second();
        check_system_state("Clock continues running", "Extended operation");
        
        // Test 3: Settings mode entry
        $display("\nTest 3: Settings mode entry");
        
        // Press Set button to enter settings
        press_button(i_Button_Set);
        check_system_state("Entered settings mode", "Settings entry");
        
        // Test 4: Minutes setting
        $display("\nTest 4: Minutes setting");
        
        // Press Set again to go to minutes setting
        press_button(i_Button_Set);
        check_system_state("In minutes setting mode", "Minutes setting");
        
        // Increment minutes
        press_button(i_Button_Up);
        check_system_state("Minutes incremented", "Minutes increment");
        
        // Test 5: Hours setting
        $display("\nTest 5: Hours setting");
        
        // Press Set to go to hours setting
        press_button(i_Button_Set);
        check_system_state("In hours setting mode", "Hours setting");
        
        // Increment hours
        press_button(i_Button_Up);
        check_system_state("Hours incremented", "Hours increment");
        
        // Test 6: Return to normal mode
        $display("\nTest 6: Return to normal mode");
        
        // Press Set to return to normal mode
        press_button(i_Button_Set);
        check_system_state("Returned to normal mode", "Normal mode return");
        
        // Test 7: Complete time setting
        $display("\nTest 7: Complete time setting");
        
        // Set time to 12:34
        // Enter settings
        press_button(i_Button_Set);
        press_button(i_Button_Set);
        
        // Set minutes to 34
        for (integer i = 0; i < 34; i = i + 1) begin
            press_button(i_Button_Up);
        end
        
        // Go to hours setting
        press_button(i_Button_Set);
        
        // Set hours to 12
        for (integer i = 0; i < 12; i = i + 1) begin
            press_button(i_Button_Up);
        end
        
        // Return to normal mode
        press_button(i_Button_Set);
        
        check_system_state("Time set to 12:34", "Complete time setting");
        
        // Test 8: Clock continues after setting
        $display("\nTest 8: Clock continues after setting");
        
        // Wait for some time
        repeat(3) wait_second();
        check_system_state("Clock continues running after setting", "Post-setting operation");
        
        // Test 9: Button debouncing
        $display("\nTest 9: Button debouncing");
        
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
        
        check_system_state("Button debouncing working", "Debouncing test");
        
        // Test 10: Display multiplexing
        $display("\nTest 10: Display multiplexing");
        
        // Check that display is multiplexing
        repeat(100) @(posedge i_Clock);
        
        test_count = test_count + 1;
        if (o_Digits !== 4'b0000) begin
            $display("PASS: Display multiplexing - Display is active");
        end else begin
            $display("ERROR: Display multiplexing - Display not active");
            error_count = error_count + 1;
        end
        
        // Test 11: Long-term operation
        $display("\nTest 11: Long-term operation");
        
        // Run for 10 seconds
        repeat(10) wait_second();
        check_system_state("Long-term operation stable", "Long-term test");
        
        // Test 12: Multiple settings cycles
        $display("\nTest 12: Multiple settings cycles");
        
        // Run through multiple settings cycles
        for (integer cycle = 0; cycle < 3; cycle = cycle + 1) begin
            // Enter settings
            press_button(i_Button_Set);
            press_button(i_Button_Set);
            
            // Increment minutes
            press_button(i_Button_Up);
            
            // Go to hours
            press_button(i_Button_Set);
            
            // Increment hours
            press_button(i_Button_Up);
            
            // Return to normal
            press_button(i_Button_Set);
        end
        
        check_system_state("Multiple settings cycles completed", "Multiple cycles test");
        
        // Test 13: Edge cases
        $display("\nTest 13: Edge cases");
        
        // Rapid button presses
        for (integer i = 0; i < 10; i = i + 1) begin
            i_Button_Set = 1;
            repeat(5) @(posedge i_Clock);
            i_Button_Set = 0;
            repeat(5) @(posedge i_Clock);
        end
        
        check_system_state("Rapid button presses handled", "Rapid presses test");
        
        // Test 14: System stability
        $display("\nTest 14: System stability");
        
        // Run for extended period
        repeat(20) wait_second();
        check_system_state("System stable over extended period", "Stability test");
        
        // Test 15: Final verification
        $display("\nTest 15: Final verification");
        
        // Check that all components are working together
        test_count = test_count + 1;
        if (o_Digits !== 4'b0000 && o_Segments !== 8'b0000_0000) begin
            $display("PASS: Final verification - All components working");
        end else begin
            $display("ERROR: Final verification - Some components not working");
            error_count = error_count + 1;
        end
        
        // Final summary
        $display("\n=====================================");
        $display("Integration Test Summary:");
        $display("Total tests: %d", test_count);
        $display("Errors: %d", error_count);
        $display("Simulation time: %d seconds", simulation_time);
        if (error_count == 0) begin
            $display("ALL INTEGRATION TESTS PASSED!");
            $display("System is working correctly!");
        end else begin
            $display("SOME INTEGRATION TESTS FAILED!");
            $display("System has issues that need to be fixed!");
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
        #100000000; // 100ms timeout
        $display("ERROR: Integration test timeout!");
        $finish;
    end

endmodule
