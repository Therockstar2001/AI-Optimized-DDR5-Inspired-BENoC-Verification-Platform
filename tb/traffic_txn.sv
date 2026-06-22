package traffic_pkg;

  import benoc_pkg::*;

  class traffic_txn;

    rand src_id_e src_id;
    rand qos_e    qos;
    rand cmd_e    cmd;

    rand logic [31:0] addr;
    rand logic [63:0] data;
    rand logic [7:0]  burst_len;

    constraint c_src {
      src_id inside {SRC_CPU, SRC_AI, SRC_DMA, SRC_DBG};
    }

    constraint c_addr_align {
      addr[2:0] == 3'b000;
    }

    constraint c_burst {
      burst_len inside {[1:32]};
    }

    constraint c_addr_range {
      addr inside {
        [32'h0000_0000 : 32'h0000_FFFF],
        [32'h9000_0000 : 32'h9000_FFFF]
      };
    }

    constraint c_cmd_dist {
      cmd dist {
        READ  := 40,
        WRITE := 60
      };
    }

    constraint c_qos_dist {
      qos dist {
        QOS_LOW    := 20,
        QOS_NORMAL := 50,
        QOS_HIGH   := 30
      };
    }

    function void print();
      $display("--------------------------------");
      $display(" RANDOM TRAFFIC TXN");
      $display("--------------------------------");
      $display(" SRC_ID    = %0d", src_id);
      $display(" QOS       = %0d", qos);
      $display(" CMD       = %0d", cmd);
      $display(" ADDR      = %h", addr);
      $display(" DATA      = %h", data);
      $display(" BURST_LEN = %0d", burst_len);
      $display("--------------------------------");
    endfunction

  endclass

endpackage