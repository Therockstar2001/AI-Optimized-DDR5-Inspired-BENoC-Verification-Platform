module benoc_perf_monitor (
  input logic clk,
  input logic rst_n,

  benoc_if.monitor cpu_if,
  benoc_if.monitor ai_if,
  benoc_if.monitor fabric_skid_if,
  ddr_if.monitor   mem_if
);

  int cycle_count;
  int cpu_req_count;
  int ai_req_count;
  int total_req_count;
  int write_cmd_count;
  int read_cmd_count;
  int response_count;
  int stall_count;

  int current_cycle;

  int cpu_req_start_cycle;
  int cpu_latency;

  int total_latency;
  int max_latency;
  int min_latency;
  int latency_samples;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cycle_count         <= 0;
      cpu_req_count       <= 0;
      ai_req_count        <= 0;
      total_req_count     <= 0;
      write_cmd_count     <= 0;
      read_cmd_count      <= 0;
      response_count      <= 0;
      stall_count         <= 0;

      current_cycle       <= 0;

      cpu_req_start_cycle <= 0;
      cpu_latency         <= 0;

      total_latency       <= 0;
      max_latency         <= 0;
      min_latency         <= 999999;
      latency_samples     <= 0;
    end
    else begin
      current_cycle <= current_cycle + 1;
      cycle_count   <= cycle_count + 1;

      // Count accepted CPU requests and record issue cycle
      if (cpu_if.req_valid && cpu_if.req_ready) begin
        cpu_req_start_cycle <= current_cycle;
        cpu_req_count       <= cpu_req_count + 1;
        total_req_count     <= total_req_count + 1;
      end

      // Count accepted AI requests
      if (ai_if.req_valid && ai_if.req_ready) begin
        ai_req_count    <= ai_req_count + 1;
        total_req_count <= total_req_count + 1;
      end

      // Count DDR commands
      if (mem_if.cmd_valid && mem_if.cmd_ready) begin
        if (mem_if.cmd_write)
          write_cmd_count <= write_cmd_count + 1;
        else
          read_cmd_count <= read_cmd_count + 1;
      end

      // Count CPU/AI responses
      if (cpu_if.rsp_valid || ai_if.rsp_valid) begin
        response_count <= response_count + 1;
      end

      // Measure CPU request-response latency
      if (cpu_if.rsp_valid) begin
        cpu_latency = current_cycle - cpu_req_start_cycle;

        total_latency   <= total_latency + cpu_latency;
        latency_samples <= latency_samples + 1;

        if (cpu_latency > max_latency)
          max_latency <= cpu_latency;

        if (cpu_latency < min_latency)
          min_latency <= cpu_latency;

        $display("[PERF] CPU LATENCY = %0d cycles", cpu_latency);
      end

      // Count fabric backpressure stalls
      if (fabric_skid_if.req_valid && !fabric_skid_if.req_ready) begin
        stall_count <= stall_count + 1;
      end
    end
  end

  task automatic print_report;
    $display("====================================");
    $display(" BENoC PERFORMANCE REPORT");
    $display("====================================");
    $display(" Total cycles       = %0d", cycle_count);
    $display(" CPU requests       = %0d", cpu_req_count);
    $display(" AI requests        = %0d", ai_req_count);
    $display(" Total requests     = %0d", total_req_count);
    $display(" DDR write commands = %0d", write_cmd_count);
    $display(" DDR read commands  = %0d", read_cmd_count);
    $display(" Responses          = %0d", response_count);
    $display(" Stall cycles       = %0d", stall_count);

    if (cycle_count != 0) begin
      $display(" Request throughput = %0f req/cycle",
               real'(total_req_count) / real'(cycle_count));
    end

    if (latency_samples != 0) begin
      $display(" Avg CPU latency    = %0f cycles",
               real'(total_latency) / real'(latency_samples));

      $display(" Max CPU latency    = %0d cycles", max_latency);
      $display(" Min CPU latency    = %0d cycles", min_latency);
      $display(" Latency samples    = %0d", latency_samples);
    end

    $display("====================================");
  endtask

endmodule