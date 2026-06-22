interface benoc_if #(parameter int DATA_W = 64,
                     parameter int ADDR_W = 32)
(
  input logic clk,
  input logic rst_n
);

  import benoc_pkg::*;

  logic        req_valid;
  logic        req_ready;
  benoc_pkt_t  req_pkt;

  logic        rsp_valid;
  logic        rsp_ready;
  benoc_rsp_t  rsp_pkt;

  modport master (
    input  clk,
    input  rst_n,
    output req_valid,
    input  req_ready,
    output req_pkt,
    input  rsp_valid,
    output rsp_ready,
    input  rsp_pkt
  );

  modport slave (
    input  clk,
    input  rst_n,
    input  req_valid,
    output req_ready,
    input  req_pkt,
    output rsp_valid,
    input  rsp_ready,
    output rsp_pkt
  );

  modport monitor (
    input clk,
    input rst_n,
    input req_valid,
    input req_ready,
    input req_pkt,
    input rsp_valid,
    input rsp_ready,
    input rsp_pkt
  );

endinterface