module memory_model #(
  parameter int MEM_DEPTH = 1024
)(
  input logic clk,
  input logic rst_n,

  ddr_if.phy ddr
);

  logic [63:0] mem [0:MEM_DEPTH-1];
  logic [31:0] read_addr_q;
  logic        read_pending;

  logic [7:0] expected_crc;

  wire [31:0] word_addr = ddr.cmd_addr[31:3];

  crc8 u_crc8_check (
    .data_i(ddr.wr_data),
    .crc_o (expected_crc)
  );

  assign ddr.cmd_ready = 1'b1;
  assign ddr.wr_ready  = 1'b1;
  assign ddr.dqs_valid = ddr.wr_valid || ddr.rd_valid;
  assign ddr.rd_crc    = 8'h00;

  integer i;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ddr.rd_valid <= 1'b0;
      ddr.rd_data  <= '0;
      read_addr_q  <= '0;
      read_pending <= 1'b0;

      for (i = 0; i < MEM_DEPTH; i++) begin
        mem[i] <= '0;
      end
    end
    else begin

      if (ddr.cmd_valid && ddr.cmd_ready) begin

        if (ddr.cmd_write) begin

          if (ddr.wr_valid && ddr.wr_ready) begin

            if (expected_crc == ddr.wr_crc) begin
              $display("[CRC PASS] ADDR=%h DATA=%h CRC=%h",
                       ddr.cmd_addr,
                       ddr.wr_data,
                       ddr.wr_crc);
            end
            else begin
              $display("[CRC FAIL] ADDR=%h EXPECTED=%h GOT=%h DATA=%h",
                       ddr.cmd_addr,
                       expected_crc,
                       ddr.wr_crc,
                       ddr.wr_data);
            end

            if (word_addr < MEM_DEPTH) begin
              mem[word_addr] <= ddr.wr_data;
            end
          end

        end
        else begin
          read_addr_q  <= word_addr;
          read_pending <= 1'b1;
        end
      end

      if (read_pending) begin
        ddr.rd_valid <= 1'b1;
        ddr.rd_data  <= (read_addr_q < MEM_DEPTH)
                       ? mem[read_addr_q]
                       : 64'hDEAD_DEAD_DEAD_DEAD;
        read_pending <= 1'b0;
      end
      else if (ddr.rd_valid && ddr.rd_ready) begin
        ddr.rd_valid <= 1'b0;
      end

    end
  end

endmodule