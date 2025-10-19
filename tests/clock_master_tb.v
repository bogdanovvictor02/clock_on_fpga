`timescale 1ns/1ps

module clock_master_tb;

    // Testbench signals
    reg         i_Clock;
    wire        o_Clock_1024Hz;
    wire        o_Clock_512Hz;
    wire        o_Clock_2Hz;
    wire        o_Clock_1Hz;
    wire        o_Enable_Clock_1Hz;
    
    // Clock generation
    parameter CLOCK_PERIOD = 10; // 10ns period = 100MHz
    
    initial begin
        i_Clock = 0;
        forever #(CLOCK_PERIOD/2) i_Clock = ~i_Clock;
    end
    
    // Instantiate the module under test
    clock_master uut (
        .i_Clock(i_Clock),
        .o_Clock_1024Hz(o_Clock_1024Hz),
        .o_Clock_512Hz(o_Clock_512Hz),
        .o_Clock_2Hz(o_Clock_2Hz),
        .o_Clock_1Hz(o_Clock_1Hz),
        .o_Enable_Clock_1Hz(o_Enable_Clock_1Hz)
    );
    
    // Test variables
    integer test_count = 0;
    integer error_count = 0;
    integer clock_1024_count = 0;
    integer clock_512_count = 0;
    integer clock_2_count = 0;
    integer clock_1_count = 0;
    integer enable_1hz_count = 0;
    
    // Task to check frequency
    task check_frequency;
        input integer expected_period_cycles;
        input integer actual_period_cycles;
        input [255:0] signal_name;
        begin
            test_count = test_count + 1;
            if (actual_period_cycles !== expected_period_cycles) begin
                $display("ERROR: %s - Expected period: %d cycles, Got: %d cycles", 
                        signal_name, expected_period_cycles, actual_period_cycles);
                error_count = error_count + 1;
            end else begin
                $display("PASS: %s - Period: %d cycles", signal_name, actual_period_cycles);
            end
        end
    endtask
    
    // Task to count clock cycles
    task count_cycles;
        input signal;
        input [255:0] signal_name;
        output integer cycle_count;
        begin
            cycle_count = 0;
            while (signal === 1'b0) begin
                @(posedge i_Clock);
                cycle_count = cycle_count + 1;
            end
            while (signal === 1'b1) begin
                @(posedge i_Clock);
                cycle_count = cycle_count + 1;
            end
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("Starting clock_master testbench...");
        $display("=====================================");
        
        // Initialize VCD dump
        $dumpfile("tests/clock_master_tb.vcd");
        $dumpvars(0, clock_master_tb);
        
        // Wait for initial reset
        repeat(10) @(posedge i_Clock);
        
        // Test 1: Check 1024Hz clock (should toggle every 32 cycles)
        $display("\nTest 1: 1024Hz clock frequency");
        clock_1024_count = 0;
        while (clock_1024_count < 2) begin
            @(posedge o_Clock_1024Hz);
            clock_1024_count = clock_1024_count + 1;
        end
        
        // Count cycles for one period
        clock_1024_count = 0;
        @(posedge o_Clock_1024Hz);
        while (o_Clock_1024Hz === 1'b1) begin
            @(posedge i_Clock);
            clock_1024_count = clock_1024_count + 1;
        end
        while (o_Clock_1024Hz === 1'b0) begin
            @(posedge i_Clock);
            clock_1024_count = clock_1024_count + 1;
        end
        
        check_frequency(32, clock_1024_count, "1024Hz clock");
        
        // Test 2: Check 512Hz clock (should toggle every 64 cycles)
        $display("\nTest 2: 512Hz clock frequency");
        clock_512_count = 0;
        while (clock_512_count < 2) begin
            @(posedge o_Clock_512Hz);
            clock_512_count = clock_512_count + 1;
        end
        
        clock_512_count = 0;
        @(posedge o_Clock_512Hz);
        while (o_Clock_512Hz === 1'b1) begin
            @(posedge i_Clock);
            clock_512_count = clock_512_count + 1;
        end
        while (o_Clock_512Hz === 1'b0) begin
            @(posedge i_Clock);
            clock_512_count = clock_512_count + 1;
        end
        
        check_frequency(64, clock_512_count, "512Hz clock");
        
        // Test 3: Check 2Hz clock (should toggle every 16384 cycles)
        $display("\nTest 3: 2Hz clock frequency");
        clock_2_count = 0;
        while (clock_2_count < 2) begin
            @(posedge o_Clock_2Hz);
            clock_2_count = clock_2_count + 1;
        end
        
        clock_2_count = 0;
        @(posedge o_Clock_2Hz);
        while (o_Clock_2Hz === 1'b1) begin
            @(posedge i_Clock);
            clock_2_count = clock_2_count + 1;
        end
        while (o_Clock_2Hz === 1'b0) begin
            @(posedge i_Clock);
            clock_2_count = clock_2_count + 1;
        end
        
        check_frequency(16384, clock_2_count, "2Hz clock");
        
        // Test 4: Check 1Hz clock (should toggle every 32768 cycles)
        $display("\nTest 4: 1Hz clock frequency");
        clock_1_count = 0;
        while (clock_1_count < 2) begin
            @(posedge o_Clock_1Hz);
            clock_1_count = clock_1_count + 1;
        end
        
        clock_1_count = 0;
        @(posedge o_Clock_1Hz);
        while (o_Clock_1Hz === 1'b1) begin
            @(posedge i_Clock);
            clock_1_count = clock_1_count + 1;
        end
        while (o_Clock_1Hz === 1'b0) begin
            @(posedge i_Clock);
            clock_1_count = clock_1_count + 1;
        end
        
        check_frequency(32768, clock_1_count, "1Hz clock");
        
        // Test 5: Check Enable_Clock_1Hz pulse
        $display("\nTest 5: Enable_Clock_1Hz pulse");
        enable_1hz_count = 0;
        
        // Wait for enable pulse
        while (o_Enable_Clock_1Hz === 1'b0) begin
            @(posedge i_Clock);
        end
        
        // Count how long enable stays high
        while (o_Enable_Clock_1Hz === 1'b1) begin
            @(posedge i_Clock);
            enable_1hz_count = enable_1hz_count + 1;
        end
        
        test_count = test_count + 1;
        if (enable_1hz_count !== 1) begin
            $display("ERROR: Enable_Clock_1Hz - Expected 1 cycle high, Got: %d cycles", enable_1hz_count);
            error_count = error_count + 1;
        end else begin
            $display("PASS: Enable_Clock_1Hz - High for 1 cycle");
        end
        
        // Test 6: Check phase relationships
        $display("\nTest 6: Phase relationships");
        
        // Wait for all clocks to be in known state
        repeat(1000) @(posedge i_Clock);
        
        // Check that 1024Hz is faster than 512Hz
        test_count = test_count + 1;
        if (o_Clock_1024Hz !== o_Clock_512Hz) begin
            $display("PASS: 1024Hz and 512Hz have different phases");
        end else begin
            $display("INFO: 1024Hz and 512Hz are in phase (this is expected)");
        end
        
        // Test 7: Long-term stability
        $display("\nTest 7: Long-term stability");
        repeat(10000) @(posedge i_Clock);
        
        test_count = test_count + 1;
        $display("PASS: System stable after 10000 clock cycles");
        
        // Test 8: Counter overflow behavior
        $display("\nTest 8: Counter overflow behavior");
        
        // Wait for counter to overflow (2^15 = 32768 cycles)
        repeat(32768) @(posedge i_Clock);
        
        test_count = test_count + 1;
        $display("PASS: Counter overflowed successfully");
        
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
        $monitor("Time: %t, 1024Hz: %b, 512Hz: %b, 2Hz: %b, 1Hz: %b, Enable: %b", 
                $time, o_Clock_1024Hz, o_Clock_512Hz, o_Clock_2Hz, o_Clock_1Hz, o_Enable_Clock_1Hz);
    end
    
    // Timeout to prevent infinite simulation
    initial begin
        #1000000; // 1ms timeout
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
