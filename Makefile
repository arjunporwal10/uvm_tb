# Simple VCS UVM-1.2 Makefile (POC)
VCS=vcs
UVM_OPTS=-full64 -sverilog -ntb_opts uvm-1.2 +vpi -debug_access+all
INCDIRS=+incdir+src/tb +incdir+src/tb/agent +incdir+src/tb/pkgs
TOP=src/tb/top.sv
SRCS=\
 src/dut/simple_bus_if.sv \
 src/dut/simple_dut.sv \
 src/tb/pkgs/avry_types_pkg.sv \
 src/tb/stimulus_auto_builder.sv \
 src/tb/pkgs/scenario_config_pkg.sv \
 src/tb/pkgs/action_executors_pkg.sv \
 src/tb/agent/avry_item.sv \
 src/tb/agent/avry_sequencer.sv \
 src/tb/coverage/avry_cov.sv \
 src/tb/avry_env.sv \
 src/tb/sequences/avry_stimulus_flexible_base.sv \
 src/tb/tests/avry_tests.sv \
 $(TOP)

all: simv

# At top, after variables
SCEN_PKG=src/tb/pkgs/scenario_config_pkg.sv

simv: $(SRCS) $(SCEN_PKG)
	$(VCS) $(UVM_OPTS) $(INCDIRS) $(SRCS) -o simv

$(SCEN_PKG): yaml/*.yaml tools/yaml2sv.py
	@echo "==> Generating scenario package from YAML"
	@python3 tools/yaml2sv.py ./yaml $(SCEN_PKG)


run: simv
	./simv +UVM_TESTNAME=$(TEST) +SCENARIO=$(SCEN) -l logs/$(TEST)_$(SCEN).log

# Run single test with scenario by name (see scenario_config_pkg)
one:
	mkdir -p logs
	$(MAKE) run TEST=$(TEST) SCEN=$(SCEN)

# Regression: run all 5 tests (names map to UVM tests) with default scenarios
regress: simv
	mkdir -p logs
	./simv +UVM_TESTNAME=avry_test_reset_traffic     +SCENARIO=reset_traffic     -l logs/reset_traffic.log
	./simv +UVM_TESTNAME=avry_test_parallel_viral    +SCENARIO=parallel_viral    -l logs/parallel_viral.log
	./simv +UVM_TESTNAME=avry_test_reg_ops           +SCENARIO=reg_ops           -l logs/reg_ops.log
	./simv +UVM_TESTNAME=avry_test_parallel_poll_bfm +SCENARIO=poll_bfm          -l logs/poll_bfm.log
	./simv +UVM_TESTNAME=avry_test_full_protocol     +SCENARIO=full_protocol     -l logs/full_protocol.log

# Generate coverage database (VCS URG)
cov:
	urg -dir simv.vdb -report cov_html

clean:
	rm -rf simv csrc simv.daidir ucli.key *.vpd *.fsdb *.vcd simv.vdb DVEfiles \
	       logs cov_html

