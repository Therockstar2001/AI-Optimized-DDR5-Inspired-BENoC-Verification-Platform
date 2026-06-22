module benoc_fabric (
  input logic clk,
  input logic rst_n,

  benoc_if.slave  cpu_if,
  benoc_if.slave  ai_if,
  benoc_if.slave  dma_if,
  benoc_if.slave  dbg_if,

  benoc_if.master ddr_if
);

  import benoc_pkg::*;

  logic [3:0] req_valid_vec;
  logic [1:0] req_qos [4];

  logic [3:0] grant;
  logic [1:0] grant_id;
  logic       grant_valid;

  assign req_valid_vec[0] = cpu_if.req_valid;
  assign req_valid_vec[1] = ai_if.req_valid;
  assign req_valid_vec[2] = dma_if.req_valid;
  assign req_valid_vec[3] = dbg_if.req_valid;

  assign req_qos[0] = cpu_if.req_pkt.qos;
  assign req_qos[1] = ai_if.req_pkt.qos;
  assign req_qos[2] = dma_if.req_pkt.qos;
  assign req_qos[3] = dbg_if.req_pkt.qos;

  benoc_arbiter #(
    .NUM_MASTERS(4)
  ) u_arbiter (
    .clk         (clk),
    .rst_n       (rst_n),
    .req_valid   (req_valid_vec),
    .req_qos     (req_qos),
    .grant       (grant),
    .grant_id    (grant_id),
    .grant_valid (grant_valid)
  );

  always_comb begin
    ddr_if.req_valid = 1'b0;
    ddr_if.req_pkt   = '0;

    cpu_if.req_ready = 1'b0;
    ai_if.req_ready  = 1'b0;
    dma_if.req_ready = 1'b0;
    dbg_if.req_ready = 1'b0;

    unique case (grant_id)
      2'd0: begin
        if (grant_valid) begin
          ddr_if.req_valid = cpu_if.req_valid;
          ddr_if.req_pkt   = cpu_if.req_pkt;
          cpu_if.req_ready = ddr_if.req_ready;
        end
      end

      2'd1: begin
        if (grant_valid) begin
          ddr_if.req_valid = ai_if.req_valid;
          ddr_if.req_pkt   = ai_if.req_pkt;
          ai_if.req_ready  = ddr_if.req_ready;
        end
      end

      2'd2: begin
        if (grant_valid) begin
          ddr_if.req_valid = dma_if.req_valid;
          ddr_if.req_pkt   = dma_if.req_pkt;
          dma_if.req_ready = ddr_if.req_ready;
        end
      end

      2'd3: begin
        if (grant_valid) begin
          ddr_if.req_valid = dbg_if.req_valid;
          ddr_if.req_pkt   = dbg_if.req_pkt;
          dbg_if.req_ready = ddr_if.req_ready;
        end
      end

      default: begin
        ddr_if.req_valid = 1'b0;
        ddr_if.req_pkt   = '0;
      end
    endcase
  end

  always_comb begin
    cpu_if.rsp_valid = 1'b0;
    ai_if.rsp_valid  = 1'b0;
    dma_if.rsp_valid = 1'b0;
    dbg_if.rsp_valid = 1'b0;

    cpu_if.rsp_pkt = '0;
    ai_if.rsp_pkt  = '0;
    dma_if.rsp_pkt = '0;
    dbg_if.rsp_pkt = '0;

    ddr_if.rsp_ready = 1'b0;

    if (ddr_if.rsp_valid) begin
      unique case (ddr_if.rsp_pkt.src_id)
        SRC_CPU: begin
          cpu_if.rsp_valid = ddr_if.rsp_valid;
          cpu_if.rsp_pkt   = ddr_if.rsp_pkt;
          ddr_if.rsp_ready = cpu_if.rsp_ready;
        end

        SRC_AI: begin
          ai_if.rsp_valid  = ddr_if.rsp_valid;
          ai_if.rsp_pkt    = ddr_if.rsp_pkt;
          ddr_if.rsp_ready = ai_if.rsp_ready;
        end

        SRC_DMA: begin
          dma_if.rsp_valid = ddr_if.rsp_valid;
          dma_if.rsp_pkt   = ddr_if.rsp_pkt;
          ddr_if.rsp_ready = dma_if.rsp_ready;
        end

        SRC_DBG: begin
          dbg_if.rsp_valid = ddr_if.rsp_valid;
          dbg_if.rsp_pkt   = ddr_if.rsp_pkt;
          ddr_if.rsp_ready = dbg_if.rsp_ready;
        end

        default: begin
          ddr_if.rsp_ready = 1'b1;
        end
      endcase
    end
  end

endmodule