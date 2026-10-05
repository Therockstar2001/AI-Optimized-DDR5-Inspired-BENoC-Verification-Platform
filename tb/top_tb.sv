`timescale 1ns/1ps
import benoc_pkg::*;
import traffic_pkg::*;
module top_tb;

  logic clk;
  logic rst_n;
  logic crc_error_inject;

  traffic_txn txn;

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst_n = 0;
    #20;
    rst_n = 1;
  end

  // BENoC master-side interfaces
  benoc_if cpu_if (.clk(clk), .rst_n(rst_n));
  benoc_if ai_if  (.clk(clk), .rst_n(rst_n));
  benoc_if dma_if (.clk(clk), .rst_n(rst_n));
  benoc_if dbg_if (.clk(clk), .rst_n(rst_n));

  // Fabric -> skid buffer
  benoc_if fabric_skid_if (.clk(clk), .rst_n(rst_n));

  // Skid buffer -> DDR controller
  benoc_if skid_ddr_if (.clk(clk), .rst_n(rst_n));

  // DDR controller -> memory model
  ddr_if mem_if (.clk(clk), .rst_n(rst_n));

  benoc_fabric u_fabric (
    .clk    (clk),
    .rst_n  (rst_n),
    .cpu_if (cpu_if),
    .ai_if  (ai_if),
    .dma_if (dma_if),
    .dbg_if (dbg_if),
    .ddr_if (fabric_skid_if)
  );

  benoc_skid_buffer u_skid_buffer (
    .clk    (clk),
    .rst_n  (rst_n),
    .in_if  (fabric_skid_if),
    .out_if (skid_ddr_if)
  );

  ddr64_ctrl u_ddr64_ctrl (
    .clk   (clk),
    .rst_n (rst_n),
    .crc_error_inject (crc_error_inject),
    .benoc (skid_ddr_if),
    .ddr   (mem_if)
  );

  memory_model u_memory_model (
    .clk   (clk),
    .rst_n (rst_n),
    .ddr   (mem_if)
  );

  benoc_assertions u_benoc_assertions (
    .clk            (clk),
    .rst_n          (rst_n),
    .cpu_if         (cpu_if),
    .ai_if          (ai_if),
    .fabric_skid_if (fabric_skid_if),
    .skid_ddr_if    (skid_ddr_if)
  );

  benoc_scoreboard u_benoc_scoreboard (
    .clk   (clk),
    .rst_n (rst_n),
    .cpu_if(cpu_if),
    .ai_if (ai_if),
    .dma_if(dma_if),
    .dbg_if(dbg_if)
  );

  benoc_perf_monitor u_benoc_perf_monitor (
    .clk            (clk),
    .rst_n          (rst_n),
    .cpu_if         (cpu_if),
    .ai_if          (ai_if),
    .fabric_skid_if (fabric_skid_if),
    .mem_if         (mem_if)
  );

  benoc_coverage u_benoc_coverage (
    .clk   (clk),
    .rst_n (rst_n),
    .cpu_if(cpu_if),
    .ai_if (ai_if)
  );

  task automatic send_cpu_req;
    input qos_e qos;
    input cmd_e cmd;
    input logic [31:0] addr;
    input logic [63:0] data;
    input logic [7:0]  burst_len;

    begin
      @(posedge clk);
      cpu_if.req_valid         <= 1'b1;
      cpu_if.req_pkt.src_id    <= SRC_CPU;
      cpu_if.req_pkt.qos       <= qos;
      cpu_if.req_pkt.cmd       <= cmd;
      cpu_if.req_pkt.addr      <= addr;
      cpu_if.req_pkt.data      <= data;
      cpu_if.req_pkt.burst_len <= burst_len;

      do begin
        @(posedge clk);
      end while (!cpu_if.req_ready);

      cpu_if.req_valid <= 1'b0;
    end
  endtask

  task automatic send_ai_req;
    input qos_e qos;
    input cmd_e cmd;
    input logic [31:0] addr;
    input logic [63:0] data;
    input logic [7:0]  burst_len;

    begin
      @(posedge clk);
      ai_if.req_valid         <= 1'b1;
      ai_if.req_pkt.src_id    <= SRC_AI;
      ai_if.req_pkt.qos       <= qos;
      ai_if.req_pkt.cmd       <= cmd;
      ai_if.req_pkt.addr      <= addr;
      ai_if.req_pkt.data      <= data;
      ai_if.req_pkt.burst_len <= burst_len;

      do begin
        @(posedge clk);
      end while (!ai_if.req_ready);

      ai_if.req_valid <= 1'b0;
    end
  endtask

  task automatic send_dma_req;
    input qos_e qos;
    input cmd_e cmd;
    input logic [31:0] addr;
    input logic [63:0] data;
    input logic [7:0]  burst_len;

    begin
      @(posedge clk);
      dma_if.req_valid         <= 1'b1;
      dma_if.req_pkt.src_id    <= SRC_DMA;
      dma_if.req_pkt.qos       <= qos;
      dma_if.req_pkt.cmd       <= cmd;
      dma_if.req_pkt.addr      <= addr;
      dma_if.req_pkt.data      <= data;
      dma_if.req_pkt.burst_len <= burst_len;

      do begin
        @(posedge clk);
      end while (!dma_if.req_ready);

      dma_if.req_valid <= 1'b0;
    end
  endtask


  task automatic send_dbg_req;
    input qos_e qos;
    input cmd_e cmd;
    input logic [31:0] addr;
    input logic [63:0] data;
    input logic [7:0]  burst_len;

    begin
      @(posedge clk);
      dbg_if.req_valid         <= 1'b1;
      dbg_if.req_pkt.src_id    <= SRC_DBG;
      dbg_if.req_pkt.qos       <= qos;
      dbg_if.req_pkt.cmd       <= cmd;
      dbg_if.req_pkt.addr      <= addr;
      dbg_if.req_pkt.data      <= data;
      dbg_if.req_pkt.burst_len <= burst_len;

      do begin
        @(posedge clk);
      end while (!dbg_if.req_ready);

      dbg_if.req_valid <= 1'b0;
    end
  endtask

  task automatic send_cpu_read;
    input logic [31:0] addr;
    input logic [7:0]  burst_len;

    begin
      @(posedge clk);

      cpu_if.req_valid         <= 1'b1;
      cpu_if.req_pkt.src_id    <= SRC_CPU;
      cpu_if.req_pkt.qos       <= QOS_NORMAL;
      cpu_if.req_pkt.cmd       <= READ;
      cpu_if.req_pkt.addr      <= addr;
      cpu_if.req_pkt.data      <= '0;
      cpu_if.req_pkt.burst_len <= burst_len;

      do begin
        @(posedge clk);
      end while (!cpu_if.req_ready);

      cpu_if.req_valid <= 1'b0;

      // If a previous CPU write response overlaps this read-request
      // acceptance cycle, let that response retire first.
      if (cpu_if.rsp_valid) begin
        do begin
          @(posedge clk);
        end while (cpu_if.rsp_valid);
      end

      wait(cpu_if.rsp_valid && cpu_if.rsp_ready);

      $display("CPU READ RESPONSE DATA = %h",
                cpu_if.rsp_pkt.rdata);
    end
  endtask

  // Read helpers for the remaining BENoC masters.
  // Each task waits for the read response so the directed cross-master
  // tests below complete deterministically.
  task automatic send_ai_read;
    input logic [31:0] addr;
    input logic [7:0]  burst_len;

    begin
      send_ai_req(QOS_NORMAL, READ, addr, 64'h0, burst_len);

      // A previous write response can overlap the cycle in which this read
      // request is accepted.  If so, wait for that response to retire before
      // waiting for this read response.
      if (ai_if.rsp_valid) begin
        do begin
          @(posedge clk);
        end while (ai_if.rsp_valid);
      end

      wait(ai_if.rsp_valid && ai_if.rsp_ready);
      $display("AI READ RESPONSE DATA = %h", ai_if.rsp_pkt.rdata);
    end
  endtask

  task automatic send_dma_read;
    input logic [31:0] addr;
    input logic [7:0]  burst_len;

    begin
      send_dma_req(QOS_NORMAL, READ, addr, 64'h0, burst_len);

      if (dma_if.rsp_valid) begin
        do begin
          @(posedge clk);
        end while (dma_if.rsp_valid);
      end

      wait(dma_if.rsp_valid && dma_if.rsp_ready);
      $display("DMA READ RESPONSE DATA = %h", dma_if.rsp_pkt.rdata);
    end
  endtask

  task automatic send_dbg_read;
    input logic [31:0] addr;
    input logic [7:0]  burst_len;

    begin
      send_dbg_req(QOS_NORMAL, READ, addr, 64'h0, burst_len);

      if (dbg_if.rsp_valid) begin
        do begin
          @(posedge clk);
        end while (dbg_if.rsp_valid);
      end

      wait(dbg_if.rsp_valid && dbg_if.rsp_ready);
      $display("DBG READ RESPONSE DATA = %h", dbg_if.rsp_pkt.rdata);
    end
  endtask

  task automatic inject_backpressure();

      $display("[TEST] Starting backpressure stress");

      repeat (5) begin

          force mem_if.cmd_ready = 1'b0;
          repeat (2) @(posedge clk);
	  release mem_if.cmd_ready;

          force mem_if.wr_ready = 1'b0;
          repeat (2) @(posedge clk);
	  release mem_if.wr_ready;

          force mem_if.rd_ready = 1'b0;
          repeat (2) @(posedge clk);
	  release mem_if.rd_ready;

      end

      $display("[TEST] Backpressure stress complete");

  endtask

  initial begin
    cpu_if.req_valid = 1'b0;
    ai_if.req_valid  = 1'b0;
    dma_if.req_valid = 1'b0;
    dbg_if.req_valid = 1'b0;

    cpu_if.req_pkt = '0;
    ai_if.req_pkt  = '0;
    dma_if.req_pkt = '0;
    dbg_if.req_pkt = '0;

    cpu_if.rsp_ready = 1'b1;
    ai_if.rsp_ready  = 1'b1;
    dma_if.rsp_ready = 1'b1;
    dbg_if.rsp_ready = 1'b1;
    crc_error_inject = 1'b0;

    wait(rst_n);
    @(posedge clk);

    // Existing contention test: CPU write + AI high QoS write
    fork
      send_cpu_req(
        QOS_NORMAL,
        WRITE,
        32'h0000_1000,
        64'hAAAA_BBBB_CCCC_DDDD,
        8
      );

      send_ai_req(
        QOS_HIGH,
        WRITE,
        32'h0000_2000,
        64'h1111_2222_3333_4444,
        16
      );
    join

    inject_backpressure();
    repeat (10) @(posedge clk);

    // CPU readback check
    send_cpu_read(
      32'h0000_1000,
      8
    );

    repeat (10) @(posedge clk);

    // ------------------------------------------------------------
    // 4-MASTER END-TO-END SCOREBOARD TEST
    // ------------------------------------------------------------
    // All addresses below are inside the 1024 x 64-bit memory model
    // (valid byte-address range 0x0000_0000 through 0x0000_1FFF).
    // Each master performs a write, and a different master reads it back.

    // CPU -> AI
    send_cpu_req(
      QOS_NORMAL,
      WRITE,
      32'h0000_0100,
      64'h1111_2222_3333_4444,
      1
    );

    repeat (5) @(posedge clk);

    send_ai_read(
      32'h0000_0100,
      1
    );

    repeat (5) @(posedge clk);

    // AI -> DMA
    send_ai_req(
      QOS_NORMAL,
      WRITE,
      32'h0000_0200,
      64'hAAAA_BBBB_CCCC_DDDD,
      1
    );

    repeat (5) @(posedge clk);

    send_dma_read(
      32'h0000_0200,
      1
    );

    repeat (5) @(posedge clk);

    // DMA -> DBG
    send_dma_req(
      QOS_NORMAL,
      WRITE,
      32'h0000_0300,
      64'h0123_4567_89AB_CDEF,
      1
    );

    repeat (5) @(posedge clk);

    send_dbg_read(
      32'h0000_0300,
      1
    );

    repeat (5) @(posedge clk);

    // DBG -> CPU
    send_dbg_req(
      QOS_NORMAL,
      WRITE,
      32'h0000_0400,
      64'hFEDC_BA98_7654_3210,
      1
    );

    repeat (5) @(posedge clk);

    send_cpu_read(
      32'h0000_0400,
      1
    );

    repeat (10) @(posedge clk);

    // Closure item 1: AI QOS_LOW
    send_ai_req(
      QOS_LOW,
      WRITE,
      32'h0000_3000,
      64'h5555_6666_7777_8888,
      8
    );

    repeat (5) @(posedge clk);

    // Closure item 2: AI QOS_NORMAL
    send_ai_req(
      QOS_NORMAL,
      WRITE,
      32'h0000_4000,
      64'h9999_AAAA_BBBB_CCCC,
      8
    );

    repeat (5) @(posedge clk);

    // Closure item 3: CPU small burst
    send_cpu_req(
      QOS_NORMAL,
      WRITE,
      32'h0000_5000,
      64'h0000_0000_0000_1111,
      1
    );

    repeat (5) @(posedge clk);

    // Closure item 4: CPU large burst
    send_cpu_req(
      QOS_NORMAL,
      WRITE,
      32'h0000_6000,
      64'h2222_3333_4444_5555,
      32
    );

    repeat (5) @(posedge clk);

    // Closure item 5: high address bin
    send_cpu_req(
      QOS_NORMAL,
      WRITE,
      32'h9000_0000,
      64'hDEAD_BEEF_CAFE_1234,
      8
    );

    repeat (10) @(posedge clk);

    // CRC error injection test
    crc_error_inject = 1'b1;

    send_cpu_req(
      QOS_NORMAL,
      WRITE,
      32'h0000_7000,
      64'hCAFE_BABE_DEAD_1234,
      8
    );

    // Hold injection active long enough for DDR S_WRITE phase
    repeat (3) @(posedge clk);

    crc_error_inject = 1'b0;

    repeat (5) @(posedge clk);

    // -----------------------------------
    // Randomized traffic phase
    // -----------------------------------
    // -----------------------------------
    // Full source-randomized stress phase
    // CPU + AI + DMA + DBG
    // -----------------------------------
    repeat (50) begin
      txn = new();

      assert(txn.randomize())
      else $fatal("Randomization failed");

      txn.print();

      // For now, force WRITE to avoid random reads to unwritten addresses
      txn.cmd = WRITE;

      case (txn.src_id)

        SRC_CPU: begin
          send_cpu_req(
            txn.qos,
            txn.cmd,
            txn.addr,
            txn.data,
            txn.burst_len
          );
        end

        SRC_AI: begin
          send_ai_req(
            txn.qos,
            txn.cmd,
            txn.addr,
            txn.data,
            txn.burst_len
          );
        end

        SRC_DMA: begin
          send_dma_req(
            txn.qos,
            txn.cmd,
            txn.addr,
            txn.data,
            txn.burst_len
          );
        end

        SRC_DBG: begin
          send_dbg_req(
            txn.qos,
            txn.cmd,
            txn.addr,
            txn.data,
            txn.burst_len
          );
        end

        default: begin
          $fatal("Illegal src_id generated");
        end

      endcase

      repeat ($urandom_range(1,5)) @(posedge clk);
    end

    // DMA traffic improvement
    repeat (5) begin
      send_dma_req(
        QOS_NORMAL,
        WRITE,
        32'h0000_8000 + ($urandom_range(0, 15) << 3),
        $urandom(),
        $urandom_range(1, 16)
      );

      repeat ($urandom_range(1,3)) @(posedge clk);
    end

    // DBG traffic improvement
    repeat (5) begin
      send_dbg_req(
        QOS_LOW,
        WRITE,
        32'h0000_9000 + ($urandom_range(0, 15) << 3),
        $urandom(),
        $urandom_range(1, 8)
      );

      repeat ($urandom_range(1,3)) @(posedge clk);
    end

    //-----------------------------------
    // CPU VALID + PACKET STABILITY TEST
    //-----------------------------------

    repeat (10) @(posedge clk);

    @(negedge clk);
    force fabric_skid_if.req_ready = 1'b0;

    cpu_if.req_valid         <= 1'b1;
    cpu_if.req_pkt.src_id    <= SRC_CPU;
    cpu_if.req_pkt.qos       <= QOS_NORMAL;
    cpu_if.req_pkt.cmd       <= WRITE;
    cpu_if.req_pkt.addr      <= 32'h0000_0500;
    cpu_if.req_pkt.data      <= 64'h1111_2222_3333_4444;
    cpu_if.req_pkt.burst_len <= 8;

    repeat (3) @(posedge clk);

    @(negedge clk);
    release fabric_skid_if.req_ready;

    do begin
      @(posedge clk);
    end while (!cpu_if.req_ready);

    @(negedge clk);
    cpu_if.req_valid <= 1'b0;

    wait(cpu_if.rsp_valid && cpu_if.rsp_ready);

    repeat (5) @(posedge clk);


    //-----------------------------------
    // AI VALID + PACKET STABILITY TEST
    //-----------------------------------

    repeat (10) @(posedge clk);

    @(negedge clk);
    force fabric_skid_if.req_ready = 1'b0;

    ai_if.req_valid         <= 1'b1;
    ai_if.req_pkt.src_id    <= SRC_AI;
    ai_if.req_pkt.qos       <= QOS_NORMAL;
    ai_if.req_pkt.cmd       <= WRITE;
    ai_if.req_pkt.addr      <= 32'h0000_0600;
    ai_if.req_pkt.data      <= 64'h5555_6666_7777_8888;
    ai_if.req_pkt.burst_len <= 8;

    repeat (3) @(posedge clk);

    @(negedge clk);
    release fabric_skid_if.req_ready;

    do begin
      @(posedge clk);
    end while (!ai_if.req_ready);

    @(negedge clk);
    ai_if.req_valid <= 1'b0;

    wait(ai_if.rsp_valid && ai_if.rsp_ready);

    repeat (5) @(posedge clk);

    //-----------------------------------------
    // CODE COVERAGE TEST 1:
    // Invalid / out-of-range read address
    //-----------------------------------------

    send_cpu_read(
      32'h0000_4000,   // word_addr = 0x4000 >> 3 = 2048, outside MEM_DEPTH=1024
      8
    );

    repeat (10) @(posedge clk);

    //-----------------------------------------
// CODE COVERAGE TEST 2:
// DDR command/write ready backpressure
//-----------------------------------------

    repeat (5) @(posedge clk);

// Hold DDR command/write ready low while CPU issues write
    force mem_if.cmd_ready = 1'b0;
    force mem_if.wr_ready  = 1'b0;

    fork
    begin
      send_cpu_req(
        QOS_NORMAL,
        WRITE,
        32'h0000_C000,
        64'h1357_2468_ABCD_EF01,
        8
      );
    end
    join_none

    repeat (4) @(posedge clk);

    release mem_if.cmd_ready;
    release mem_if.wr_ready;

    repeat (10) @(posedge clk);


    //-----------------------------------------
    // CODE COVERAGE TEST 2B:
    // DDR read ready backpressure
    //-----------------------------------------

    force mem_if.rd_ready = 1'b0;

    fork
    begin
      send_cpu_read(
        32'h0000_1000,
        8
      );
    end
    join_none

    repeat (4) @(posedge clk);

    release mem_if.rd_ready;

    repeat (10) @(posedge clk);

    //-----------------------------------------
    // CODE COVERAGE TEST 3:
    // QOS_CRITICAL traffic from all masters
    //-----------------------------------------

    send_cpu_req(
      QOS_CRITICAL,
      WRITE,
      32'h0000_D000,
      64'hCAFE_BABE_1111_2222,
      8
    );

    repeat (5) @(posedge clk);

    send_ai_req(
      QOS_CRITICAL,
      WRITE,
      32'h0000_D100,
      64'hCAFE_BABE_3333_4444,
      8
    );

    repeat (5) @(posedge clk);

    send_dma_req(
      QOS_CRITICAL,
      WRITE,
      32'h0000_D200,
      64'hCAFE_BABE_5555_6666,
      8
    );

    repeat (5) @(posedge clk);

    send_dbg_req(
      QOS_CRITICAL,
      WRITE,
      32'h0000_D300,
      64'hCAFE_BABE_7777_8888,
      8
    );

    repeat (20) @(posedge clk);

    //-----------------------------------------
    // CODE COVERAGE TEST 4:
    // High-address traffic to toggle upper addr bits
    //-----------------------------------------

    send_cpu_req(
      QOS_CRITICAL,
      WRITE,
      32'h8000_0000,
      64'h1111_2222_3333_4444,
      8
    );

    repeat (5) @(posedge clk);

    send_ai_req(
      QOS_HIGH,
      WRITE,
      32'hC000_0000,
      64'h5555_6666_7777_8888,
      16
    );

    repeat (5) @(posedge clk);

    send_dma_req(
      QOS_NORMAL,
      WRITE,
      32'hF000_0000,
      64'h9999_AAAA_BBBB_CCCC,
      32
    );

    repeat (5) @(posedge clk);

    send_dbg_req(
      QOS_LOW,
      WRITE,
      32'hFFFF_FFF8,
      64'hDDDD_EEEE_FFFF_0000,
      64
    );

    repeat (10) @(posedge clk);

    send_cpu_read(
      32'hFFFF_FFF8,
      64
    );

    repeat (20) @(posedge clk);

    //-----------------------------------------
    // CODE COVERAGE TEST 5:
    // Data pattern stress for rdata/data toggle coverage
    //-----------------------------------------

    send_cpu_req(
      QOS_NORMAL,
      WRITE,
      32'h0000_E000,
      64'hFFFF_FFFF_FFFF_FFFF,
      8
    );

    repeat (5) @(posedge clk);

    send_cpu_read(
      32'h0000_E000,
      8
    );

    repeat (5) @(posedge clk);

    send_cpu_req(
      QOS_NORMAL,
      WRITE,
      32'h0000_E008,
      64'h0000_0000_0000_0000,
      8
    );

    repeat (5) @(posedge clk);

    send_cpu_read(
      32'h0000_E008,
      8
    );

    repeat (5) @(posedge clk);

    send_cpu_req(
      QOS_NORMAL,
      WRITE,
      32'h0000_E010,
      64'hAAAA_AAAA_AAAA_AAAA,
      8
    );

    repeat (5) @(posedge clk);

    send_cpu_read(
      32'h0000_E010,
      8
    );

    repeat (5) @(posedge clk);

    send_cpu_req(
      QOS_NORMAL,
      WRITE,
      32'h0000_E018,
      64'h5555_5555_5555_5555,
      8
    );

    repeat (5) @(posedge clk);

    send_cpu_read(
      32'h0000_E018,
      8
    );

    repeat (20) @(posedge clk);

    //-----------------------------------------
    // CODE COVERAGE TEST 6:
    // Toggle burst_len[7] and addr[2:0]
    //-----------------------------------------

    send_cpu_req(
      QOS_HIGH,
      WRITE,
      32'h0000_E003,              // addr[2:0] = 3'b011
      64'h0F0F_F0F0_A5A5_5A5A,
      8'd128                      // burst_len[7] = 1
    );

    repeat (5) @(posedge clk);

    send_ai_req(
      QOS_CRITICAL,
      WRITE,
      32'h0000_E005,              // addr[2:0] = 3'b101
      64'hF0F0_0F0F_5A5A_A5A5,
      8'd128
    );

    repeat (5) @(posedge clk);

    send_dma_req(
      QOS_NORMAL,
      WRITE,
      32'h0000_E007,              // addr[2:0] = 3'b111
      64'h1234_ABCD_5678_EF90,
      8'd128
    );

    repeat (5) @(posedge clk);

    send_dbg_req(
      QOS_LOW,
      WRITE,
      32'hFFFF_FFFD,              // high addr + addr[2:0] = 3'b101
      64'hFEDC_BA98_7654_3210,
      8'd128
    );

    repeat (10) @(posedge clk);

    send_cpu_read(
      32'h0000_E003,
      8'd128
    );

    repeat (20) @(posedge clk);

    // Final self-check: no mismatches, no orphaned expected responses,
    // and both READ/WRITE traffic observed from every master.
    u_benoc_scoreboard.final_check();

    u_benoc_perf_monitor.print_report();

    $finish;
  end

endmodule