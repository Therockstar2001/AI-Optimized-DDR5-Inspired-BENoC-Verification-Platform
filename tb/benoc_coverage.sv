module benoc_coverage (
  input logic clk,
  input logic rst_n,

  benoc_if.monitor cpu_if,
  benoc_if.monitor ai_if
);

  import benoc_pkg::*;

  covergroup benoc_cg @(posedge clk);

    // -----------------------------
    // CPU command coverage
    // -----------------------------

    cpu_cmd_cp : coverpoint cpu_if.req_pkt.cmd
    iff (cpu_if.req_valid && cpu_if.req_ready)
    {
      bins read_bin  = {READ};
      bins write_bin = {WRITE};
    }

    // -----------------------------
    // AI QoS coverage
    // -----------------------------

    ai_qos_cp : coverpoint ai_if.req_pkt.qos
    iff (ai_if.req_valid && ai_if.req_ready)
    {
      bins low_bin    = {QOS_LOW};
      bins normal_bin = {QOS_NORMAL};
      bins high_bin   = {QOS_HIGH};
    }

    // -----------------------------
    // Burst length coverage
    // -----------------------------

    cpu_burst_cp : coverpoint cpu_if.req_pkt.burst_len
    iff (cpu_if.req_valid && cpu_if.req_ready)
    {
      bins small_burst = {[1:4]};
      bins med_burst   = {[5:16]};
      bins large_burst = {[17:32]};
    }

    // -----------------------------
    // Address coverage
    // -----------------------------

    addr_cp : coverpoint cpu_if.req_pkt.addr
    iff (cpu_if.req_valid && cpu_if.req_ready)
    {
      bins low_addr  = {[32'h0000_0000 : 32'h0000_FFFF]};
      bins high_addr = {[32'h0001_0000 : 32'hFFFF_FFFF]};
    }

    // -----------------------------
    // Read response coverage
    // -----------------------------

    rsp_cp : coverpoint cpu_if.rsp_valid
    {
      bins rsp_seen = {1};
    }

  endgroup

  benoc_cg cg;

  initial begin
    cg = new();
  end

endmodule