# Proposed Maintenance Tasks

## Typo Fix
- **Issue**: The YAML scenario definition for `reset_traffic` sets `scenario_id` to `SCENARIO_REG_TRAFFIC`, which appears to be a misspelling (missing "SET") and does not match the intended reset-themed scenario naming used elsewhere.
- **Evidence**: `yaml/reset_traffic.yaml`, line 2.
- **Proposed Task**: Correct the typo by renaming the scenario identifier (e.g., `SCENARIO_RESET_TRAFFIC` or aligning it with the existing enum name) and ensure the downstream generator emits the fixed value.

## Bug Fix
- **Issue**: The DUT raises its interrupt based on the registered value of `bus.rdata`, so the comparison checks the previous cycle's read data instead of the data returned in the current cycle, causing missed interrupts.
- **Evidence**: `src/dut/simple_dut.sv`, lines 22-30.
- **Proposed Task**: Rework the interrupt generation logic to compare against the freshly read data (e.g., `mem[bus.raddr]` when a read is issued, or pipeline the compare alongside `rvalid`).

## Comment / Documentation Discrepancy
- **Issue**: The guidance in `top.sv` suggests invoking tests with a fully qualified `+UVM_TESTNAME=avry_tests_pkg::test`, but the provided Makefile and typical UVM usage expect the bare class name (e.g., `+UVM_TESTNAME=avry_test_reset_traffic`).
- **Evidence**: `src/tb/top.sv`, lines 33-34 and `Makefile`, lines 31-37.
- **Proposed Task**: Update the comment (and any related docs) to reflect the correct command-line syntax so users don't copy an invocation that will be rejected by the simulator.

## Test Improvement
- **Issue**: Each test shell simply starts `avry_stimulus_flexible_base` without ensuring the intended scenario is selected; if the `+SCENARIO` plusarg is omitted, all tests silently run the default `reset_traffic` scenario, reducing coverage.
- **Evidence**: `src/tb/tests/avry_tests.sv`, lines 20-28 and `src/tb/sequences/avry_stimulus_flexible_base.sv`, lines 24-29.
- **Proposed Task**: Enhance the tests to programmatically select or assert the expected scenario (for example, via configuration or sequence overrides) so each test reliably exercises its unique stimulus even without external plusargs.
