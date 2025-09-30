// Auto-generated scenario_config_pkg.sv
package scenario_config_pkg;

  import uvm_pkg::*;
  import avry_types_pkg::*;
  import stimulus_auto_builder_pkg::*; // FIXED
  `include "uvm_macros.svh"

  function automatic avry_scenario_cfg get_scenario_by_name(string name);

    avry_scenario_cfg cfg = avry_scenario_cfg::type_id::create(name);

    // FIXED: Declare all handles at the top, outside if/else
    stimulus_action_t a_reset_0;
    stimulus_action_t a_link_degrade_1;
    stimulus_action_t a_traffic_2;

    if (0); // dummy block to allow else-if chain

    else if (name == "test_link_degrade") begin
      cfg.scenario_name = "test_link_degrade";
      cfg.timeout_value = 20000;

      // FIXED: Use fully qualified call
      a_reset_0         = stimulus_auto_builder::build_reset();
      a_link_degrade_1  = stimulus_auto_builder::build_link_degrade();
      a_traffic_2       = stimulus_auto_builder::build_traffic(DIR_READ, 32);

      cfg.action_list.delete();
      cfg.action_list.push_back(a_reset_0);
      cfg.action_list.push_back(a_link_degrade_1);
      cfg.action_list.push_back(a_traffic_2);
    end

    else if (name == "reset_traffic") begin
      cfg.scenario_name = "reset_traffic";
      cfg.action_list.delete();
    end

    else if (name == "parallel_viral") begin
      cfg.scenario_name = "parallel_viral";
      cfg.action_list.delete();
    end

    else if (name == "serial_parallel_mix") begin
      cfg.scenario_name = "serial_parallel_mix";
      cfg.timeout_value = 15000;
      cfg.action_list.delete();
    end

    else if (name == "poll_bfm") begin
      cfg.scenario_name = "poll_bfm";
      cfg.action_list.delete();
    end

    else if (name == "reg_ops") begin
      cfg.scenario_name = "reg_ops";
      cfg.action_list.delete();
    end

    else if (name == "full_protocol") begin
      cfg.scenario_name = "full_protocol";
      cfg.action_list.delete();
    end

    return cfg;

  endfunction

endpackage

