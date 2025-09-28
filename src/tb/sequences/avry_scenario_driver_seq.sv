package avry_scenario_seq_pkg;
  import uvm_pkg::*;
  import avry_types_pkg::*;
  import avry_base_seq_pkg::*;
  import avry_agent_pkg::*;
  `include "uvm_macros.svh"

  class avry_scenario_driver_seq extends avry_base_seq#(avry_seq_item, avry_seq_item);
    `uvm_object_utils(avry_scenario_driver_seq)

    avry_scenario_cfg scenario_cfg;

    function new(string name="avry_scenario_driver_seq");
      super.new(name);
    endfunction

    virtual task task_main_body();
      `uvm_info(get_type_name(),
        $sformatf("Executing Scenario: %s (id=%0d)", scenario_cfg.scenario_name, scenario_cfg.scenario_id),
        UVM_MEDIUM)

      perform_error_handling(); // demotions/promotions applied prior to activity
      wait_with_timeout(task_run_scenario);
    endtask

    virtual task task_run_scenario();
      perform_stimulus();         // emits traffic/items
      perform_interrupt_check();  // verify interrupts (if any)
      // coverage & self-check in post_body
    endtask

    // ------------ Stimulus selection by scenario_id ------------
    virtual task perform_stimulus();
      step_stimulus_called = 1;
      `uvm_info(get_type_name(), "Performing STIMULUS step", UVM_MEDIUM)

      case (scenario_cfg.scenario_id)
        SCENARIO_LINK_TRAINING:   stimulus_link_training();
        SCENARIO_TRAFFIC:         stimulus_traffic(0);
        SCENARIO_ERROR_TRAFFIC:   stimulus_traffic(1);
        SCENARIO_FLEX_FLOW:       stimulus_flexible_action_list();
        default: `uvm_fatal(get_type_name(),
                    $sformatf("Unknown scenario_id: %0d", scenario_cfg.scenario_id))
      endcase
      step_stimulus_completed = 1;
    endtask

    // ------------ Concrete stimulus implementations ------------
    virtual task stimulus_link_training();
      `uvm_info(get_type_name(), "Running LINK TRAINING stimulus", UVM_MEDIUM)
      // TODO: training pattern items or config writes
      // placeholder delay:
      #50ns;
    endtask

    virtual task stimulus_traffic(bit inject_err);
      int k;
      avry_seq_item it;
      `uvm_info(get_type_name(), $sformatf("Running TRAFFIC stimulus npkts=%0d", scenario_cfg.num_packets), UVM_MEDIUM)
      for (k=0; k<scenario_cfg.num_packets; k++) begin
        it = avry_seq_item::type_id::create($sformatf("it_%0d", k));
        it.we   = (inject_err) ? (k[0]) : 1'b1; // simplistic variation
        it.addr = scenario_cfg.addr_base + k*4;
        it.data = scenario_cfg.data_pattern ^ k;
        start_item(it);
        finish_item(it);
      end
    endtask

    virtual task stimulus_flexible_action_list();
      `uvm_info(get_type_name(),
        $sformatf("Flexible Action List size=%0d", scenario_cfg.action_list.size()), UVM_MEDIUM)
      foreach (scenario_cfg.action_list[i]) begin
        stimulus_action_t a;
        a = scenario_cfg.action_list[i];

        if (a.action_type == "TRAFFIC") begin
          traffic_action_data d;
          if ($cast(d, a.action_data)) begin
            avry_seq_item it;
            int n;
            int k;
            bit is_wr;
            is_wr = (d.direction == DIR_WRITE);
            n     = d.num_packets;
            for (k=0; k<n; k++) begin
              it = avry_seq_item::type_id::create($sformatf("it_%0d", k));
              it.we   = is_wr;
              it.addr = scenario_cfg.addr_base + k*4;
              it.data = scenario_cfg.data_pattern ^ k;
              start_item(it); finish_item(it);
            end
          end else begin
            `uvm_error(get_type_name(),"TRAFFIC action missing traffic_action_data")
          end
        end
        else begin
          // Non-traffic actions are delegated to executors via registry
          stimulus_action_executor_base ex;
          ex = action_executors_pkg::executor_registry::get(a.action_type);
          if (ex == null) `uvm_error(get_type_name(),
                         $sformatf("No executor registered for %s", a.action_type))
          else            ex.execute(a);
        end
      end
    endtask

    // ------------ Interrupt Check override ------------
    virtual task perform_interrupt_check();
      int idx;
      step_interrupt_check_called = 1;
      `uvm_info(get_type_name(), "Performing INTERRUPT CHECK step", UVM_MEDIUM)

      if (scenario_cfg.expected_interrupts.size() == 0) begin
        `uvm_info(get_type_name(), "No expected interrupts for this scenario", UVM_LOW)
        step_interrupt_check_completed = 1;
        return;
      end

      if (intr_mon_h == null) begin
        `uvm_warning(get_type_name(), "Interrupt monitor not connected — skipping interrupt check!")
        step_interrupt_check_completed = 0;
        return;
      end

      for (idx=0; idx<scenario_cfg.expected_interrupts.size(); idx++) begin
        string intr_name;
        bit    seen;
        intr_name = scenario_cfg.expected_interrupts[idx];
        seen = intr_mon_h.check_for_interrupt(intr_name); // user monitor API
        if (!seen)
          `uvm_error(get_type_name(), $sformatf("Expected interrupt %s not seen!", intr_name))
        else
          `uvm_info(get_type_name(), $sformatf("Expected interrupt %s seen.", intr_name), UVM_HIGH)
      end
      step_interrupt_check_completed = 1;
    endtask

    // ------------ Timeout wrapper override -------------
    task wait_with_timeout(input task automatic void_task);
      step_timeout_check_called = 1;
      fork
        begin void_task(); step_timeout_check_completed = 1; end
        begin #(scenario_cfg.timeout_value); `uvm_error(get_type_name(),"Sequence TIMEOUT occurred!") end
      join_any
      disable fork;
    endtask

    // ------------ Error handling (demote/promote) -----
    virtual task perform_error_handling();
      int i;
      `uvm_info(get_type_name(), "Applying ERROR HANDLING settings", UVM_MEDIUM)
      for (i=0; i<scenario_cfg.demote_errors.size(); i++) begin
        string err; err = scenario_cfg.demote_errors[i];
        // hook: uvm_report_handler::set_severity_id_override() or a custom manager
        `uvm_info(get_type_name(), $sformatf("Demote error id: %s -> WARNING (hook)", err), UVM_LOW)
      end
      for (i=0; i<scenario_cfg.promote_errors.size(); i++) begin
        string err; err = scenario_cfg.promote_errors[i];
        `uvm_info(get_type_name(), $sformatf("Promote error id: %s -> FATAL (hook)", err), UVM_LOW)
      end
    endtask

  endclass
endpackage

