`timescale 1ns/1ps

module counter_tb;

    // Testbench signals
    reg         i_Clock;
    reg         i_Reset;
    reg         i_Enable_Count;
    wire [3:0]  o_Data;
    wire        o_Carry;
    
    // Clock generation
    parameter CLOCK_PERIOD = 10; // 10ns period = 100MHz
    
    initial begin
        i_Clock = 0;
        forever #(CLOCK_PERIOD/2) i_Clock = ~i_Clock;
    end
    
    // Instantiate the module under test
    counter #(
        .c_WIDTH(4),
        .c_RESET_VALUE(4'b1111)
    ) uut (
        .i_Clock(i_Clock),
        .i_Reset(i_Reset),
        .i_Enable_Count(i_Enable_Count),
        .o_Data(o_Data),
        .o_Carry(o_Carry)
    );
    
    // Test variables
    integer test_count = 0;
    integer error_count = 0;
    
    // Task to check expected output
    task check_output;
        input [3:0] expected_data;
        input expected_carry;
        input [255:0] test_name;
        begin
            test_count = test_count + 1;
            if (o_Data !== expected_data || o_Carry !== expected_carry) begin
                $display("ERROR: %s - Expected Data: %b, Got: %b, Expected Carry: %b, Got: %b at time %t", 
                        test_name, expected_data, o_Data, expected_carry, o_Carry, $time);
                error_count = error_count + 1;
            end else begin
                $display("PASS: %s - Data: %b, Carry: %b at time %t", 
                        test_name, o_Data, o_Carry, $time);
            end
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("Starting counter testbench...");
        $display("=====================================");
        
        // Initialize VCD dump
        $dumpfile("tests/counter_tb.vcd");
        $dumpvars(0, counter_tb);
        
        // Initialize inputs
        i_Reset = 0;
        i_Enable_Count = 0;
        
        // Wait for initial reset
        repeat(5) @(posedge i_Clock);
        
        // Test 1: Reset functionality
        $display("\nTest 1: Reset functionality");
        i_Reset = 1;
        @(posedge i_Clock);
        check_output(4'b0000, 1'b0, "Reset active - should be 0");
        
        i_Reset = 0;
        @(posedge i_Clock);
        check_output(4'b0000, 1'b0, "Reset released - should stay 0");
        
        // Test 2: Basic counting
        $display("\nTest 2: Basic counting");
        i_Enable_Count = 1;
        
        repeat(5) @(posedge i_Clock);
        check_output(4'b0101, 1'b0, "Count to 5");
        
        repeat(5) @(posedge i_Clock);
        check_output(4'b1010, 1'b0, "Count to 10");
        
        // Test 3: Counter overflow
        $display("\nTest 3: Counter overflow");
        // Count to 15 (0xF)
        repeat(5) @(posedge i_Clock);
        check_output(4'b1111, 1'b0, "Count to 15 (max value)");
        
        // Next count should wrap to 0 and generate carry
        @(posedge i_Clock);
        check_output(4'b0000, 1'b1, "Overflow to 0 with carry");
        
        // Test 4: Disable counting
        $display("\nTest 4: Disable counting");
        i_Enable_Count = 0;
        repeat(5) @(posedge i_Clock);
        check_output(4'b0000, 1'b0, "Disabled - should stay at 0");
        
        // Test 5: Re-enable counting
        $display("\nTest 5: Re-enable counting");
        i_Enable_Count = 1;
        repeat(3) @(posedge i_Clock);
        check_output(4'b0011, 1'b0, "Re-enabled - count to 3");
        
        // Test 6: Multiple overflows
        $display("\nTest 6: Multiple overflows");
        // Count to 15 again
        repeat(12) @(posedge i_Clock);
        check_output(4'b1111, 1'b0, "Count to 15 again");
        
        // Overflow
        @(posedge i_Clock);
        check_output(4'b0000, 1'b1, "Second overflow");
        
        // Count to 15 again
        repeat(15) @(posedge i_Clock);
        check_output(4'b1111, 1'b0, "Count to 15 third time");
        
        // Test 7: Reset during counting
        $display("\nTest 7: Reset during counting");
        repeat(3) @(posedge i_Clock);
        check_output(4'b0010, 1'b0, "Count to 2");
        
        i_Reset = 1;
        @(posedge i_Clock);
        check_output(4'b0000, 1'b0, "Reset during count - should go to 0");
        
        i_Reset = 0;
        @(posedge i_Clock);
        check_output(4'b0000, 1'b0, "Reset released - should stay 0");
        
        // Test 8: Enable/disable toggle
        $display("\nTest 8: Enable/disable toggle");
        i_Enable_Count = 1;
        @(posedge i_Clock);
        check_output(4'b0001, 1'b0, "Enable - count to 1");
        
        i_Enable_Count = 0;
        @(posedge i_Clock);
        check_output(4'b0001, 1'b0, "Disable - should stay at 1");
        
        i_Enable_Count = 1;
        @(posedge i_Clock);
        check_output(4'b0010, 1'b0, "Re-enable - count to 2");
        
        // Test 9: Carry signal timing
        $display("\nTest 9: Carry signal timing");
        // Count to 14
        repeat(12) @(posedge i_Clock);
        check_output(4'b1110, 1'b0, "Count to 14 - no carry");
        
        // Count to 15
        @(posedge i_Clock);
        check_output(4'b1111, 1'b0, "Count to 15 - no carry yet");
        
        // Overflow with carry
        @(posedge i_Clock);
        check_output(4'b0000, 1'b1, "Overflow - carry should be high");
        
        // Next cycle - carry should be low
        @(posedge i_Clock);
        check_output(4'b0001, 1'b0, "Next cycle - carry should be low");
        
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
        $monitor("Time: %t, Reset: %b, Enable: %b, Data: %b, Carry: %b", 
                $time, i_Reset, i_Enable_Count, o_Data, o_Carry);
    end
    
    // Timeout to prevent infinite simulation
    initial begin
        #100000; // 100us timeout
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
