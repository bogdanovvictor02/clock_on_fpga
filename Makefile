# Makefile for FPGA Clock Project Testbenches

# Simulator (change to your preferred simulator)
SIMULATOR = iverilog
VIEWER = gtkwave

# Directories
RTL_DIR = rtl
TEST_DIR = tests

# Source files
RTL_SOURCES = $(RTL_DIR)/button_debounce.v \
              $(RTL_DIR)/counter.v \
              $(RTL_DIR)/clock_master.v \
              $(RTL_DIR)/display.v \
              $(RTL_DIR)/control_unit.v \
              $(RTL_DIR)/clock_counters.v \
              $(RTL_DIR)/clock_top.v

# Testbench files
TESTBENCHES = $(TEST_DIR)/button_debounce_tb.v \
              $(TEST_DIR)/counter_tb.v \
              $(TEST_DIR)/clock_master_tb.v \
              $(TEST_DIR)/display_tb.v \
              $(TEST_DIR)/control_unit_tb.v \
              $(TEST_DIR)/clock_counters_tb.v \
              $(TEST_DIR)/clock_top_tb.v \
              $(TEST_DIR)/integration_test.v

# Output files
VVP_FILES = $(TESTBENCHES:.v=.vvp)
VCD_FILES = $(TESTBENCHES:.v=.vcd)

# Default target
all: test-all

# Run all tests
test-all: $(VVP_FILES)
	@echo "=========================================="
	@echo "Running all tests..."
	@echo "=========================================="
	@echo ""
	@total_tests=0; \
	total_errors=0; \
	failed_tests=""; \
	for vvp in $(VVP_FILES); do \
		echo "Running $$vvp..."; \
		echo "------------------------------------------"; \
		output=$$(COLUMNS=300 vvp $$vvp 2>&1); \
		echo "$$output"; \
		echo ""; \
		test_count=$$(echo "$$output" | grep -E "(Total tests|Tests run|Test count): [0-9]*" | grep -o "[0-9]*" | tail -1 || echo "0"); \
		error_count=$$(echo "$$output" | grep -E "(Errors|Error count): [0-9]*" | grep -o "[0-9]*" | tail -1 || echo "0"); \
		if [ "$$error_count" -gt 0 ] || echo "$$output" | grep -q "ERROR:"; then \
			failed_tests="$$failed_tests $$(basename $$vvp .vvp)"; \
		fi; \
		total_tests=$$((total_tests + test_count)); \
		total_errors=$$((total_errors + error_count)); \
	done; \
	echo "=========================================="; \
	echo "FINAL TEST SUMMARY"; \
	echo "=========================================="; \
	echo "Total tests run: $$total_tests"; \
	echo "Total errors found: $$total_errors"; \
	if [ "$$total_errors" -eq 0 ]; then \
		echo "Status: ALL TESTS PASSED! ✅"; \
	else \
		echo "Status: SOME TESTS FAILED! ❌"; \
		echo "Failed test files:$$failed_tests"; \
	fi; \
	echo "=========================================="

# Individual test targets
test-button: $(TEST_DIR)/button_debounce_tb.vvp
	vvp $(TEST_DIR)/button_debounce_tb.vvp

test-counter: $(TEST_DIR)/counter_tb.vvp
	vvp $(TEST_DIR)/counter_tb.vvp

test-clock-master: $(TEST_DIR)/clock_master_tb.vvp
	vvp $(TEST_DIR)/clock_master_tb.vvp

test-display: $(TEST_DIR)/display_tb.vvp
	vvp $(TEST_DIR)/display_tb.vvp

test-control: $(TEST_DIR)/control_unit_tb.vvp
	vvp $(TEST_DIR)/control_unit_tb.vvp

test-counters: $(TEST_DIR)/clock_counters_tb.vvp
	vvp $(TEST_DIR)/clock_counters_tb.vvp

test-top: $(TEST_DIR)/clock_top_tb.vvp
	vvp $(TEST_DIR)/clock_top_tb.vvp

test-top-verbose: $(TEST_DIR)/clock_top_tb.vvp
	@echo "Running clock_top test with monitoring..."
	@echo "=========================================="
	@COLUMNS=200 vvp $(TEST_DIR)/clock_top_tb.vvp +monitor

test-integration: $(TEST_DIR)/integration_test.vvp
	vvp $(TEST_DIR)/integration_test.vvp

test-integration-verbose: $(TEST_DIR)/integration_test.vvp
	@echo "Running integration test with monitoring (wide output)..."
	@echo "Terminal width: $$(tput cols) columns"
	@echo "=========================================="
	@COLUMNS=200 vvp $(TEST_DIR)/integration_test.vvp +monitor

test-integration-wide: $(TEST_DIR)/integration_test.vvp
	@echo "Running integration test with very wide monitoring..."
	@echo "=========================================="
	@COLUMNS=300 vvp $(TEST_DIR)/integration_test.vvp +monitor | cat

test-integration-custom: $(TEST_DIR)/integration_test.vvp
	@echo "Running integration test with custom width monitoring..."
	@echo "Usage: make test-integration-custom WIDTH=400"
	@echo "Default width: 200 columns"
	@echo "=========================================="
	@COLUMNS=$${WIDTH:-200} vvp $(TEST_DIR)/integration_test.vvp +monitor | cat

# Compile all testbenches
$(VVP_FILES): %.vvp: %.v $(RTL_SOURCES)
	$(SIMULATOR) -o $@ $< $(RTL_SOURCES)

# Run simulation and generate VCD
wave-all: $(VVP_FILES)
	@echo "Running all tests with VCD generation..."
	@for vvp in $(VVP_FILES); do \
		echo "Running $$vvp with VCD..."; \
		vvp $$vvp +vcd; \
	done

# Run specific test with VCD
wave-button: $(TEST_DIR)/button_debounce_tb.vvp
	vvp $(TEST_DIR)/button_debounce_tb.vvp +vcd
	$(VIEWER) $(TEST_DIR)/button_debounce_tb.vcd &

wave-counter: $(TEST_DIR)/counter_tb.vvp
	vvp $(TEST_DIR)/counter_tb.vvp +vcd
	$(VIEWER) $(TEST_DIR)/counter_tb.vcd &

wave-clock-master: $(TEST_DIR)/clock_master_tb.vvp
	vvp $(TEST_DIR)/clock_master_tb.vvp +vcd
	$(VIEWER) $(TEST_DIR)/clock_master_tb.vcd &

wave-display: $(TEST_DIR)/display_tb.vvp
	vvp $(TEST_DIR)/display_tb.vvp +vcd
	$(VIEWER) $(TEST_DIR)/display_tb.vcd &

wave-control: $(TEST_DIR)/control_unit_tb.vvp
	vvp $(TEST_DIR)/control_unit_tb.vvp +vcd
	$(VIEWER) $(TEST_DIR)/control_unit_tb.vcd &

wave-counters: $(TEST_DIR)/clock_counters_tb.vvp
	vvp $(TEST_DIR)/clock_counters_tb.vvp +vcd
	$(VIEWER) $(TEST_DIR)/clock_counters_tb.vcd &

wave-top: $(TEST_DIR)/clock_top_tb.vvp
	vvp $(TEST_DIR)/clock_top_tb.vvp +vcd
	$(VIEWER) $(TEST_DIR)/clock_top_tb.vcd &

wave-integration: $(TEST_DIR)/integration_test.vvp
	vvp $(TEST_DIR)/integration_test.vvp +vcd
	$(VIEWER) $(TEST_DIR)/integration_test.vcd &

# Detailed error analysis
test-errors: $(VVP_FILES)
	@echo "=========================================="
	@echo "DETAILED ERROR ANALYSIS"
	@echo "=========================================="
	@for vvp in $(VVP_FILES); do \
		echo "Analyzing $$vvp..."; \
		echo "------------------------------------------"; \
		output=$$(COLUMNS=300 vvp $$vvp 2>&1); \
		error_count=$$(echo "$$output" | grep -E "(Errors|Error count): [0-9]*" | grep -o "[0-9]*" | tail -1 || echo "0"); \
		if [ "$$error_count" -gt 0 ]; then \
			echo "❌ FAILED - $$error_count errors found:"; \
			echo "$$output" | grep "ERROR:" | sed 's/.*ERROR: //'; \
		else \
			echo "✅ PASSED - No errors found"; \
		fi; \
		echo ""; \
	done

# Show detailed errors for a specific test
show-errors:
	@echo "Usage: make show-errors TEST=<test_name> [DETAILED=1]"
	@echo "Available tests: button_debounce_tb, counter_tb, clock_master_tb, display_tb, control_unit_tb, clock_counters_tb, clock_top_tb, integration_test"
	@if [ -z "$(TEST)" ]; then \
		echo "Please specify TEST parameter"; \
		exit 1; \
	fi
	@echo "Showing errors for $(TEST)..."
	@echo "=========================================="
	@if [ "$(DETAILED)" = "1" ]; then \
		COLUMNS=300 vvp tests/$(TEST).vvp 2>&1 | grep -A 2 -B 1 "ERROR:" | fold -w 200 -s; \
	else \
		COLUMNS=300 vvp tests/$(TEST).vvp 2>&1 | grep "ERROR:" | sed 's/.*ERROR: //'; \
	fi

# Clean generated files
clean:
	rm -f $(VVP_FILES) $(VCD_FILES)

# Help
help:
	@echo "Available targets:"
	@echo ""
	@echo "Test targets:"
	@echo "  test-all          - Run all tests with summary"
	@echo "  test-errors       - Detailed error analysis"
	@echo "  test-button       - Run button_debounce test"
	@echo "  test-counter      - Run counter test"
	@echo "  test-clock-master - Run clock_master test"
	@echo "  test-display      - Run display test"
	@echo "  test-control      - Run control_unit test"
	@echo "  test-counters     - Run clock_counters test"
	@echo "  test-top          - Run clock_top test"
	@echo "  test-top-verbose  - Run clock_top test with monitoring"
	@echo "  test-integration  - Run integration test"
	@echo "  test-integration-verbose - Run integration test with monitoring (200 cols)"
	@echo "  test-integration-wide - Run integration test with wide monitoring (300 cols)"
	@echo "  test-integration-custom - Run integration test with custom width (WIDTH=400)"
	@echo "  show-errors       - Show errors for specific test (DETAILED=1 for full details)"
	@echo ""
	@echo "Waveform targets:"
	@echo "  wave-all          - Run all tests with VCD generation"
	@echo "  wave-button       - Run button_debounce test with VCD"
	@echo "  wave-counter      - Run counter test with VCD"
	@echo "  wave-clock-master - Run clock_master test with VCD"
	@echo "  wave-display      - Run display test with VCD"
	@echo "  wave-control      - Run control_unit test with VCD"
	@echo "  wave-counters     - Run clock_counters test with VCD"
	@echo "  wave-top          - Run clock_top test with VCD"
	@echo "  wave-integration  - Run integration test with VCD"
	@echo ""
	@echo "Other targets:"
	@echo "  clean             - Remove generated files"
	@echo "  help              - Show this help message"

.PHONY: all test-all test-errors test-button test-counter test-clock-master test-display test-control test-counters test-top test-top-verbose test-integration test-integration-verbose test-integration-wide test-integration-custom show-errors wave-all wave-button wave-counter wave-clock-master wave-display wave-control wave-counters wave-top wave-integration clean help
