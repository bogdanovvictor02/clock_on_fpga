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
	@echo "Running all tests..."
	@for vvp in $(VVP_FILES); do \
		echo "Running $$vvp..."; \
		vvp $$vvp; \
		echo ""; \
	done

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

# Clean generated files
clean:
	rm -f $(VVP_FILES) $(VCD_FILES)

# Help
help:
	@echo "Available targets:"
	@echo ""
	@echo "Test targets:"
	@echo "  test-all          - Run all tests"
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

.PHONY: all test-all test-button test-counter test-clock-master test-display test-control test-counters test-top test-integration wave-all wave-button wave-counter wave-clock-master wave-display wave-control wave-counters wave-top wave-integration clean help
