interface simple_bus_if (
  input  logic clk,
  input  logic rst_n
);
  // Handshake + payload
  logic        valid;
  logic        ready;
  logic        we;         // 1=write, 0=read
  logic [31:0] addr;
  logic [31:0] wdata;
  logic [31:0] rdata;

  // Driver modport: drives request, observes ready/rdata
  modport drv (
    input  clk, rst_n, ready, rdata,
    output valid, we, addr, wdata
  );

  // Monitor modport: observes everything
  modport mon (
    input  clk, rst_n, valid, ready, we, addr, wdata, rdata
  );

  // DUT modport: observes request, drives ready/rdata
  modport dut (
    input  clk, rst_n, valid, we, addr, wdata,
    output ready, rdata
  );

endinterface

