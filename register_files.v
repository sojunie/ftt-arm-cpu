module register_files(
  input clk,
  input wr,
  input [3:0] rn, rm, rd,
  input [31:0] din,
  output reg [31:0] dout1,
  output reg [31:0] dout2,
);
  reg [31:0] register [0:15];

  always @(*) begin
    dout1 = register[rn];
    dout2 = register[rm];
  end

  always @(posedge clk) begin
    if (wr) register[rd] <= din;
  end

endmodule
