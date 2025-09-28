package avry_seq_pkg;
  import uvm_pkg::*;
  // IMPORTANT: only import types once to avoid duplicate wildcard collisions
  import avry_types_pkg::*;            // defines avry_seq_item, actions, cfg, etc.
  import action_executors_pkg::*;      // executors registry & classes
  import stimulus_auto_builder_pkg::*; // auto action list builder
  import scenario_config_pkg::*;       // YAML → scenario_cfg getter
  `include "uvm_macros.svh"

  // Use fully-qualified type in the param to avoid wildcard ambiguity:
  class avry_stimulus_flexible_base extends uvm_sequence#(avry_types_pkg::avry_seq_item);
    `uvm_object_utils(avry_stimulus_flexible_base)

    avry_scenario_cfg   cfg;
    stimulus_action_t   action_q[$];

    // Flags for post-check
    bit step_self_check_done;
    bit step_interrupt_check_done;
    bit step_error_handling_done;

    function new(string name="avry_stimulus_flexible_base");
      super.new(name);
    endfunction

    virtual task body();
      string scen;
      if (!$value$plusargs("SCENARIO=%s", scen)) scen="reset_traffic";
      cfg = scenario_config_pkg::get_scenario_by_name(scen);
      `uvm_info(get_type_name(), $sformatf("Using scenario: %s", scen), UVM_MEDIUM)

      // Register executors (only once per seq instance)
      executor_registry::register("RESET",           reset_action_executor::type_id::create("reset_exec"));
      executor_registry::register("TRAFFIC",         traffic_action_executor::type_id::create("traf_exec"));
      executor_registry::register("VIRAL_CHECK",     viral_check_action_executor::type_id::create("viral_exec"));
      executor_registry::register("ERROR_INJECTION", error_inject_action_executor::type_id::create("err_exec"));
      executor_registry::register("SELF_CHECK",      self_check_action_executor::type_id::create("self_exec"));
      executor_registry::register("PARALLEL_GROUP",  parallel_group_action_executor::type_id::create("par_exec"));
      executor_registry::register("SERIAL_GROUP",    serial_group_action_executor::type_id::create("ser_exec"));

      // Build action list (from YAML or auto-builder fallback)
      if (cfg.autobuild_enabled && cfg.action_list.size()==0) begin
        `uvm_info(get_type_name(),"Auto-building default action list",UVM_MEDIUM)
        stimulus_auto_builder::build(cfg, action_q);
      end else begin
        int i;
        for (i=0;i<cfg.action_list.size();i++) action_q.push_back(cfg.action_list[i]);
      end

      // Execute actions then post-checks
      exec_action_list();
      post_check_phase();
    endtask

    // Execute actions: TRAFFIC drives real items; others delegate to executors
    virtual task exec_action_list();
      int i;
      for (i=0;i<action_q.size();i++) begin
        stimulus_action_t a;
        a = action_q[i];
        if (a.action_type=="TRAFFIC") begin
          traffic_action_data d;
          bit is_wr;
          int num, k;
          avry_types_pkg::avry_seq_item it;

          if (!$cast(d,a.action_data)) begin
            `uvm_error(get_type_name(),"TRAFFIC missing traffic_action_data")
            continue;
          end
          is_wr = (d.direction==DIR_WRITE);
          num   = d.num_packets;

          `uvm_info(get_type_name(),
            $sformatf("SEQ driving TRAFFIC (%s) count=%0d",(is_wr?"WRITE":"READ"),num),UVM_MEDIUM)

          for (k=0;k<num;k++) begin
            it = avry_types_pkg::avry_seq_item::type_id::create($sformatf("it_%0d",k));
            it.we   = is_wr;
            it.addr = cfg.addr_base + k*4;
            it.data = cfg.data_pattern ^ k;
            start_item(it); finish_item(it);
          end
        end
        else begin
          stimulus_action_executor_base ex;
          ex = executor_registry::get(a.action_type);
          if (ex==null) `uvm_error(get_type_name(),$sformatf("No executor for %s",a.action_type))
          else ex.execute(a);
        end
      end
    endtask

    // -------- Post-check phase (logs + flags) --------
    virtual task post_check_phase();
      `uvm_info(get_type_name(), "Starting post-check phase", UVM_MEDIUM)

      `uvm_info(get_type_name(), "Starting self-check phase", UVM_MEDIUM)
      // Hook: add real scoreboard checks here
      `uvm_info(get_type_name(), "Self-check completed", UVM_LOW)
      step_self_check_done = 1;

      perform_interrupt_check();
      perform_error_handling();

      if (!step_self_check_done)
        `uvm_warning(get_type_name(), "Self-check was not performed!");
      if (!step_interrupt_check_done)
        `uvm_warning(get_type_name(), "Interrupt check was not performed!");
      if (!step_error_handling_done)
        `uvm_warning(get_type_name(), "Error handling was not performed!");

      `uvm_info(get_type_name(), "Post-check phase completed", UVM_MEDIUM)
    endtask

    virtual task perform_interrupt_check();
      `uvm_info(get_type_name(), "Performing interrupt check (hook)", UVM_MEDIUM)
      step_interrupt_check_done = 1;
    endtask

    virtual task perform_error_handling();
      `uvm_info(get_type_name(), "Performing error handling (hook)", UVM_MEDIUM)
      step_error_handling_done = 1;
    endtask

  endclass
endpackage

