module crc8 (
  input  logic [63:0] data_i,
  output logic [7:0]  crc_o
);

  integer i;
  logic [7:0] crc;

  always_comb begin
    crc = 8'h00;

    for (i = 0; i < 64; i++) begin
      crc = {crc[6:0], crc[7] ^ data_i[i]};
    end

    crc_o = crc;
  end

endmodule