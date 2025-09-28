package avry_env_pkg;
  import uvm_pkg::*;
  import avry_agent_pkg::*;
  import avry_cov_pkg::*;
  `include "uvm_macros.svh"

  class avry_env extends uvm_env;
    `uvm_component_utils(avry_env)

    avry_sequencer sqr;
    avry_driver    drv;
    avry_monitor   mon;
    avry_cov       cov;

    function new(string name="avry_env", uvm_component parent=null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      sqr = avry_sequencer::type_id::create("sqr", this);
      drv = avry_driver   ::type_id::create("drv", this);
      mon = avry_monitor  ::type_id::create("mon", this);
      cov = avry_cov      ::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      drv.seq_item_port.connect(sqr.seq_item_export); // FIX
      mon.intr_ap.connect(cov.intr_imp);
      mon.viral_ap.connect(cov.viral_imp);
    endfunction
  endclass

endpackage

