interface ddr_if #(parameter int DATA_W = 64,
                   parameter int ADDR_W = 32)
(
  input logic clk,
  input logic rst_n
);

  logic              cmd_valid;
  logic              cmd_ready;
  logic              cmd_write;
  logic [ADDR_W-1:0] cmd_addr;
  logic [7:0]        burst_len;

  logic              wr_valid;
  logic              wr_ready;
  logic [DATA_W-1:0] wr_data;
  logic [7:0]        wr_crc;

  logic              rd_valid;
  logic              rd_ready;
  logic [DATA_W-1:0] rd_data;
  logic [7:0]        rd_crc;

  logic              dqs_valid;
  logic [1:0]        freq_ratio;

  modport ctrl (
    input  clk,
    input  rst_n,
    output cmd_valid,
    input  cmd_ready,
    output cmd_write,
    output cmd_addr,
    output burst_len,

    output wr_valid,
    input  wr_ready,
    output wr_data,
    output wr_crc,

    input  rd_valid,
    output rd_ready,
    input  rd_data,
    input  rd_crc,

    input  dqs_valid,
    output freq_ratio
  );

  modport phy (
    input  clk,
    input  rst_n,
    input  cmd_valid,
    output cmd_ready,
    input  cmd_write,
    input  cmd_addr,
    input  burst_len,

    input  wr_valid,
    output wr_ready,
    input  wr_data,
    input  wr_crc,

    output rd_valid,
    input  rd_ready,
    output rd_data,
    output rd_crc,

    output dqs_valid,
    input  freq_ratio
  );

  modport monitor (
    input clk,
    input rst_n,
    input cmd_valid,
    input cmd_ready,
    input cmd_write,
    input cmd_addr,
    input burst_len,
    input wr_valid,
    input wr_ready,
    input wr_data,
    input wr_crc,
    input rd_valid,
    input rd_ready,
    input rd_data,
    input rd_crc,
    input dqs_valid,
    input freq_ratio
  );

endinterface