// Simple DUT that implements a one-beat VALID/READY handshake
// Interface: simple_bus_if.dut (see simple_bus_if.sv)

module simple_dut (
  simple_bus_if.dut bus
);

  // Simple 1KB memory (256 x 32-bit)
  logic [31:0] mem [0:255];

  // Reset memory on power-up (optional)
  initial begin : init_mem
    integer i;
    for (i = 0; i < 256; i = i + 1) mem[i] = '0;
  end

  // Address decode (word address from [9:2])
  function automatic int unsigned word_index(input logic [31:0] a);
    word_index = a[9:2];
  endfunction

  // Simple handshake: READY is high whenever out of reset (single-cycle ready)
  // Reads return rdata = mem[addr] on the same cycle as VALID&READY (simple model)
  // Writes update mem[addr] on VALID&READY when we==1
  always_ff @(posedge bus.clk or negedge bus.rst_n) begin
    if (!bus.rst_n) begin
      bus.ready <= 1'b0;
      bus.rdata <= '0;
    end
    else begin
      bus.ready <= 1'b1; // always ready (no backpressure)

      // Serve read data by default (combinational read sampled on clk)
      // If you prefer registered read latency, move this into the if(valid) block.
      bus.rdata <= mem[word_index(bus.addr)];

      if (bus.valid && bus.ready) begin
        if (bus.we) begin
          // WRITE
          mem[word_index(bus.addr)] <= bus.wdata;
        end
        else begin
          // READ: rdata already set from mem above
        end
      end
    end
  end

endmodule

