module mcu(
  input clk,
  input rst
);
  wire [31:0] address_bus;
  wire [31:0] data_in_bus;
  wire [31:0] data_out_bus;

  wire write_data_to_mem;
  wire mem_error;
 
  cpu cpu_core(
    .clk(clk),
    .rst(rst),
    .little_endian_en(1'b1),
    .memory_addr(address_bus),
    .data_from_memory(data_in_bus),
    .data_to_memory(data_out_bus),
    .write_to_memory(write_data_to_mem),
    .memory_error(mem_error)
  );

  memory_controller mem_ctrl(
    .clk(clk),
    .rst(rst),
    .cpu_write_mem(write_data_to_mem),
    .addr(address_bus),
    .idata_from_cpu(data_out_bus),
    .odata_to_cpu(data_in_bus),
    .error(mem_error)
  );

endmodule
