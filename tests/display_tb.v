`timescale 1ns/1ps

module display_tb;

    // Testbench signals
    reg  [1:0]  i_Select;
    reg  [3:0]  i_Enable_Digits;
    reg         i_Enable_Dot;
    reg  [3:0]  i_Data_Dig1;
    reg  [3:0]  i_Data_Dig2;
    reg  [3:0]  i_Data_Dig3;
    reg  [3:0]  i_Data_Dig4;
    wire [7:0]  o_Segments;
    wire [3:0]  o_Digits;
    
    // Instantiate the module under test
    display uut (
        .i_Select(i_Select),
        .i_Enable_Digits(i_Enable_Digits),
        .i_Enable_Dot(i_Enable_Dot),
        .i_Data_Dig1(i_Data_Dig1),
        .i_Data_Dig2(i_Data_Dig2),
        .i_Data_Dig3(i_Data_Dig3),
        .i_Data_Dig4(i_Data_Dig4),
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
    
    // Task to check expected output
    task check_output;
        input [7:0] expected_segments_full;
        input [3:0] expected_digits;
        input [255:0] test_name;
        begin
            test_count = test_count + 1;
            if (o_Segments !== expected_segments_full || o_Digits !== expected_digits) begin
                $display("ERROR: %s - Expected Segments: %b, Got: %b, Expected Digits: %b, Got: %b at time %t", 
                        test_name, expected_segments_full, o_Segments, expected_digits, o_Digits, $time);
                error_count = error_count + 1;
            end else begin
                $display("PASS: %s - Segments: %b, Digits: %b at time %t", 
                        test_name, o_Segments, o_Digits, $time);
            end
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("Starting display testbench...");
        $display("=====================================");
        
        // Initialize VCD dump
        $dumpfile("tests/display_tb.vcd");
        $dumpvars(0, display_tb);
        
        // Initialize inputs
        i_Select = 2'b00;
        i_Enable_Digits = 4'b0000;
        i_Enable_Dot = 1'b0;
        i_Data_Dig1 = 4'b0000;
        i_Data_Dig2 = 4'b0000;
        i_Data_Dig3 = 4'b0000;
        i_Data_Dig4 = 4'b0000;
        
        // Wait for initial setup
        #10;
        
        // Test 1: All digits disabled
        $display("\nTest 1: All digits disabled");
        i_Enable_Digits = 4'b0000;
        i_Select = 2'b00;
        i_Data_Dig1 = 4'b0001;
        #10;
        check_output(8'b0000_0000, 4'b0000, "All digits disabled");
        
        // Test 2: Digit 1 enabled, display 0
        $display("\nTest 2: Digit 1 enabled, display 0");
        i_Enable_Digits = 4'b1000;
        i_Select = 2'b00;
        i_Data_Dig1 = 4'b0000;
        #10;
        check_output({1'b0, expected_segments[0]}, 4'b0001, "Digit 1 shows 0");
        
        // Test 3: All digits 0-9
        $display("\nTest 3: All digits 0-9");
        i_Enable_Digits = 4'b1000;
        i_Select = 2'b00;
        
        for (integer i = 0; i < 10; i = i + 1) begin
            i_Data_Dig1 = i[3:0];
            #10;
            check_output({1'b0, expected_segments[i]}, 4'b0001, "Digit 1 shows digit");
        end
        
        // Test 4: All 4 digits with different values
        $display("\nTest 4: All 4 digits with different values");
        i_Data_Dig1 = 4'b0001; // 1
        i_Data_Dig2 = 4'b0010; // 2
        i_Data_Dig3 = 4'b0011; // 3
        i_Data_Dig4 = 4'b0100; // 4
        
        // Test digit 1
        i_Select = 2'b00;
        i_Enable_Digits = 4'b1000;
        #10;
        check_output({1'b0, expected_segments[1]}, 4'b0001, "Digit 1 shows 1");
        
        // Test digit 2
        i_Select = 2'b01;
        i_Enable_Digits = 4'b0100;
        #10;
        check_output({1'b0, expected_segments[2]}, 4'b0010, "Digit 2 shows 2");
        
        // Test digit 3
        i_Select = 2'b10;
        i_Enable_Digits = 4'b0010;
        #10;
        check_output({1'b0, expected_segments[3]}, 4'b0100, "Digit 3 shows 3");
        
        // Test digit 4
        i_Select = 2'b11;
        i_Enable_Digits = 4'b0001;
        #10;
        check_output({1'b0, expected_segments[4]}, 4'b1000, "Digit 4 shows 4");
        
        // Test 5: Dot functionality
        $display("\nTest 5: Dot functionality");
        i_Select = 2'b01; // Select digit 2 (should show dot)
        i_Enable_Digits = 4'b0100;
        i_Enable_Dot = 1'b1;
        i_Data_Dig2 = 4'b0101; // 5
        #10;
        check_output({1'b1, expected_segments[5]}, 4'b0010, "Digit 2 shows 5 with dot");
        
        // Test dot on other digits (should not show)
        i_Select = 2'b00; // Select digit 1 (should not show dot)
        i_Enable_Digits = 4'b1000;
        i_Data_Dig1 = 4'b0101; // 5
        #10;
        check_output({1'b0, expected_segments[5]}, 4'b0001, "Digit 1 shows 5 without dot");
        
        // Test 6: Multiple digits enabled
        $display("\nTest 6: Multiple digits enabled");
        i_Select = 2'b00;
        i_Enable_Digits = 4'b1100; // Enable digits 1 and 2
        i_Data_Dig1 = 4'b0110; // 6
        #10;
        check_output({1'b0, expected_segments[6]}, 4'b0001, "Multiple digits enabled - only selected shows");
        
        // Test 7: Invalid digit values
        $display("\nTest 7: Invalid digit values");
        i_Select = 2'b00;
        i_Enable_Digits = 4'b1000;
        i_Data_Dig1 = 4'b1010; // Invalid value
        #10;
        check_output(8'b0000_0000, 4'b0001, "Invalid digit value - should show blank");
        
        i_Data_Dig1 = 4'b1111; // Another invalid value
        #10;
        check_output(8'b0000_0000, 4'b0001, "Another invalid digit value - should show blank");
        
        // Test 8: Edge cases
        $display("\nTest 8: Edge cases");
        
        // All digits enabled, select digit 4
        i_Select = 2'b11;
        i_Enable_Digits = 4'b1111;
        i_Data_Dig4 = 4'b1001; // 9
        #10;
        check_output({1'b0, expected_segments[9]}, 4'b1000, "All digits enabled, select digit 4");
        
        // No digits enabled
        i_Enable_Digits = 4'b0000;
        #10;
        check_output(8'b0000_0000, 4'b0000, "No digits enabled");
        
        // Test 9: Dot enable/disable
        $display("\nTest 9: Dot enable/disable");
        i_Select = 2'b01;
        i_Enable_Digits = 4'b0100;
        i_Data_Dig2 = 4'b0111; // 7
        
        i_Enable_Dot = 1'b0;
        #10;
        check_output({1'b0, expected_segments[7]}, 4'b0010, "Dot disabled");
        
        i_Enable_Dot = 1'b1;
        #10;
        check_output({1'b1, expected_segments[7]}, 4'b0010, "Dot enabled");
        
        // Test 10: Clock display simulation (like in real clock)
        $display("\nTest 10: Clock display simulation");
        i_Data_Dig1 = 4'b0010; // 2 (tens of hours)
        i_Data_Dig2 = 4'b0011; // 3 (units of hours)
        i_Data_Dig3 = 4'b0101; // 5 (tens of minutes)
        i_Data_Dig4 = 4'b0100; // 4 (units of minutes)
        
        // Simulate multiplexing through all digits
        for (integer sel = 0; sel < 4; sel = sel + 1) begin
            i_Select = sel[1:0];
            i_Enable_Digits = 4'b1111;
            #10;
            
            case (sel)
                0: check_output({1'b0, expected_segments[2]}, 4'b0001, "Clock digit 1 (tens hours)");
                1: check_output({1'b1, expected_segments[3]}, 4'b0010, "Clock digit 2 (units hours)");
                2: check_output({1'b0, expected_segments[5]}, 4'b0100, "Clock digit 3 (tens minutes)");
                3: check_output({1'b0, expected_segments[4]}, 4'b1000, "Clock digit 4 (units minutes)");
            endcase
        end
        
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
        $monitor("Time: %t, Select: %b, Enable_Digits: %b, Enable_Dot: %b, Data: %b %b %b %b, Segments: %b, Digits: %b", 
                $time, i_Select, i_Enable_Digits, i_Enable_Dot, 
                i_Data_Dig1, i_Data_Dig2, i_Data_Dig3, i_Data_Dig4,
                o_Segments, o_Digits);
    end
    
    // Timeout to prevent infinite simulation
    initial begin
        #10000; // 10us timeout
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
