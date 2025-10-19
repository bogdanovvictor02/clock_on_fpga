`timescale 1ns/1ps

module button_debounce_tb;

    // Testbench signals
    reg         i_Clock;
    reg         i_Button;
    wire        o_Released_Button;
    
    // Clock generation
    parameter CLOCK_PERIOD = 10; // 10ns period = 100MHz
    
    initial begin
        i_Clock = 0;
        forever #(CLOCK_PERIOD/2) i_Clock = ~i_Clock;
    end
    
    // Instantiate the module under test
    button_debounce uut (
        .i_Clock(i_Clock),
        .i_Button(i_Button),
        .o_Released_Button(o_Released_Button)
    );
    
    // Test variables
    integer test_count = 0;
    integer error_count = 0;
    
    // Task to check expected output
    task check_output;
        input expected;
        input [255:0] test_name;
        begin
            test_count = test_count + 1;
            if (o_Released_Button !== expected) begin
                $display("ERROR: %s - Expected: %b, Got: %b at time %t", 
                        test_name, expected, o_Released_Button, $time);
                error_count = error_count + 1;
            end else begin
                $display("PASS: %s - Output: %b at time %t", 
                        test_name, o_Released_Button, $time);
            end
        end
    endtask
    
    // Task to wait for debounce period
    task wait_debounce;
        begin
            repeat(1024) @(posedge i_Clock); // Wait for full debounce period
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("Starting button_debounce testbench...");
        $display("=====================================");
        
        // Initialize VCD dump
        $dumpfile("tests/button_debounce_tb.vcd");
        $dumpvars(0, button_debounce_tb);
        
        // Initialize inputs
        i_Button = 0;
        
        // Wait for initial reset
        repeat(5) @(posedge i_Clock);
        
        // Test 1: Normal button press and release
        $display("\nTest 1: Normal button press and release");
        i_Button = 1;
        wait_debounce();
        check_output(1'b0, "Button pressed - should not release");
        
        i_Button = 0;
        wait_debounce();
        check_output(1'b1, "Button released - should detect release");
        
        // Wait a bit after release
        repeat(10) @(posedge i_Clock);
        check_output(1'b0, "After release - should be low");
        
        // Test 2: Noisy button input (bouncing)
        $display("\nTest 2: Noisy button input (bouncing)");
        i_Button = 0;
        repeat(5) @(posedge i_Clock);
        
        // Simulate bouncing
        i_Button = 1;
        repeat(3) @(posedge i_Clock);
        i_Button = 0;
        repeat(2) @(posedge i_Clock);
        i_Button = 1;
        repeat(4) @(posedge i_Clock);
        i_Button = 0;
        repeat(1) @(posedge i_Clock);
        i_Button = 1;
        
        // Wait for debounce to settle
        wait_debounce();
        check_output(1'b0, "Bouncing button pressed - should not release");
        
        // Now release with some bouncing
        i_Button = 0;
        repeat(2) @(posedge i_Clock);
        i_Button = 1;
        repeat(1) @(posedge i_Clock);
        i_Button = 0;
        repeat(3) @(posedge i_Clock);
        i_Button = 1;
        repeat(1) @(posedge i_Clock);
        i_Button = 0;
        
        wait_debounce();
        check_output(1'b1, "Bouncing button released - should detect release");
        
        // Test 3: Very short button press (should not be detected)
        $display("\nTest 3: Very short button press");
        i_Button = 0;
        repeat(10) @(posedge i_Clock);
        
        i_Button = 1;
        repeat(100) @(posedge i_Clock); // Short press, less than debounce time
        i_Button = 0;
        
        wait_debounce();
        check_output(1'b0, "Short press - should not detect release");
        
        // Test 4: Multiple rapid presses
        $display("\nTest 4: Multiple rapid presses");
        i_Button = 0;
        repeat(10) @(posedge i_Clock);
        
        // First press
        i_Button = 1;
        wait_debounce();
        check_output(1'b0, "First press - should not release");
        
        i_Button = 0;
        wait_debounce();
        check_output(1'b1, "First release - should detect");
        
        repeat(5) @(posedge i_Clock);
        check_output(1'b0, "After first release - should be low");
        
        // Second press
        i_Button = 1;
        wait_debounce();
        check_output(1'b0, "Second press - should not release");
        
        i_Button = 0;
        wait_debounce();
        check_output(1'b1, "Second release - should detect");
        
        // Test 5: Button held for very long time
        $display("\nTest 5: Long button hold");
        i_Button = 0;
        repeat(10) @(posedge i_Clock);
        
        i_Button = 1;
        repeat(2000) @(posedge i_Clock); // Very long hold
        check_output(1'b0, "Long hold - should not release");
        
        i_Button = 0;
        wait_debounce();
        check_output(1'b1, "Release after long hold - should detect");
        
        // Test 6: Edge case - button starts high
        $display("\nTest 6: Button starts high");
        i_Button = 1;
        repeat(10) @(posedge i_Clock);
        check_output(1'b0, "Button starts high - should not release");
        
        i_Button = 0;
        wait_debounce();
        check_output(1'b1, "Release from high start - should detect");
        
        // Test 7: Counter overflow test
        $display("\nTest 7: Counter behavior at limit");
        i_Button = 0;
        repeat(10) @(posedge i_Clock);
        
        // Test counter behavior when button changes rapidly
        i_Button = 1;
        repeat(500) @(posedge i_Clock);
        i_Button = 0;
        repeat(100) @(posedge i_Clock);
        i_Button = 1;
        repeat(200) @(posedge i_Clock);
        i_Button = 0;
        
        wait_debounce();
        check_output(1'b1, "Complex sequence - should detect final release");
        
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
        $monitor("Time: %t, Button: %b, Released: %b", 
                $time, i_Button, o_Released_Button);
    end
    
    // Timeout to prevent infinite simulation
    initial begin
        #1000000; // 1ms timeout
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
