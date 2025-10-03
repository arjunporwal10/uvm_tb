package stimulus_auto_builder_pkg;
  import uvm_pkg::*;
  import avry_types_pkg::*;          // stimulus_action_t, traffic_action_data, reg_*_action_data, wait_viral_action_data, link_degrade_action_data, parallel_group_t, dir_e
  import action_executors_pkg::*;
  `include "uvm_macros.svh"

  //----------------------------------------------------------------------
  // Stimulus Auto Builder
  //
  // Notes:
  //  - Functions use defaulted trailing arguments so both 2-arg and 4-arg
  //    YAML-generated calls compile (e.g., build_traffic(dir,n) OR build_traffic(dir,n,base,pat)).
  //  - No executor pointers are stored in the action object; the sequence’s
  //    executor registry (in avry_stimulus_flexible_base) remains the single
  //    source of truth mapping action_type -> executor.
  //----------------------------------------------------------------------

  class stimulus_auto_builder;

    // Build a default action list if scenario_cfg.action_list is empty
    static function void build(avry_scenario_cfg cfg, ref stimulus_action_t action_q[$]);
      integer n;
      if (cfg.action_list.size() == 0) begin
        // Minimal: RESET -> TRAFFIC(WRITE) -> SELF_CHECK
        action_q.push_back(build_reset());

        // Resolve packet count (prefer new field, fallback to legacy)
        if (cfg.num_packets > 0)       n = cfg.num_packets;
        else if (cfg.num_writes > 0)   n = cfg.num_writes;
        else if (cfg.num_reads  > 0)   n = cfg.num_reads;
        else                           n = 16;

        action_q.push_back(build_traffic(DIR_WRITE, n));         // defaults base/pat = 0
        action_q.push_back(build_self_check());

        if (cfg.inject_errors) action_q.push_back(build_error());
        if (cfg.viral_check)   action_q.push_back(build_viral());
        if (cfg.reset_after)   action_q.push_back(build_reset());
      end
    endfunction

    //-----------------------------
    // Atomic action builders
    //-----------------------------

    static function stimulus_action_t build_reset();
      stimulus_action_t a;
      a = new("a_reset");
      a.action_type = "RESET";
      a.action_data = null;
      return a;
    endfunction

    static function stimulus_action_t build_error();
      stimulus_action_t a;
      a = new("a_error_injection");
      a.action_type = "ERROR_INJECTION";
      a.action_data = null;
      return a;
    endfunction

    // Historical short form for a simple viral check
    static function stimulus_action_t build_viral();
      stimulus_action_t a;
      a = new("a_viral_check");
      a.action_type = "VIRAL_CHECK";
      a.action_data = null;
      return a;
    endfunction

    // Explicit wait-viral with payload
    static function stimulus_action_t build_wait_viral(string expected_state = "VIRAL_ACTIVE",
                                                       int    timeout        = 1000);
      stimulus_action_t      a;
      wait_viral_action_data d;
      a = new("a_wait_viral");
      a.action_type = "WAIT_VIRAL";
      d = new();
      d.expected_state = expected_state;
      d.timeout        = timeout;
      a.action_data    = d;
      return a;
    endfunction

    static function stimulus_action_t build_self_check();
      stimulus_action_t a;
      a = new("a_self_check");
      a.action_type = "SELF_CHECK";
      a.action_data = null;
      return a;
    endfunction

    // Traffic builder with defaulted trailing args so both 2-arg and 4-arg calls work.
    static function stimulus_action_t build_traffic(dir_e dir,
                                                    integer num_packets,
                                                    bit [31:0] addr_base   = 32'h0,
                                                    bit [31:0] data_pattern = 32'h0);
      stimulus_action_t   a;
      traffic_action_data d;
      a = new("a_traffic");
      a.action_type = "TRAFFIC";
      d = new();
      d.direction   = dir;
      d.num_packets = num_packets;
      // If you want addr_base/data_pattern in traffic payload, add fields there and set them.
      // For now, we keep them in scenario_cfg or use executors’ defaults.
      a.action_data = d;
      return a;
    endfunction

    static function stimulus_action_t build_reg_write(bit [31:0] addr, bit [31:0] data);
      stimulus_action_t      a;
      reg_write_action_data  d;
      a = new("a_reg_write");
      a.action_type = "REG_WRITE";
      d = new();
      d.addr = addr;
      d.data = data;
      a.action_data = d;
      return a;
    endfunction

    static function stimulus_action_t build_reg_read(bit [31:0] addr);
      stimulus_action_t     a;
      reg_read_action_data  d;
      a = new("a_reg_read");
      a.action_type = "REG_READ";
      d = new();
      d.addr = addr;
      a.action_data = d;
      return a;
    endfunction

    // New: Link degrade with defaulted args (so YAML can pass 2 args, or none).
    static function stimulus_action_t build_link_degrade(string degrade_type = "generic",
                                                         int    delay_cycles = 100);
      stimulus_action_t          a;
      link_degrade_action_data   d;
      a = new("a_link_degrade");
      a.action_type = "LINK_DEGRADE";
      d = new();
      d.degrade_type = degrade_type;
      d.delay_cycles = delay_cycles;
      a.action_data  = d;
      return a;
    endfunction

    //-----------------------------
    // Grouping builders
    //-----------------------------
    static function stimulus_action_t build_parallel(stimulus_action_t subs[$]);
      stimulus_action_t a;
      parallel_group_t  p;
      int i;
      a = new("a_parallel_group");
      a.action_type = "PARALLEL_GROUP";
      p = new();
      for (i = 0; i < subs.size(); i++) p.parallel_actions.push_back(subs[i]);
      a.action_data = p;
      return a;
    endfunction

    static function stimulus_action_t build_serial(stimulus_action_t subs[$]);
      // We reuse parallel_group_t as a generic list container; the executor
      // for "SERIAL_GROUP" will consume p.parallel_actions in order.
      stimulus_action_t a;
      parallel_group_t  p;
      int i;
      a = new("a_serial_group");
      a.action_type = "SERIAL_GROUP";
      p = new();
      for (i = 0; i < subs.size(); i++) p.parallel_actions.push_back(subs[i]);
      a.action_data = p;
      return a;
    endfunction

  endclass
endpackage
  
