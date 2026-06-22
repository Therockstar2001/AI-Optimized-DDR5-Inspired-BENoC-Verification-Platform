module benoc_skid_buffer (
  input  logic clk,
  input  logic rst_n,

  // Input side (from BENoC fabric)
  benoc_if.slave in_if,

  // Output side (to DDR controller)
  benoc_if.master out_if
);

  import benoc_pkg::*;

  benoc_pkt_t pkt_q;
  logic       valid_q;

  // Input ready when buffer empty
  assign in_if.req_ready = !valid_q;

  // Output signals
  assign out_if.req_valid = valid_q;
  assign out_if.req_pkt   = pkt_q;

  // Response path passthrough
  assign out_if.rsp_ready = in_if.rsp_ready;

  assign in_if.rsp_valid  = out_if.rsp_valid;
  assign in_if.rsp_pkt    = out_if.rsp_pkt;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid_q <= 1'b0;
      pkt_q   <= '0;
    end
    else begin

      // Capture incoming request
      if (in_if.req_valid && in_if.req_ready) begin
        pkt_q   <= in_if.req_pkt;
        valid_q <= 1'b1;
      end

      // Release when downstream accepts
      if (out_if.req_valid && out_if.req_ready) begin
        valid_q <= 1'b0;
      end

    end
  end

endmodule