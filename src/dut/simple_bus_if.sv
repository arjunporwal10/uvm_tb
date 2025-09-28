// src/dut/simple_bus_if.sv
interface simple_bus_if(input logic clk, input logic rst_n);
    // Request/Grant handshake
    logic req;
    logic gnt;

    // Write data channel
    logic        we;
    logic [31:0] waddr;
    logic [31:0] wdata;

    // Read data channel
    logic        re;
    logic [31:0] raddr;
    logic [31:0] rdata;
    logic        rvalid;

    // Interrupt / status lines
    logic intr;
    logic viral_state;

    // Modports
    modport dut (input  clk, rst_n, req, we, waddr, wdata, re, raddr,
                 output gnt, rdata, rvalid, intr, viral_state);

    modport drv (output req, we, waddr, wdata, re, raddr,
                 input  gnt, rdata, rvalid);

    modport mon (input clk, rst_n, req, we, waddr, wdata,
                 re, raddr, rdata, gnt, rvalid, intr, viral_state);
endinterface

