module bram (
  input clk,
  input rst,
  input rd_en,
  input wr_en,
  input [15:0] addr,
  input [31:0] idata,
  output reg [31:0] odata
);
  reg [31:0] memory [0:16383];
  wire [13:0] word_addr;   // log2(16384)
  assign word_addr = addr[15:2];


  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      integer i;
      for (i = 0; i < 16383; i=i+1) begin
        memory[i] = 32'd0;
      end
      odata <= 32'd0;
    end else begin
      if (wr_en) begin
        memory[word_addr] <= idata;
      end
      if (rd_en) begin
        odata <= memory[word_addr];
      end
    end
  end

endmodule
