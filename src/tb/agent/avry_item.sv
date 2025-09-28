package avry_agent_pkg;
  import uvm_pkg::*;
  import avry_types_pkg::*;
  `include "uvm_macros.svh"

  // --------------------------------------------------------------------------
  // Canonical item re-export (avoid duplicate class definitions across packages)
  // --------------------------------------------------------------------------
  typedef avry_types_pkg::avry_seq_item avry_seq_item;
  typedef avry_types_pkg::avry_seq_item avry_item; // legacy alias

  // --------------------------------------------------------------------------
  // Sequencer
  // --------------------------------------------------------------------------
  class avry_sequencer extends uvm_sequencer #(avry_seq_item);
    `uvm_component_utils(avry_sequencer)
    function new(string name="avry_sequencer", uvm_component parent=null);
      super.new(name, parent);
    endfunction
  endclass

  // --------------------------------------------------------------------------
  // Driver: matches simple_bus_if (valid/ready/we/addr/wdata/rdata)
  // --------------------------------------------------------------------------
  class avry_driver extends uvm_driver #(avry_seq_item);
    `uvm_component_utils(avry_driver)

    virtual simple_bus_if vif;

    function new(string name="avry_driver", uvm_component parent=null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual simple_bus_if)::get(this, "", "vif", vif)) begin
        `uvm_fatal(get_type_name(), "virtual interface 'vif' not set via config_db (key='vif')")
      end
    endfunction

    task run_phase(uvm_phase phase);
      avry_seq_item t;
      // init idle
      vif.valid <= 1'b0;
      vif.we    <= 1'b0;
      vif.addr  <= '0;
      vif.wdata <= '0;

      forever begin
        seq_item_port.get_next_item(t);

        // one-beat handshake
        @(posedge vif.clk);
        vif.we    <= t.we;
        vif.addr  <= t.addr;
        vif.wdata <= t.data;
        vif.valid <= 1'b1;

        // wait until DUT ready
        do @(posedge vif.clk); while (!vif.ready);

        // return to idle
        @(posedge vif.clk);
        vif.valid <= 1'b0;

        seq_item_port.item_done();
      end
    endtask
  endclass

  // --------------------------------------------------------------------------
  // Monitor: simple events on handshake (write→intr, read→viral)
  // --------------------------------------------------------------------------
  class avry_monitor extends uvm_component;
    `uvm_component_utils(avry_monitor)

    uvm_analysis_port#(int) intr_ap;
    uvm_analysis_port#(int) viral_ap;

    virtual simple_bus_if vif;

    function new(string name="avry_monitor", uvm_component parent=null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      intr_ap  = new("intr_ap",  this);
      viral_ap = new("viral_ap", this);
      if (!uvm_config_db#(virtual simple_bus_if)::get(this, "", "vif", vif)) begin
        `uvm_fatal(get_type_name(), "virtual interface 'vif' not set via config_db (key='vif')")
      end
    endfunction

    task run_phase(uvm_phase phase);
      forever begin
        @(posedge vif.clk);
        if (vif.valid && vif.ready) begin
          if (vif.we) intr_ap.write(1);
          else        viral_ap.write(1);
        end
      end
    endtask
  endclass

endpackage

