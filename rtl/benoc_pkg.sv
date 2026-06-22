package benoc_pkg;

  parameter int DATA_W = 64;
  parameter int ADDR_W = 32;
  parameter int LEN_W  = 8;
  parameter int NUM_MASTERS = 4;

  typedef enum logic [1:0] {
    SRC_CPU   = 2'b00,
    SRC_AI    = 2'b01,
    SRC_DMA   = 2'b10,
    SRC_DBG   = 2'b11
  } src_id_e;

  typedef enum logic [1:0] {
    QOS_LOW      = 2'b00,
    QOS_NORMAL   = 2'b01,
    QOS_HIGH     = 2'b10,
    QOS_CRITICAL = 2'b11
  } qos_e;

  typedef enum logic {
    READ  = 1'b0,
    WRITE = 1'b1
  } cmd_e;

  typedef struct packed {
    src_id_e              src_id;
    qos_e                 qos;
    cmd_e                 cmd;
    logic [ADDR_W-1:0]    addr;
    logic [DATA_W-1:0]    data;
    logic [LEN_W-1:0]     burst_len;
  } benoc_pkt_t;

  typedef struct packed {
    src_id_e              src_id;
    logic                 error;
    logic [DATA_W-1:0]    rdata;
  } benoc_rsp_t;

endpackage