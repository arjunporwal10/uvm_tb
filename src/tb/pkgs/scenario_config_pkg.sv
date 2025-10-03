// Auto-generated scenario_config_pkg.sv
package scenario_config_pkg;
  import avry_types_pkg::*;
  import stimulus_auto_builder_pkg::*;
  function automatic avry_scenario_cfg get_scenario_by_name(string name);
    avry_scenario_cfg cfg = avry_scenario_cfg::type_id::create(name);
    if (0) ;
    else if (name == "full_protocol") begin
      cfg.scenario_name = "full_protocol";
      cfg.action_list.delete();
    end
    else if (name == "test_link_degrade_parallel") begin
      stimulus_action_t a_reset_0;
      stimulus_action_t a_parallel_group_1;
      stimulus_action_t a_link_degrade_1_0;
      stimulus_action_t a_traffic_1_1;
      stimulus_action_t a_reset_2;
      stimulus_action_t a_parallel_group_3;
      stimulus_action_t a_link_degrade_3_0;
      stimulus_action_t a_link_degrade_3_1;
      stimulus_action_t a_link_degrade_3_2;
      stimulus_action_t a_serial_group_4;
      stimulus_action_t a_traffic_4_0;
      stimulus_action_t a_self_check_4_1;
      stimulus_action_t a_link_degrade_4_2;
      cfg.scenario_name = "test_link_degrade_parallel";
      cfg.timeout_value = 20000;
      a_reset_0 = stimulus_auto_builder::build_reset();
      a_link_degrade_1_0 = stimulus_auto_builder::build_link_degrade("2-lane", 150);
      a_traffic_1_1 = stimulus_auto_builder::build_traffic(DIR_WRITE, 32);
      a_parallel_group_1 = stimulus_auto_builder::build_parallel({a_link_degrade_1_0, a_traffic_1_1});
      a_reset_2 = stimulus_auto_builder::build_reset();
      a_link_degrade_3_0 = stimulus_auto_builder::build_link_degrade("2-lane", 150);
      a_link_degrade_3_1 = stimulus_auto_builder::build_link_degrade("2-lane", 150);
      a_link_degrade_3_2 = stimulus_auto_builder::build_link_degrade("2-lane", 200);
      a_parallel_group_3 = stimulus_auto_builder::build_parallel({a_link_degrade_3_0, a_link_degrade_3_1, a_link_degrade_3_2});
      a_traffic_4_0 = stimulus_auto_builder::build_traffic(DIR_READ, 16);
      a_self_check_4_1 = stimulus_auto_builder::build_self_check();
      a_link_degrade_4_2 = stimulus_auto_builder::build_link_degrade("generic", 100);
      a_serial_group_4 = stimulus_auto_builder::build_serial({a_traffic_4_0, a_self_check_4_1, a_link_degrade_4_2});
      cfg.action_list.delete();
      cfg.action_list.push_back(a_reset_0);
      cfg.action_list.push_back(a_parallel_group_1);
      cfg.action_list.push_back(a_reset_2);
      cfg.action_list.push_back(a_parallel_group_3);
      cfg.action_list.push_back(a_serial_group_4);
    end
    else if (name == "parallel_viral") begin
      cfg.scenario_name = "parallel_viral";
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
    else if (name == "reset_traffic") begin
      cfg.scenario_name = "reset_traffic";
      cfg.action_list.delete();
    end
    else if (name == "serial_parallel_mix") begin
      cfg.scenario_name = "serial_parallel_mix";
      cfg.timeout_value = 15000;
      cfg.action_list.delete();
    end
    return cfg;
  endfunction
endpackage
