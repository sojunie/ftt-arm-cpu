module peripheral(
  input clk,
  input rst,
  input rd_en,
  input wr_en,
  input [11:0] addr,
  input [31:0] idata,
  output reg [31:0] odata
);

endmodule
