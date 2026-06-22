module benoc_arbiter #(
  parameter int NUM_MASTERS = 4
)(
  input  logic clk,
  input  logic rst_n,

  input  logic [NUM_MASTERS-1:0] req_valid,
  input  var logic [1:0]         req_qos [NUM_MASTERS],

  output logic [NUM_MASTERS-1:0] grant,
  output logic [$clog2(NUM_MASTERS)-1:0] grant_id,
  output logic grant_valid
);

  logic [$clog2(NUM_MASTERS)-1:0] rr_ptr;
  integer k;
  int idx;

  always_comb begin
    grant       = '0;
    grant_id    = rr_ptr;
    grant_valid = 1'b0;

    for (k = 0; k < NUM_MASTERS; k++) begin
      idx = (rr_ptr + k) % NUM_MASTERS;

      if (!grant_valid && req_valid[idx]) begin
        grant_id    = idx[$clog2(NUM_MASTERS)-1:0];
        grant_valid = 1'b1;
      end
    end

    if (grant_valid) begin
      grant[grant_id] = 1'b1;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rr_ptr <= '0;
    end else if (grant_valid) begin
      rr_ptr <= grant_id + 1'b1;
    end
  end

endmodule