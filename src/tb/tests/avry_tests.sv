package avry_tests_pkg;
  import uvm_pkg::*;
  import avry_types_pkg::*;            // avry_scenario_cfg, enums, action types
  import avry_env_pkg::*;              // env (sqr, drv, mon, cov)
  import avry_seq_pkg::*;              // avry_stimulus_flexible_base
  import scenario_config_pkg::*;       // get_scenario_by_name
  import stimulus_auto_builder_pkg::*; // build_* helpers
  `include "uvm_macros.svh"

  // --------------------------------------------------------------------------
  // Base test: builds env and runs the flexible sequence
  // --------------------------------------------------------------------------
  class avry_test_base extends uvm_test;
    `uvm_component_utils(avry_test_base)

    avry_env env;

    function new(string name="avry_test_base", uvm_component parent=null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      // Declarations FIRST (some tools require this)
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

  // --------------------------------------------------------------------------
  // Five thin test shells (UVM-style, no initial blocks)
  // --------------------------------------------------------------------------
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

  // --------------------------------------------------------------------------
  // Serial + Parallel combo test (programmatic)
  // --------------------------------------------------------------------------
  class avry_test_serial_parallel_combo extends avry_test_base;
    `uvm_component_utils(avry_test_serial_parallel_combo)

    function new(string n="avry_test_serial_parallel_combo", uvm_component p=null);
      super.new(n,p);
    endfunction

    function void build_phase(uvm_phase phase);
      // Declarations FIRST
      avry_scenario_cfg   cfg;
      stimulus_action_t   a_reset;
      stimulus_action_t   a_traf_wr_16;
      stimulus_action_t   a_viral;
      stimulus_action_t   a_parallel;
      stimulus_action_t   a_errinj;
      stimulus_action_t   a_traf_rd_16;
      stimulus_action_t   a_selfcheck;
      stimulus_action_t   serial_list[$];
      stimulus_action_t   a_serial;

      super.build_phase(phase);

      // Create cfg
      cfg = avry_scenario_cfg::type_id::create("scenario_cfg");
      cfg.scenario_name   = "serial_parallel_combo";
      cfg.scenario_id     = SCENARIO_FLEX_FLOW;
      cfg.timeout_value   = 10000;
      cfg.addr_base       = 32'h2000_0000;
      cfg.data_pattern    = 32'h55AA_33CC;
      cfg.num_packets     = 16;
      cfg.expected_interrupts.delete();
      cfg.demote_errors.delete();
      cfg.promote_errors.delete();

      // Build the nested Action List (use helpers)
      a_reset       = stimulus_auto_builder::build_reset();
      a_traf_wr_16  = stimulus_auto_builder::build_traffic(DIR_WRITE, 16);
      a_viral       = stimulus_auto_builder::build_viral();
      a_parallel    = stimulus_auto_builder::build_parallel('{a_traf_wr_16, a_viral});
      a_errinj      = stimulus_auto_builder::build_error();
      a_traf_rd_16  = stimulus_auto_builder::build_traffic(DIR_READ, 16);
      a_selfcheck   = stimulus_auto_builder::build_self_check();

      // Serial composition: RESET -> (WRITE || VIRAL) -> ERROR -> READ -> SELF_CHECK
      serial_list   = '{a_reset, a_parallel, a_errinj, a_traf_rd_16, a_selfcheck};
      a_serial      = stimulus_auto_builder::build_serial(serial_list);

      // Final action list for the scenario
      cfg.action_list.delete();
      cfg.action_list.push_back(a_serial);

      // Provide the scenario to the flexible sequence via config_db
      uvm_config_db#(avry_scenario_cfg)::set(this, "env.sqr.main_phase", "scenario_cfg", cfg);
    endfunction
  endclass

  // --------------------------------------------------------------------------
  // YAML-driven: serial_parallel_mix (pulled from scenario_config_pkg)
  // --------------------------------------------------------------------------
  class avry_test_serial_parallel_mix extends uvm_test;
    `uvm_component_utils(avry_test_serial_parallel_mix)

    avry_env env;

    function new(string name="avry_test_serial_parallel_mix", uvm_component parent=null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      // Declarations FIRST
      avry_scenario_cfg cfg;

      super.build_phase(phase);
      env = avry_env::type_id::create("env", this);

      // Pull the scenario built by YAML converter
      cfg = scenario_config_pkg::get_scenario_by_name("serial_parallel_mix");

      // Provide the scenario to the flexible sequence via config_db
      uvm_config_db#(avry_scenario_cfg)::set(this, "env.sqr.main_phase", "scenario_cfg", cfg);
    endfunction

    task run_phase(uvm_phase phase);
      avry_stimulus_flexible_base seq;
      phase.raise_objection(this);
      seq = avry_stimulus_flexible_base::type_id::create("seq");
      seq.start(env.sqr);
      phase.drop_objection(this);
    endtask
  endclass

endpackage

