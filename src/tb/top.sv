module top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // --------------------------------------------------------------------------
  // Clock / Reset
  // --------------------------------------------------------------------------
  logic clk;
  logic rst_n;

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk; // 100 MHz
  end

  initial begin
    rst_n = 1'b0;
    #100 rst_n = 1'b1;
  end

  // --------------------------------------------------------------------------
  // Interface instance shared by DUT and TB
  // --------------------------------------------------------------------------
  simple_bus_if tb_if (.clk(clk), .rst_n(rst_n));

  // --------------------------------------------------------------------------
  // DUT (expects modport 'dut' inside the module port declaration)
  //   module simple_dut (simple_bus_if.dut bus);
  // --------------------------------------------------------------------------
  simple_dut u_dut (.bus(tb_if));

  // --------------------------------------------------------------------------
  // UVM bring-up: make the virtual interface visible to TB components
  // --------------------------------------------------------------------------
  initial begin
    // Provide vif to anything under uvm_test_top.env.*
    uvm_config_db#(virtual simple_bus_if)::set(null, "uvm_test_top.env.*", "vif", tb_if);

    // Launch test; pick one via +UVM_TESTNAME=avry_tests_pkg::avry_test_reset_traffic (etc.)
    run_test();
  end

endmodule

