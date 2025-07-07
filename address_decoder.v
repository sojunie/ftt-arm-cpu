module address_decoder(
  input [31:0] addr,
  output reg bram_select,
  output reg sram_select,
  output reg flash_select,
  output reg peripheral_select,
  output reg error
);
  always @(*) begin
    bram_select = 0;
    sram_select = 0;
    flash_select = 0;
    peripheral_select = 0;
    error = 0;
    $display("[%0t][MEM][DEC] %b    addr: 0x%08x", $realtime, error, addr);
    case (addr[31:16])
      16'h0000: flash_select = 1;
      16'h0001: bram_select = 1;
      16'h0002: sram_select = 1;
      16'h0003: peripheral_select = 1;
      default: begin
        $display("[%0t][MEM][DEC] error:  invalid address range", $realtime);
        bram_select = 0;
        sram_select = 0;
        flash_select = 0;
        peripheral_select = 0;
        error = 1;
      end
    endcase
  end

endmodule
