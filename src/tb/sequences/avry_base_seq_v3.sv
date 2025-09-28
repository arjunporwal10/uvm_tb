package avry_base_seq_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Forward decls for handles from env
  typedef class avry_scoreboard_base;
  typedef class avry_interrupt_monitor_base;

  class avry_base_seq #(type REQ_T = uvm_sequence_item,
                        type RSP_T = uvm_sequence_item)
      extends uvm_sequence #(REQ_T, RSP_T);

    `uvm_object_param_utils(avry_base_seq#(REQ_T, RSP_T))

    // ---------------- Vars ----------------
    rand bit         enable_self_checking = 1;
    int unsigned     seq_timeout = 10000;

    REQ_T            req;
    RSP_T            rsp;

    avry_scoreboard_base        sb_h;
    avry_interrupt_monitor_base intr_mon_h;

    // ---- Called/Completed flags (fine-grain) ----
    bit step_stimulus_called,            step_stimulus_completed;
    bit step_interrupt_check_called,     step_interrupt_check_completed;
    bit step_timeout_check_called,       step_timeout_check_completed;
    bit step_self_check_called,          step_self_check_completed;
    bit step_coverage_check_called,      step_coverage_check_completed;

    function new(string name="avry_base_seq");
      super.new(name);
    endfunction

    // --------------- pre_body ----------------------
    virtual task pre_body();
      super.pre_body();
      `uvm_info(get_type_name(), ">>> PRE_BODY START <<<", UVM_MEDIUM)

      if (!uvm_config_db#(avry_scoreboard_base)::get(null, "*", "scoreboard", sb_h))
        `uvm_error(get_type_name(), "Failed to get handle to scoreboard!")

      if (!uvm_config_db#(avry_interrupt_monitor_base)::get(null, "*", "intr_monitor", intr_mon_h))
        `uvm_warning(get_type_name(), "Interrupt monitor not connected, continuing...")
    endtask

    // ---------------- body -------------------------
    virtual task body();
      `uvm_info(get_type_name(), ">>> BODY START <<<", UVM_LOW)
      wait_with_timeout(task_main_body);
    endtask

    // --------------- post_body ---------------------
    virtual task post_body();
      super.post_body();
      `uvm_info(get_type_name(), ">>> POST_BODY START <<<", UVM_MEDIUM)

      // Coverage & Self-check in post
      perform_coverage_check();
      perform_self_check();

      report_step_summary();
    endtask

    // ---------------- modular steps ----------------
    virtual task perform_stimulus();
      step_stimulus_called = 1;
      `uvm_info(get_type_name(), "Performing STIMULUS step", UVM_MEDIUM)
      // INSERT STIMULUS HERE
      step_stimulus_completed = 1;
    endtask

    virtual task perform_interrupt_check();
      step_interrupt_check_called = 1;
      `uvm_info(get_type_name(), "Performing INTERRUPT CHECK step", UVM_MEDIUM)
      if (intr_mon_h != null) begin
        // example overall check
        if (intr_mon_h.check_interrupts() == 0)
          `uvm_error(get_type_name(), "Expected interrupt(s) did not occur!")
        else
          `uvm_info(get_type_name(), "Expected interrupt(s) observed.", UVM_HIGH)
      end else begin
        `uvm_warning(get_type_name(), "Interrupt monitor not connected — skipping interrupt check!")
      end
      step_interrupt_check_completed = 1;
    endtask

    task wait_with_timeout(input task automatic void_task);
      step_timeout_check_called = 1;
      fork
        begin
          void_task();
          step_timeout_check_completed = 1;
        end
        begin
          #(seq_timeout);
          `uvm_error(get_type_name(), "Sequence TIMEOUT occurred!")
        end
      join_any
      disable fork;
    endtask

    virtual task perform_self_check();
      step_self_check_called = 1;
      if (enable_self_checking) begin
        `uvm_info(get_type_name(), "Performing SELF CHECK step", UVM_HIGH)
        if (sb_h != null) begin
          sb_h.check_results();
          step_self_check_completed = 1;
        end else begin
          `uvm_warning(get_type_name(), "No scoreboard connected - skipping self-check!")
          step_self_check_completed = 0; // explicit skip
        end
      end else begin
        `uvm_warning(get_type_name(), "Self-checking DISABLED for this sequence!")
        step_self_check_completed = 0; // explicit disabled
      end
    endtask

    virtual task perform_coverage_check();
      step_coverage_check_called = 1;
      `uvm_info(get_type_name(), "Performing COVERAGE CHECK step", UVM_LOW)
      sample_coverage();
      step_coverage_check_completed = 1; // mark if sample_coverage did something meaningful
    endtask

    virtual function void sample_coverage();
      `uvm_info(get_type_name(), "Sampling coverage (if applicable)", UVM_LOW)
      // Insert covergroup.sample() or ap-driven sampling logic
    endfunction

    virtual task report_step_summary();
      `uvm_info(get_type_name(), ">>> Final SEQUENCE STEP SUMMARY <<<", UVM_MEDIUM)

      if (!step_stimulus_called)
        `uvm_error(get_type_name(), "Stimulus step was NOT called!")
      else if (!step_stimulus_completed)
        `uvm_warning(get_type_name(), "Stimulus step was called but NOT completed!")

      if (!step_interrupt_check_called)
        `uvm_error(get_type_name(), "Interrupt check step was NOT called!")
      else if (!step_interrupt_check_completed)
        `uvm_warning(get_type_name(), "Interrupt check step was called but NOT completed!")

      if (!step_timeout_check_called)
        `uvm_error(get_type_name(), "Timeout wrapper was NOT used!")
      else if (!step_timeout_check_completed)
        `uvm_warning(get_type_name(), "Timeout completed with TIMEOUT ERROR or was preempted!")

      if (!step_coverage_check_called)
        `uvm_error(get_type_name(), "Coverage check step was NOT called!")
      else if (!step_coverage_check_completed)
        `uvm_warning(get_type_name(), "Coverage step called but no coverage sampled!")

      if (!step_self_check_called)
        `uvm_error(get_type_name(), "Self-check step was NOT called!")
      else if (!step_self_check_completed)
        `uvm_warning(get_type_name(), "Self-check step called but NOT completed!")

      `uvm_info(get_type_name(), ">>> SEQUENCE STEP SUMMARY COMPLETE <<<", UVM_MEDIUM)
    endtask

    // ------------- hook to implement in derived seq -------------
    virtual task task_main_body();
      `uvm_info(get_type_name(), ">>> Executing MAIN SEQUENCE logic <<<", UVM_MEDIUM)
      perform_stimulus();
      perform_interrupt_check();
    endtask

  endclass
endpackage

