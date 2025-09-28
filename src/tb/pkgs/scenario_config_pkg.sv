package scenario_config_pkg;
  import uvm_pkg::*;
  import avry_types_pkg::*;

  function avry_scenario_cfg get_scenario_by_name(string name);
    avry_scenario_cfg cfg = new();
    if (0) ;
    else if (name == "full_protocol") begin
      cfg.scenario_name = "full_protocol";
      cfg.scenario_id = "SCENARIO_FULL_PROTOCOL";
      cfg.autobuild_enabled = 1;
      cfg.reset_after = 1;
      cfg.num_writes = 256;
      cfg.num_reads = 64;
      cfg.inject_errors = 1;
      cfg.viral_check = 1;
      cfg.wait_timeout_value = 500;
    end
    else if (name == "parallel_viral") begin
      cfg.scenario_name = "parallel_viral";
      cfg.scenario_id = "SCENARIO_PARALLEL_TRAFFIC_VIRAL";
      cfg.autobuild_enabled = 1;
      cfg.reset_after = 0;
      cfg.num_writes = 128;
      cfg.num_reads = 64;
      cfg.inject_errors = 0;
      cfg.viral_check = 1;
      cfg.wait_timeout_value = 500;
    end
    else if (name == "poll_bfm") begin
      cfg.scenario_name = "poll_bfm";
      cfg.scenario_id = "SCENARIO_PARALLEL_POLL_BFM";
      cfg.autobuild_enabled = 1;
      cfg.reset_after = 0;
      cfg.num_writes = 200;
      cfg.num_reads = 0;
      cfg.inject_errors = 0;
      cfg.viral_check = 1;
      cfg.wait_timeout_value = 500;
    end
    else if (name == "reg_ops") begin
      cfg.scenario_name = "reg_ops";
      cfg.scenario_id = "SCENARIO_REG_OPS";
      cfg.autobuild_enabled = 1;
      cfg.reset_after = 1;
      cfg.num_writes = 16;
      cfg.num_reads = 16;
      cfg.inject_errors = 0;
      cfg.viral_check = 0;
      cfg.wait_timeout_value = 500;
    end
    else if (name == "reset_traffic") begin
      cfg.scenario_name = "reset_traffic";
      cfg.scenario_id = "SCENARIO_REG_TRAFFIC";
      cfg.autobuild_enabled = 1;
      cfg.reset_after = 1;
      cfg.num_writes = 64;
      cfg.num_reads = 0;
      cfg.inject_errors = 0;
      cfg.viral_check = 0;
      cfg.wait_timeout_value = 500;
    end
    else begin `uvm_warning("SCEN", $sformatf("Unknown scenario %s", name)) end
    return cfg;
  endfunction
endpackage
