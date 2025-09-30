package action_executors_pkg;
  import uvm_pkg::*;
  import avry_types_pkg::*;
  `include "uvm_macros.svh"

  // ----------------------------------------------------------------------------
  // Minimal registry: maps action_type -> executor object (one per sequence run)
  // ----------------------------------------------------------------------------
  class executor_registry;
    static protected stimulus_action_executor_base m[string];

    static function void register(string t, stimulus_action_executor_base e);
      m[t] = e;
    endfunction

    static function stimulus_action_executor_base get(string t);
      if (!m.exists(t)) return null;
      return m[t];
    endfunction

    static function bit exists(string t);
      return m.exists(t);
    endfunction

    static function void clear();
      foreach (m[k]) m.delete(k);
    endfunction
  endclass

  // Base class is declared in avry_types_pkg
  // class stimulus_action_executor_base extends uvm_object; ... endclass

  // ----------------------------------------------------------------------------
  // Utility: access VIF if needed
  // ----------------------------------------------------------------------------
  // If executors need the bus vif, fetch it from config_db when they run.
  function automatic virtual simple_bus_if get_vif_or_null();
    virtual simple_bus_if vif;
    if (!uvm_config_db#(virtual simple_bus_if)::get(null, "uvm_test_top.env.*", "vif", vif))
      return null;
    return vif;
  endfunction

  // ----------------------------------------------------------------------------
  // RESET
  // ----------------------------------------------------------------------------
  class reset_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(reset_action_executor)
    function new(string name="reset_action_executor"); super.new(name); endfunction
    virtual task execute(stimulus_action_t a);
      `uvm_info(get_type_name(), "Executing RESET", UVM_MEDIUM)
      // TB-wide reset policy could be:
      //   - toggle top-level rst
      //   - or drive a SW reset via bus
      // Here we no-op to keep DUT reset controlled in top.sv; leave hook:
      // `uvm_info(...,"RESET hook: add TB reset toggling if desired",UVM_LOW)
      #10;
    endtask
  endclass

  // ----------------------------------------------------------------------------
  // TRAFFIC
  // ----------------------------------------------------------------------------
  class traffic_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(traffic_action_executor)
    function new(string name="traffic_action_executor"); super.new(name); endfunction
    virtual task execute(stimulus_action_t a);
      traffic_action_data d;
      if (!$cast(d, a.action_data)) begin
        `uvm_error(get_type_name(), "TRAFFIC missing traffic_action_data"); return;
      end

      `uvm_info(get_type_name(),
        $sformatf("TRAFFIC: dir=%s count=%0d",
          (d.direction==DIR_WRITE)?"WRITE":"READ", d.num_packets), UVM_MEDIUM)

      // NOTE: Real driving of items happens in the sequence (so sequencer/driver are used).
      // This executor is a placeholder if you want side effects, e.g., modify CommonMdl, etc.
      #1;
    endtask
  endclass

  // ----------------------------------------------------------------------------
  // WAIT_VIRAL  (or VIRAL_CHECK legacy)
  // ----------------------------------------------------------------------------
  class wait_viral_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(wait_viral_action_executor)
    function new(string name="wait_viral_action_executor"); super.new(name); endfunction
    virtual task execute(stimulus_action_t a);
      wait_viral_action_data d;
      if (!$cast(d, a.action_data)) begin
        `uvm_error(get_type_name(), "WAIT_VIRAL missing wait_viral_action_data"); return;
      end
      `uvm_info(get_type_name(),
        $sformatf("WAIT_VIRAL: state=%s timeout=%0d", d.expected_state, d.timeout), UVM_MEDIUM)
      // Example TB policy: just wait 'timeout' cycles; in real TB, poll a status register/AP
      repeat (d.timeout) #1;
    endtask
  endclass

  // ----------------------------------------------------------------------------
  // ERROR_INJECTION
  // ----------------------------------------------------------------------------
  class error_inject_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(error_inject_action_executor)
    function new(string name="error_inject_action_executor"); super.new(name); endfunction
    virtual task execute(stimulus_action_t a);
      `uvm_info(get_type_name(), "ERROR_INJECTION: injecting demo error", UVM_MEDIUM)
      // Hook: demote/promote errors, set error knobs, flip bits, etc.
      #1;
    endtask
  endclass

  // ----------------------------------------------------------------------------
  // SELF_CHECK
  // ----------------------------------------------------------------------------
  class self_check_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(self_check_action_executor)
    function new(string name="self_check_action_executor"); super.new(name); endfunction
    virtual task execute(stimulus_action_t a);
      `uvm_info(get_type_name(), "SELF_CHECK: placeholder (scoreboard compare)", UVM_MEDIUM)
      // Hook: call scoreboard / model check here
      #1;
    endtask
  endclass

  // ----------------------------------------------------------------------------
  // REG_WRITE
  // ----------------------------------------------------------------------------
  class reg_write_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(reg_write_action_executor)
    function new(string name="reg_write_action_executor"); super.new(name); endfunction
    virtual task execute(stimulus_action_t a);
      reg_write_action_data d;
      if (!$cast(d, a.action_data)) begin
        `uvm_error(get_type_name(), "REG_WRITE missing reg_write_action_data"); return;
      end
      `uvm_info(get_type_name(),
        $sformatf("REG_WRITE: [0x%08h] <= 0x%08h", d.addr, d.data), UVM_MEDIUM)
      // Hook: if you have a register model, call reg-model write here.
      // In this PoC, we just wait 1 to simulate work.
      #1;
    endtask
  endclass

  // ----------------------------------------------------------------------------
  // REG_READ
  // ----------------------------------------------------------------------------
  class reg_read_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(reg_read_action_executor)
    function new(string name="reg_read_action_executor"); super.new(name); endfunction
    virtual task execute(stimulus_action_t a);
      reg_read_action_data d;
      if (!$cast(d, a.action_data)) begin
        `uvm_error(get_type_name(), "REG_READ missing reg_read_action_data"); return;
      end
      `uvm_info(get_type_name(),
        $sformatf("REG_READ: [0x%08h]", d.addr), UVM_MEDIUM)
      // Hook: if you have a register model, call reg-model read here.
      #1;
    endtask
  endclass

  // ----------------------------------------------------------------------------
  // PARALLEL_GROUP
  // ----------------------------------------------------------------------------
  class parallel_group_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(parallel_group_action_executor)
    function new(string name="parallel_group_action_executor"); super.new(name); endfunction
    virtual task execute(stimulus_action_t a);
      parallel_group_t p; integer j;
      if (!$cast(p, a.action_data)) begin
        `uvm_error(get_type_name(), "PARALLEL_GROUP missing parallel_group_t"); return;
      end
      `uvm_info(get_type_name(), $sformatf("PARALLEL_GROUP: %0d actions", p.parallel_actions.size()), UVM_MEDIUM)
      fork
        for (j=0; j<p.parallel_actions.size(); j++) begin
          automatic stimulus_action_t sub = p.parallel_actions[j];
          fork
            if (!executor_registry::exists(sub.action_type)) begin
              `uvm_error(get_type_name(),
                $sformatf("No handler for Parallel Action Type: %s", sub.action_type))
            end
            else begin
              executor_registry::get(sub.action_type).execute(sub);
            end
          join_none
        end
      join
      `uvm_info(get_type_name(), "PARALLEL_GROUP complete", UVM_LOW)
    endtask
  endclass

  // ----------------------------------------------------------------------------
  // SERIAL_GROUP (reuses parallel_group_t container for convenience)
  // ----------------------------------------------------------------------------
  class serial_group_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(serial_group_action_executor)
    function new(string name="serial_group_action_executor"); super.new(name); endfunction
    virtual task execute(stimulus_action_t a);
      parallel_group_t p; integer j;
      if (!$cast(p, a.action_data)) begin
        `uvm_error(get_type_name(), "SERIAL_GROUP missing parallel_group_t"); return;
      end
      `uvm_info(get_type_name(), $sformatf("SERIAL_GROUP: %0d actions", p.parallel_actions.size()), UVM_MEDIUM)
      for (j=0; j<p.parallel_actions.size(); j++) begin
        stimulus_action_t sub = p.parallel_actions[j];
        if (!executor_registry::exists(sub.action_type)) begin
          `uvm_error(get_type_name(),
            $sformatf("No handler for Serial Action Type: %s", sub.action_type))
        end
        else begin
          executor_registry::get(sub.action_type).execute(sub);
        end
      end
      `uvm_info(get_type_name(), "SERIAL_GROUP complete", UVM_LOW)
    endtask
  endclass

  class link_degrade_executor extends stimulus_action_executor_base;
    `uvm_object_utils(link_degrade_executor)
  
    function new(string name="link_degrade_executor");
      super.new(name);
    endfunction
  
    virtual task execute(stimulus_action_t a);
      `uvm_info(get_type_name(), "Executing LINK_DEGRADE action", UVM_MEDIUM)
      // Actual link degrade code here...
    endtask
  endclass


endpackage

