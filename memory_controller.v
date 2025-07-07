module memory_controller(
  input clk,
  input rst,
  // input cpu_read_mem,
  input cpu_write_mem, //  read(0)
  input [31:0] addr,
  input [31:0] idata_from_cpu,
  output reg [31:0] odata_to_cpu,
  output reg error
);
  wire bram_selected, sram_selected, flash_selected, peripheral_selected;
  wire [31:0] bram_odata, sram_odata, flash_odata, peripheral_odata;
  reg [31:0] bram_idata, sram_idata, flash_idata, peripheral_idata;
  wire decode_error, flash_error;
  wire cpu_read_mem;
  assign cpu_read_mem = ~cpu_write_mem;

  address_decoder addr_dec(
    .addr(addr),
    .bram_select(bram_selected),
    .sram_select(sram_selected),
    .flash_select(flash_selected),
    .peripheral_select(peripheral_selected),
    .error(decode_error)
  );

  bram bram_mem(
    .clk(clk),
    .rst(rst),
    .rd_en(cpu_read_mem && bram_selected),
    .wr_en(cpu_write_mem && bram_selected),
    .addr(addr[15:0]),
    .idata(bram_idata),
    .odata(bram_odata)
  );

  sram sram_mem(
    .clk(clk),
    .rst(rst),
    .rd_en(cpu_read_mem && sram_selected),
    .wr_en(cpu_write_mem && sram_selected),
    .addr(addr[15:0]),
    .idata(sram_idata),
    .odata(sram_odata)
  );


  flash flash_mem(
    .clk(clk),
    .rd_en(cpu_read_mem && flash_selected),
    .wr_en(cpu_write_mem && flash_selected),
    .erase_en(flash_erase),
    .addr(addr[11:0]),
    .idata(flash_idata),
    .odata(flash_odata),
    .busy(flash_busy),
    .error(flash_error)
  );

  peripheral peripheral_mem(
    .clk(clk),
    .rd_en(cpu_read_mem && peripheral_selected),
    .wr_en(cpu_write_mem && peripheral_selected),
    .addr(addr[11:0]),
    .idata(peripheral_idata),
    .odata(peripheral_odata)
  );

  initial begin
    // $monitor("[MEM][CTL] [%0t]  %b\n\t[r=%b/w=%b] b:%b, s:%b, f:%b, p:%b\n\tread: 0x%08x\twrite: 0x%08x",
    //  $realtime, error, cpu_read_mem, cpu_write_mem, bram_selected, sram_selected, flash_selected, peripheral_selected, odata_to_cpu, idata_from_cpu);
    odata_to_cpu = 32'd0;
    error = 0;
  end

  always @(*) begin
    error = 0;
    if (decode_error) error = 1;
    else if (flash_error) error = 1;
    else begin
      if (cpu_read_mem) begin
        if (bram_selected) odata_to_cpu = bram_odata;
        else if (sram_selected) odata_to_cpu = sram_odata;
        else if (flash_selected) odata_to_cpu = flash_odata;
        else if (peripheral_selected) odata_to_cpu = peripheral_odata;
        else error = 1;
        $display("[%0t][MEM][CTL] %b   [r=%b/w=%b] b:%b, s:%b, f:%b, p:%b read: 0x%08x", 
            $realtime, error, cpu_read_mem, cpu_write_mem, bram_selected, sram_selected, flash_selected, peripheral_selected, odata_to_cpu);
      end else if (cpu_write_mem) begin
        if (bram_selected) bram_idata = idata_from_cpu;
        else if (sram_selected) sram_idata = idata_from_cpu;
        else if (flash_selected) flash_idata = idata_from_cpu;
        else if (peripheral_selected) peripheral_idata = idata_from_cpu;
        else error = 1;
      end else begin
        $display("[%0t][MEM][CTL] unknown error", $realtime);
        error = 1;
      end
    end
  end

endmodule
