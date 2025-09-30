package avry_types_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Forward decl for base executor type (referenced by other pkgs)
  typedef class stimulus_action_executor_base;

  // ----------------------------------------------------------------------------
  // Simple bus transaction (example)
  // ----------------------------------------------------------------------------
  typedef struct packed {
    bit [31:0] addr;
    bit [31:0] data;
    bit        we;
  } avry_txn_s;

  // ----------------------------------------------------------------------------
  // Canonical sequence item (agent re-exports this)
  // ----------------------------------------------------------------------------
  class avry_seq_item extends uvm_sequence_item;
    rand bit        we;
    rand bit [31:0] addr;
    rand bit [31:0] data;

    `uvm_object_utils_begin(avry_seq_item)
      `uvm_field_int(we,   UVM_ALL_ON)
      `uvm_field_int(addr, UVM_ALL_ON)
      `uvm_field_int(data, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name="avry_seq_item");
      super.new(name);
    endfunction
  endclass

  // ----------------------------------------------------------------------------
  // Common enums / action payloads
  // ----------------------------------------------------------------------------

  // Direction enum for traffic
  typedef enum int unsigned { DIR_READ, DIR_WRITE } dir_e;

  // Traffic action payload
  class traffic_action_data extends uvm_object;
    rand dir_e direction;   // DIR_READ / DIR_WRITE
    rand int   num_packets;

    `uvm_object_utils_begin(traffic_action_data)
      `uvm_field_enum(dir_e, direction, UVM_ALL_ON)
      `uvm_field_int(num_packets,      UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name="traffic_action_data");
      super.new(name);
    endfunction
  endclass

  // Generic action container
  class stimulus_action_t extends uvm_object;
    string     action_type;  // e.g. "RESET", "TRAFFIC", "PARALLEL_GROUP"
    uvm_object action_data;  // payload specific to action_type (may be null)

    `uvm_object_utils_begin(stimulus_action_t)
      `uvm_field_string(action_type, UVM_ALL_ON)
      `uvm_field_object(action_data, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name="stimulus_action_t");
      super.new(name);
    endfunction
  endclass

  // Parallel/Serial group payload: list of sub-actions
  class parallel_group_t extends uvm_object;
    stimulus_action_t parallel_actions[$];

    `uvm_object_utils_begin(parallel_group_t)
      // If your tool warns about queue-of-objects automation, you can comment this line.
      `uvm_field_queue_object(parallel_actions, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name="parallel_group_t");
      super.new(name);
    endfunction
  endclass

  // ----------------------------------------------------------------------------
  // Scenario enums
  // ----------------------------------------------------------------------------
  typedef enum {
    SCENARIO_UNKNOWN,
    SCENARIO_LINK_TRAINING,
    SCENARIO_TRAFFIC,
    SCENARIO_ERROR_TRAFFIC,
    SCENARIO_FLEX_FLOW
  } scenario_id_e;

  // ----------------------------------------------------------------------------
  // Scenario configuration (supports both legacy + new fields)
  // ----------------------------------------------------------------------------
  class avry_scenario_cfg extends uvm_object;
    `uvm_object_utils(avry_scenario_cfg)

    // Identity
    string        scenario_name;
    scenario_id_e scenario_id;

    // ===== Legacy-style knobs (keep for existing scenario_config_pkg.sv) =====
    bit           reset_after;          // whether to reset after main stimulus
    int           num_writes;           // legacy split counts
    int           num_reads;            // legacy split counts
    bit           inject_errors;        // whether to inject errors
    bit           viral_check;          // whether to wait/check a "viral" condition
    int           wait_timeout_value;   // wait timeout (legacy name)

    // ===== Newer unified/simple knobs =======================================
    int unsigned  timeout_value;        // used by our base seq timeout wrapper
    int unsigned  num_packets;          // total packets when not split per dir
    int unsigned  addr_base;            // base address for generated traffic
    bit [31:0]    data_pattern;         // data pattern seed

    // ===== Reporting/handling ==============================================
    string        expected_interrupts[$];
    string        demote_errors[$];
    string        promote_errors[$];

    // ===== Flexible action list (YAML-driven) ===============================
    stimulus_action_t action_list[$];   // when using action engine
    bit               autobuild_enabled;

    function new(string name="avry_scenario_cfg");
      super.new(name);

      // Sensible defaults
      scenario_id        = SCENARIO_UNKNOWN;

      // Legacy fields defaulting
      reset_after        = 0;
      num_writes         = 0;
      num_reads          = 0;
      inject_errors      = 0;
      viral_check        = 0;
      wait_timeout_value = 10000;

      // New flow defaults
      timeout_value      = 10000;
      num_packets        = 16;
      addr_base          = 32'h1000_0000;
      data_pattern       = 32'hA5A5_5A5A;

      autobuild_enabled  = 1;
    endfunction
  endclass

  // ----------------------------------------------------------------------------
  // Base executor class (concrete executors extend this)
  // ----------------------------------------------------------------------------
  class stimulus_action_executor_base extends uvm_object;
    `uvm_object_utils(stimulus_action_executor_base)

    function new(string name="stimulus_action_executor_base");
      super.new(name);
    endfunction

    virtual task execute(stimulus_action_t a);
      `uvm_fatal(get_type_name(),"execute() not implemented in base")
    endtask
  endclass
  // --- Add after traffic_action_data / parallel_group_t declarations ---

  // Register write payload
  class reg_write_action_data extends uvm_object;
    rand bit [31:0] addr;
    rand bit [31:0] data;
    `uvm_object_utils_begin(reg_write_action_data)
      `uvm_field_int(addr, UVM_ALL_ON)
      `uvm_field_int(data, UVM_ALL_ON)
    `uvm_object_utils_end
    function new(string name="reg_write_action_data"); super.new(name); endfunction
  endclass

  // Register read payload
  class reg_read_action_data extends uvm_object;
    rand bit [31:0] addr;
    `uvm_object_utils_begin(reg_read_action_data)
      `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_object_utils_end
    function new(string name="reg_read_action_data"); super.new(name); endfunction
  endclass

  // Viral wait payload
  class wait_viral_action_data extends uvm_object;
    string expected_state; // e.g., "VIRAL_ACTIVE"
    int    timeout;        // cycles or time units per your TB policy
    `uvm_object_utils_begin(wait_viral_action_data)
      `uvm_field_string(expected_state, UVM_ALL_ON)
      `uvm_field_int(timeout, UVM_ALL_ON)
    `uvm_object_utils_end
    function new(string name="wait_viral_action_data"); super.new(name); endfunction
  endclass

  class link_degrade_action_data extends uvm_object;
    string degrade_type;
    int    delay_cycles;
  
    `uvm_object_utils_begin(link_degrade_action_data)
      `uvm_field_string(degrade_type,  UVM_ALL_ON)
      `uvm_field_int   (delay_cycles,  UVM_ALL_ON)
    `uvm_object_utils_end
  
    function new(string name = "link_degrade_action_data");
      super.new(name);
    endfunction
  endclass

endpackage

