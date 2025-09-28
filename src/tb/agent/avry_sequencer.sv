package avry_sequencer_pkg;
  import uvm_pkg::*;
  import avry_agent_pkg::*;
  `include "uvm_macros.svh"

  class avry_sequencer extends uvm_sequencer #(avry_seq_item);
    `uvm_component_utils(avry_sequencer)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
  endclass

endpackage

