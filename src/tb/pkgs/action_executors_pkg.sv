package action_executors_pkg;
  import uvm_pkg::*;
  import avry_types_pkg::*;
  `include "uvm_macros.svh"

  typedef class traffic_action_executor;
  typedef class reset_action_executor;
  typedef class viral_check_action_executor;
  typedef class error_inject_action_executor;
  typedef class self_check_action_executor;
  typedef class parallel_group_action_executor;
  typedef class serial_group_action_executor;
  typedef class logging_template_action_executor;

  // Registry: map string key -> executor handle
  class executor_registry extends uvm_object;
    typedef uvm_resource_db#(stimulus_action_executor_base) exec_db_t;
    `uvm_object_utils(executor_registry)
    function new(string name="executor_registry"); super.new(name); endfunction
    static function void register(string key, stimulus_action_executor_base obj);
      exec_db_t::set({"EXEC_",key}, "handle", obj, null);
    endfunction
    static function stimulus_action_executor_base get(string key);
      stimulus_action_executor_base h; exec_db_t::read_by_name({"EXEC_",key},"handle",h); return h;
    endfunction
  endclass

  // RESET
  class reset_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(reset_action_executor)
    function new(string name="reset_action_executor"); super.new(name); endfunction
    virtual task execute(stimulus_action_t a);
      `uvm_info(get_type_name(),"RESET start",UVM_MEDIUM) #10ns; `uvm_info(get_type_name(),"RESET done",UVM_MEDIUM)
    endtask
  endclass

  // TRAFFIC (executor only logs; the sequence drives items)
  class traffic_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(traffic_action_executor)
    function new(string name="traffic_action_executor"); super.new(name); endfunction
    virtual task execute(stimulus_action_t a);
      traffic_action_data d; string dir_s;
      if (!$cast(d,a.action_data)) begin `uvm_error(get_type_name(),"Missing traffic_action_data"); return; end
      if (d.direction==DIR_WRITE) dir_s="WRITE"; else dir_s="READ";
      `uvm_info(get_type_name(),$sformatf("TRAFFIC %s num=%0d (executor log; seq drives)",dir_s,d.num_packets),UVM_MEDIUM)
      repeat (d.num_packets) #1ns;
      `uvm_info(get_type_name(),"TRAFFIC complete",UVM_MEDIUM)
    endtask
  endclass

  // VIRAL_CHECK
  class viral_check_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(viral_check_action_executor)
    function new(string name="viral_check_action_executor"); super.new(name); endfunction
    virtual task execute(stimulus_action_t a);
      `uvm_info(get_type_name(),"WAIT_VIRAL start",UVM_MEDIUM) #100ns; `uvm_info(get_type_name(),"WAIT_VIRAL done",UVM_MEDIUM)
    endtask
  endclass

  // ERROR_INJECTION
  class error_inject_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(error_inject_action_executor)
    function new(string name="error_inject_action_executor"); super.new(name); endfunction
    virtual task execute(stimulus_action_t a);
      `uvm_info(get_type_name(),"ERROR INJECTION start",UVM_MEDIUM) #10ns; `uvm_info(get_type_name(),"ERROR INJECTION done",UVM_MEDIUM)
    endtask
  endclass

  // SELF_CHECK
  class self_check_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(self_check_action_executor)
    function new(string name="self_check_action_executor"); super.new(name); endfunction
    virtual task execute(stimulus_action_t a);
      `uvm_info(get_type_name(),"SELF-CHECK invoked",UVM_MEDIUM) #1ns; `uvm_info(get_type_name(),"SELF-CHECK done",UVM_MEDIUM)
    endtask
  endclass

  // PARALLEL_GROUP
  class parallel_group_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(parallel_group_action_executor)
    function new(string name="parallel_group_action_executor"); super.new(name); endfunction
    virtual task execute(stimulus_action_t a);
      parallel_group_t par_cfg; int j;
      if (!$cast(par_cfg,a.action_data)) begin `uvm_error(get_type_name(),"PARALLEL_GROUP missing payload"); return; end
      `uvm_info(get_type_name(),$sformatf("PARALLEL_GROUP start (N=%0d)",par_cfg.parallel_actions.size()),UVM_MEDIUM)
      fork
        foreach (par_cfg.parallel_actions[j]) begin : LAUNCH
          automatic stimulus_action_t sub_a = par_cfg.parallel_actions[j];
          fork
            begin
              stimulus_action_executor_base sub_ex;
              sub_ex = executor_registry::get(sub_a.action_type);
              `uvm_info(get_type_name(),
                $sformatf("Sub[%0d] START: %s",j,sub_a.action_type),UVM_LOW)
              if (sub_ex==null)
                `uvm_error(get_type_name(),$sformatf("No executor for %s",sub_a.action_type))
              else
                sub_ex.execute(sub_a);
              `uvm_info(get_type_name(),
                $sformatf("Sub[%0d] END: %s",j,sub_a.action_type),UVM_LOW)
            end
          join_none
        end
      join
      `uvm_info(get_type_name(),"PARALLEL_GROUP end",UVM_MEDIUM)
    endtask
  endclass

  // SERIAL_GROUP
  class serial_group_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(serial_group_action_executor)
    function new(string name="serial_group_action_executor"); super.new(name); endfunction
    virtual task execute(stimulus_action_t a);
      parallel_group_t ser_cfg; int i;
      if (!$cast(ser_cfg,a.action_data)) begin `uvm_error(get_type_name(),"SERIAL_GROUP missing payload"); return; end
      `uvm_info(get_type_name(),$sformatf("SERIAL_GROUP start (N=%0d)",ser_cfg.parallel_actions.size()),UVM_MEDIUM)
      for (i=0;i<ser_cfg.parallel_actions.size();i++) begin
        stimulus_action_t sub_a; stimulus_action_executor_base ex;
        sub_a = ser_cfg.parallel_actions[i];
        ex    = executor_registry::get(sub_a.action_type);
        `uvm_info(get_type_name(),
          $sformatf("Serial[%0d] START: %s",i,sub_a.action_type),UVM_LOW)
        if (ex==null) `uvm_error(get_type_name(),$sformatf("No executor for %s",sub_a.action_type))
        else ex.execute(sub_a);
        `uvm_info(get_type_name(),
          $sformatf("Serial[%0d] END: %s",i,sub_a.action_type),UVM_LOW)
      end
      `uvm_info(get_type_name(),"SERIAL_GROUP end",UVM_MEDIUM)
    endtask
  endclass

  // Logging template (for quick stubs)
  class logging_template_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(logging_template_action_executor)
    function new(string name="logging_template_action_executor"); super.new(name); endfunction
    virtual task execute(stimulus_action_t action);
      `uvm_info(get_type_name(),$sformatf("Executing %s",action.action_type),UVM_MEDIUM)
      `uvm_info(get_type_name(),$sformatf("Completed %s",action.action_type),UVM_MEDIUM)
    endtask
  endclass

endpackage

