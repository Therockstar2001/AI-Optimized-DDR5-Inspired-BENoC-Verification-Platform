module benoc_scoreboard (
  input logic clk,
  input logic rst_n,

  benoc_if.monitor cpu_if
);
  
  import benoc_pkg::*;
  logic [63:0] expected_mem [logic [31:0]];

  // Track writes
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      expected_mem.delete();
    end
    else begin

      // Capture CPU write requests
      if (cpu_if.req_valid &&
          cpu_if.req_ready &&
          cpu_if.req_pkt.cmd == WRITE) begin

        expected_mem[cpu_if.req_pkt.addr] = cpu_if.req_pkt.data;

        $display("[SB] WRITE CAPTURED ADDR=%h DATA=%h",
                  cpu_if.req_pkt.addr,
                  cpu_if.req_pkt.data);
      end

      // Check read responses
      if (cpu_if.rsp_valid && cpu_if.rsp_pkt.rdata != 64'h0) begin

        if (expected_mem.exists(32'h0000_1000)) begin

          if (cpu_if.rsp_pkt.rdata
              == expected_mem[32'h0000_1000]) begin

            $display("[SB PASS] READ MATCH DATA=%h",
                      cpu_if.rsp_pkt.rdata);

          end
          else begin

            $error("[SB FAIL] EXPECTED=%h GOT=%h",
                    expected_mem[32'h0000_1000],
                    cpu_if.rsp_pkt.rdata);

          end
        end
      end
    end
  end

endmodule