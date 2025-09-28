// src/dut/simple_dut.sv
module simple_dut(simple_bus_if.dut bus);
    logic [31:0] mem [0:255];

    always_ff @(posedge bus.clk or negedge bus.rst_n) begin
        if (!bus.rst_n) begin
            for (int i = 0; i < 256; i++)
                mem[i] <= '0;
            bus.rdata     <= '0;
            bus.rvalid    <= 0;
            bus.gnt       <= 0;
            bus.intr      <= 0;
            bus.viral_state <= 0;
        end else begin
            bus.gnt <= bus.req;

            if (bus.we) begin
                mem[bus.waddr] <= bus.wdata;
            end

            if (bus.re) begin
                bus.rdata  <= mem[bus.raddr];
                bus.rvalid <= 1;
            end else begin
                bus.rvalid <= 0;
            end

            // Raise interrupt if read data = magic pattern
            if (bus.rdata == 32'hDEAD_BEEF)
                bus.intr <= 1;
            else
                bus.intr <= 0;
        end
    end
endmodule

