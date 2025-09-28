package avry_tests_pkg;
  import uvm_pkg::*;
  import avry_env_pkg::*;          // env (sqr, drv, mon, cov)
  import avry_seq_pkg::*;          // avry_stimulus_flexible_base
  import scenario_config_pkg::*;   // scenarios from YAML (used by the sequence)
  `include "uvm_macros.svh"

  // Base test: builds env and runs the flexible sequence
  class avry_test_base extends uvm_test;
    `uvm_component_utils(avry_test_base)

    avry_env env;

    function new(string name="avry_test_base", uvm_component parent=null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = avry_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
      avry_stimulus_flexible_base seq;
      phase.raise_objection(this);
      seq = avry_stimulus_flexible_base::type_id::create("seq");
      seq.start(env.sqr);
      phase.drop_objection(this);
    endtask
  endclass

  // Five thin test shells (UVM-style, no initial blocks)
  class avry_test_reset_traffic     extends avry_test_base;
    `uvm_component_utils(avry_test_reset_traffic)
    function new(string n="avry_test_reset_traffic", uvm_component p=null); super.new(n,p); endfunction
  endclass

  class avry_test_parallel_viral    extends avry_test_base;
    `uvm_component_utils(avry_test_parallel_viral)
    function new(string n="avry_test_parallel_viral", uvm_component p=null); super.new(n,p); endfunction
  endclass

  class avry_test_reg_ops           extends avry_test_base;
    `uvm_component_utils(avry_test_reg_ops)
    function new(string n="avry_test_reg_ops", uvm_component p=null); super.new(n,p); endfunction
  endclass

  class avry_test_parallel_poll_bfm extends avry_test_base;
    `uvm_component_utils(avry_test_parallel_poll_bfm)
    function new(string n="avry_test_parallel_poll_bfm", uvm_component p=null); super.new(n,p); endfunction
  endclass

  class avry_test_full_protocol     extends avry_test_base;
    `uvm_component_utils(avry_test_full_protocol)
    function new(string n="avry_test_full_protocol", uvm_component p=null); super.new(n,p); endfunction
  endclass

endpackage

