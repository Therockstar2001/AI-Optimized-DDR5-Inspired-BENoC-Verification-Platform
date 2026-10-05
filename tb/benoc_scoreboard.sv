module benoc_scoreboard #(
  parameter int MEM_DEPTH = 1024
)(
  input logic clk,
  input logic rst_n,

  benoc_if.monitor cpu_if,
  benoc_if.monitor ai_if,
  benoc_if.monitor dma_if,
  benoc_if.monitor dbg_if
);

  import benoc_pkg::*;

  localparam logic [63:0] OUT_OF_RANGE_DATA = 64'hDEAD_DEAD_DEAD_DEAD;

  // The memory model is 64-bit word addressed internally.  Keep the
  // reference model indexed by word address so unaligned byte addresses
  // alias exactly the same way as memory_model.sv (addr[31:3]).
  logic [63:0] expected_mem [logic [31:0]];

  // Every BENoC request receives a response, including writes.  Queue one
  // expected response per master so the scoreboard remains correct when a
  // master has another request buffered before its previous response returns.
  typedef struct packed {
    cmd_e        cmd;
    logic [31:0] addr;
    logic [63:0] exp_rdata;
  } expected_rsp_t;

  expected_rsp_t cpu_exp_q[$];
  expected_rsp_t ai_exp_q[$];
  expected_rsp_t dma_exp_q[$];
  expected_rsp_t dbg_exp_q[$];

  int unsigned pass_count;
  int unsigned fail_count;

  int unsigned cpu_read_count;
  int unsigned cpu_write_count;
  int unsigned cpu_rsp_count;

  int unsigned ai_read_count;
  int unsigned ai_write_count;
  int unsigned ai_rsp_count;

  int unsigned dma_read_count;
  int unsigned dma_write_count;
  int unsigned dma_rsp_count;

  int unsigned dbg_read_count;
  int unsigned dbg_write_count;
  int unsigned dbg_rsp_count;

  function automatic logic [31:0] word_index(input logic [31:0] addr);
    return (addr >> 3);
  endfunction

  function automatic logic [63:0] expected_read_data(input logic [31:0] addr);
    logic [31:0] idx;

    idx = word_index(addr);

    if (idx >= MEM_DEPTH)
      return OUT_OF_RANGE_DATA;
    else if (expected_mem.exists(idx))
      return expected_mem[idx];
    else
      // memory_model.sv clears all locations to zero on reset.
      return 64'h0000_0000_0000_0000;
  endfunction

  function automatic string src_name(input src_id_e src);
    case (src)
      SRC_CPU: return "CPU";
      SRC_AI : return "AI";
      SRC_DMA: return "DMA";
      SRC_DBG: return "DBG";
      default: return "UNKNOWN";
    endcase
  endfunction

  task automatic record_request(
    input src_id_e   interface_src,
    input benoc_pkt_t pkt
  );
    expected_rsp_t exp;
    logic [31:0] idx;

    begin
      exp.cmd       = pkt.cmd;
      exp.addr      = pkt.addr;
      exp.exp_rdata = 64'h0;

      // The physical master interface and the packet source ID must agree.
      if (pkt.src_id != interface_src) begin
        fail_count++;
        $error("[SB FAIL] %s request carries wrong src_id=%0d",
               src_name(interface_src), pkt.src_id);
      end

      if (pkt.cmd == WRITE) begin
        idx = word_index(pkt.addr);

        // Mirror memory_model.sv: out-of-range writes complete but do not
        // modify storage.
        if (idx < MEM_DEPTH) begin
          expected_mem[idx] = pkt.data;
          $display("[SB] %s WRITE CAPTURED ADDR=%h WORD_IDX=%0d DATA=%h",
                   src_name(interface_src), pkt.addr, idx, pkt.data);
        end
        else begin
          $display("[SB] %s OUT-OF-RANGE WRITE ADDR=%h ignored by reference memory",
                   src_name(interface_src), pkt.addr);
        end

        case (interface_src)
          SRC_CPU: cpu_write_count++;
          SRC_AI : ai_write_count++;
          SRC_DMA: dma_write_count++;
          SRC_DBG: dbg_write_count++;
          default: ;
        endcase
      end
      else begin
        // Snapshot the expected data when the read request is accepted.
        // This prevents a later write to the same address from changing the
        // expected value for an already-outstanding read.
        exp.exp_rdata = expected_read_data(pkt.addr);

        $display("[SB] %s READ CAPTURED ADDR=%h EXPECTED=%h",
                 src_name(interface_src), pkt.addr, exp.exp_rdata);

        case (interface_src)
          SRC_CPU: cpu_read_count++;
          SRC_AI : ai_read_count++;
          SRC_DMA: dma_read_count++;
          SRC_DBG: dbg_read_count++;
          default: ;
        endcase
      end

      case (interface_src)
        SRC_CPU: cpu_exp_q.push_back(exp);
        SRC_AI : ai_exp_q.push_back(exp);
        SRC_DMA: dma_exp_q.push_back(exp);
        SRC_DBG: dbg_exp_q.push_back(exp);
        default: begin
          fail_count++;
          $error("[SB FAIL] Illegal interface source %0d", interface_src);
        end
      endcase
    end
  endtask

  task automatic check_response(
    input src_id_e   interface_src,
    input benoc_rsp_t rsp
  );
    expected_rsp_t exp;
    bit have_expected;
    bit response_pass;

    begin
      have_expected = 1'b1;
      response_pass = 1'b1;
      exp            = '0;

      case (interface_src)
        SRC_CPU: begin
          cpu_rsp_count++;
          if (cpu_exp_q.size() == 0)
            have_expected = 1'b0;
          else
            exp = cpu_exp_q.pop_front();
        end

        SRC_AI: begin
          ai_rsp_count++;
          if (ai_exp_q.size() == 0)
            have_expected = 1'b0;
          else
            exp = ai_exp_q.pop_front();
        end

        SRC_DMA: begin
          dma_rsp_count++;
          if (dma_exp_q.size() == 0)
            have_expected = 1'b0;
          else
            exp = dma_exp_q.pop_front();
        end

        SRC_DBG: begin
          dbg_rsp_count++;
          if (dbg_exp_q.size() == 0)
            have_expected = 1'b0;
          else
            exp = dbg_exp_q.pop_front();
        end

        default: begin
          have_expected = 1'b0;
        end
      endcase

      if (!have_expected) begin
        fail_count++;
        $error("[SB FAIL] Unexpected %s response with no queued request: SRC=%0d DATA=%h ERR=%b",
               src_name(interface_src), rsp.src_id, rsp.rdata, rsp.error);
      end
      else begin
        if (rsp.src_id != interface_src) begin
          response_pass = 1'b0;
          $error("[SB FAIL] %s response carries wrong src_id=%0d",
                 src_name(interface_src), rsp.src_id);
        end

        // Current controller contract always returns error=0. CRC failures are
        // detected in the memory model but are not propagated upstream yet.
        if (rsp.error !== 1'b0) begin
          response_pass = 1'b0;
          $error("[SB FAIL] %s unexpected response error for ADDR=%h ERR=%b",
                 src_name(interface_src), exp.addr, rsp.error);
        end

        if (exp.cmd == READ) begin
          if (rsp.rdata !== exp.exp_rdata) begin
            response_pass = 1'b0;
            $error("[SB FAIL] %s READ ADDR=%h EXPECTED=%h GOT=%h",
                   src_name(interface_src), exp.addr, exp.exp_rdata, rsp.rdata);
          end
          else begin
            $display("[SB PASS] %s READ ADDR=%h DATA=%h",
                     src_name(interface_src), exp.addr, rsp.rdata);
          end
        end
        else begin
          // ddr64_ctrl.sv returns zero read-data for write completions.
          if (rsp.rdata !== 64'h0) begin
            response_pass = 1'b0;
            $error("[SB FAIL] %s WRITE response ADDR=%h expected RDATA=0, GOT=%h",
                   src_name(interface_src), exp.addr, rsp.rdata);
          end
          else begin
            $display("[SB PASS] %s WRITE COMPLETE ADDR=%h",
                     src_name(interface_src), exp.addr);
          end
        end

        if (response_pass)
          pass_count++;
        else
          fail_count++;
      end
    end
  endtask

  // Monitor all four master interfaces.  A request is recorded only on a
  // completed ready/valid handshake, and a response is checked only when the
  // response handshake completes.
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      expected_mem.delete();

      cpu_exp_q.delete();
      ai_exp_q.delete();
      dma_exp_q.delete();
      dbg_exp_q.delete();

      pass_count      = 0;
      fail_count      = 0;

      cpu_read_count  = 0;
      cpu_write_count = 0;
      cpu_rsp_count   = 0;

      ai_read_count   = 0;
      ai_write_count  = 0;
      ai_rsp_count    = 0;

      dma_read_count  = 0;
      dma_write_count = 0;
      dma_rsp_count   = 0;

      dbg_read_count  = 0;
      dbg_write_count = 0;
      dbg_rsp_count   = 0;
    end
    else begin
      if (cpu_if.req_valid && cpu_if.req_ready)
        record_request(SRC_CPU, cpu_if.req_pkt);

      if (ai_if.req_valid && ai_if.req_ready)
        record_request(SRC_AI, ai_if.req_pkt);

      if (dma_if.req_valid && dma_if.req_ready)
        record_request(SRC_DMA, dma_if.req_pkt);

      if (dbg_if.req_valid && dbg_if.req_ready)
        record_request(SRC_DBG, dbg_if.req_pkt);

      if (cpu_if.rsp_valid && cpu_if.rsp_ready)
        check_response(SRC_CPU, cpu_if.rsp_pkt);

      if (ai_if.rsp_valid && ai_if.rsp_ready)
        check_response(SRC_AI, ai_if.rsp_pkt);

      if (dma_if.rsp_valid && dma_if.rsp_ready)
        check_response(SRC_DMA, dma_if.rsp_pkt);

      if (dbg_if.rsp_valid && dbg_if.rsp_ready)
        check_response(SRC_DBG, dbg_if.rsp_pkt);
    end
  end

  task automatic print_report;
    begin
      $display("============================================");
      $display(" BENoC 4-MASTER SCOREBOARD REPORT");
      $display("============================================");
      $display(" CPU: reads=%0d writes=%0d responses=%0d pending=%0d",
               cpu_read_count, cpu_write_count, cpu_rsp_count, cpu_exp_q.size());
      $display(" AI : reads=%0d writes=%0d responses=%0d pending=%0d",
               ai_read_count, ai_write_count, ai_rsp_count, ai_exp_q.size());
      $display(" DMA: reads=%0d writes=%0d responses=%0d pending=%0d",
               dma_read_count, dma_write_count, dma_rsp_count, dma_exp_q.size());
      $display(" DBG: reads=%0d writes=%0d responses=%0d pending=%0d",
               dbg_read_count, dbg_write_count, dbg_rsp_count, dbg_exp_q.size());
      $display(" Passed responses = %0d", pass_count);
      $display(" Failed checks     = %0d", fail_count);
      $display("============================================");
    end
  endtask

  task automatic final_check;
    int unsigned pending_total;
    bit all_masters_exercised;

    begin
      pending_total = cpu_exp_q.size() + ai_exp_q.size()
                    + dma_exp_q.size() + dbg_exp_q.size();

      all_masters_exercised =
          (cpu_read_count  > 0) && (cpu_write_count > 0)
       && (ai_read_count   > 0) && (ai_write_count  > 0)
       && (dma_read_count  > 0) && (dma_write_count > 0)
       && (dbg_read_count  > 0) && (dbg_write_count > 0);

      print_report();

      if (pending_total != 0)
        $fatal(1, "[SB FINAL FAIL] %0d expected responses are still pending", pending_total);

      if (!all_masters_exercised)
        $fatal(1, "[SB FINAL FAIL] Regression did not exercise both READ and WRITE on all four masters");

      if (fail_count != 0)
        $fatal(1, "[SB FINAL FAIL] Scoreboard detected %0d failures", fail_count);

      $display("[SB FINAL PASS] All four masters completed READ/WRITE checking with no scoreboard mismatches");
    end
  endtask

endmodule