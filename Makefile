# Makefile for FPGA Clock Project Testbenches

# Simulator (change to your preferred simulator)
SIMULATOR = iverilog
VIEWER = gtkwave

# Directories
SRC_DIR = src
TEST_DIR = tests

# Source files
SRC_SOURCES = $(SRC_DIR)/button_debounce.v \
              $(SRC_DIR)/counter.v \
              $(SRC_DIR)/clock_master.v \
              $(SRC_DIR)/display.v \
              $(SRC_DIR)/control_unit.v \
              $(SRC_DIR)/clock_counters.v \
              $(SRC_DIR)/clock_top.v

# Testbench files
TESTBENCHES_V = $(TEST_DIR)/button_debounce_tb.v \
                $(TEST_DIR)/counter_tb.v \
                $(TEST_DIR)/clock_master_tb.v \
                $(TEST_DIR)/display_tb.v \
                $(TEST_DIR)/clock_counters_tb.v \
                $(TEST_DIR)/integration_test.v

TESTBENCHES_SV = $(TEST_DIR)/control_unit_tb.sv \
				 $(TEST_DIR)/clock_top_tb.sv

# Output files
VVP_FILES_V = $(TESTBENCHES_V:.v=.vvp)
VVP_FILES_SV = $(TESTBENCHES_SV:.sv=.vvp)
VVP_FILES = $(VVP_FILES_V) $(VVP_FILES_SV)

VCD_FILES_V = $(TESTBENCHES_V:.v=.vcd)
VCD_FILES_SV = $(TESTBENCHES_SV:.sv=.vcd)
VCD_FILES = $(VCD_FILES_V) $(VCD_FILES_SV)

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

test-integration: $(TEST_DIR)/integration_test.vvp
	vvp $(TEST_DIR)/integration_test.vvp

# Compile Verilog testbenches
$(VVP_FILES_V): %.vvp: %.v $(SRC_SOURCES)
	$(SIMULATOR) -o $@ $< $(SRC_SOURCES)

# Compile SystemVerilog testbenches
$(VVP_FILES_SV): %.vvp: %.sv $(SRC_SOURCES)
	$(SIMULATOR) -g2012 -o $@ $< $(SRC_SOURCES)

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
	@echo "  test-integration  - Run integration test"
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

.PHONY: all test-all test-errors test-button test-counter test-clock-master test-display test-control test-counters test-top test-integration wave-all wave-button wave-counter wave-clock-master wave-display wave-control wave-counters wave-top wave-integration clean help
