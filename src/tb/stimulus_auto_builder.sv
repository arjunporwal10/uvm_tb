package stimulus_auto_builder_pkg;
  import uvm_pkg::*;
  import avry_types_pkg::*;
  `include "uvm_macros.svh"

  class stimulus_auto_builder;

    // Build a default action list if none is provided
    static function void build(avry_scenario_cfg cfg, ref stimulus_action_t action_q[$]);
      integer n;   // use integer instead of int (VCS-friendly)
      if (cfg.action_list.size() == 0) begin
        // Minimal sequence: RESET -> TRAFFIC(WRITE) -> SELF_CHECK
        action_q.push_back(build_reset());

        // Packet count resolution (prefer new field, fall back to legacy)
        if (cfg.num_packets > 0)       n = cfg.num_packets;
        else if (cfg.num_writes > 0)   n = cfg.num_writes;
        else if (cfg.num_reads  > 0)   n = cfg.num_reads;
        else                           n = 16;

        action_q.push_back(build_traffic(DIR_WRITE, n));
        action_q.push_back(build_self_check());

        if (cfg.inject_errors) action_q.push_back(build_error());
        if (cfg.viral_check)   action_q.push_back(build_viral());
        if (cfg.reset_after)   action_q.push_back(build_reset());
      end
    endfunction

    static function stimulus_action_t build_reset();
      stimulus_action_t a; a=new(); a.action_type="RESET"; a.action_data=null; return a;
    endfunction

    static function stimulus_action_t build_error();
      stimulus_action_t a; a=new(); a.action_type="ERROR_INJECTION"; a.action_data=null; return a;
    endfunction

    static function stimulus_action_t build_viral();
      stimulus_action_t a; a=new(); a.action_type="VIRAL_CHECK"; a.action_data=null; return a;
    endfunction

    static function stimulus_action_t build_self_check();
      stimulus_action_t a; a=new(); a.action_type="SELF_CHECK"; a.action_data=null; return a;
    endfunction

    static function stimulus_action_t build_traffic(dir_e dir, integer n);
      stimulus_action_t a; traffic_action_data d;
      a = new(); a.action_type = "TRAFFIC";
      d = new(); d.direction = dir; d.num_packets = n;
      a.action_data = d; return a;
    endfunction

    static function stimulus_action_t build_parallel(stimulus_action_t subs[$]);
      stimulus_action_t a; parallel_group_t p; integer i;
      a = new(); a.action_type = "PARALLEL_GROUP";
      p = new(); for (i=0;i<subs.size();i++) p.parallel_actions.push_back(subs[i]);
      a.action_data = p; return a;
    endfunction

    static function stimulus_action_t build_serial(stimulus_action_t subs[$]);
      stimulus_action_t a; parallel_group_t p; integer i;
      a = new(); a.action_type = "SERIAL_GROUP";
      p = new(); for (i=0;i<subs.size();i++) p.parallel_actions.push_back(subs[i]);
      a.action_data = p; return a;
    endfunction

    static function stimulus_action_t build_link_degrade();
      link_degrade_action_executor exec = link_degrade_action_executor::type_id::create("link_degrade_exec");
      stimulus_action_t action = stimulus_action_t::type_id::create("link_degrade_action");
      action.set_executor(exec);
      return action;
    endfunction
    
  endclass
endpackage

