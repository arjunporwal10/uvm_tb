package avry_cov_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `uvm_analysis_imp_decl(_intr)
  `uvm_analysis_imp_decl(_viral)

  class avry_cov extends uvm_component;
    `uvm_component_utils(avry_cov)

    uvm_analysis_imp_intr#(int, avry_cov)   intr_imp;
    uvm_analysis_imp_viral#(int, avry_cov)  viral_imp;

    bit intr_seen;
    bit viral_seen;

    function new(string name="avry_cov", uvm_component parent=null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      intr_imp  = new("intr_imp",  this);
      viral_imp = new("viral_imp", this);
    endfunction

    function void write_intr(int t);
      intr_seen = 1;
      `uvm_info(get_type_name(),"Coverage observed: intr",UVM_LOW)
    endfunction

    function void write_viral(int t);
      viral_seen = 1;
      `uvm_info(get_type_name(),"Coverage observed: viral",UVM_LOW)
    endfunction

    function void report_phase(uvm_phase phase);
      `uvm_info(get_type_name(),
        $sformatf("Summary: intr_seen=%0d, viral_seen=%0d", intr_seen, viral_seen),
        UVM_LOW)
    endfunction
  endclass
endpackage

