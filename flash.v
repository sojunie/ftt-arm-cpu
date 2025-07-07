/**
  * Flash doesn't have nRST port. 
  * Because the flash memory doesn't have to clear data even thouth a reset signal is low.
  */
module flash(
  input clk,
  input rd_en,
  input wr_en,
  input erase_en,
  input [11:0] addr,
  input [31:0] idata,
  output reg[31:0] odata,
  output reg busy,
  output reg error
);
  localparam IDLE = 2'b00, READ = 2'b01, WRITE = 2'b10, ERASE = 2'b11;
  reg [1:0] state;

  reg [31:0] memory [0:1023];
  wire [9:0] word_addr;
  assign word_addr = addr[11:2];

  // Only for debug
  initial begin
    $readmemb("bootrom.bin.txt", memory);
    $display("mem[0] 0x%08x mem[1] 0x%08x mem[2] 0x%08x mem[3] 0x%08x", memory[0], memory[1], memory[2], memory[3]);
    odata = 32'd0;
    busy = 0;
    error = 0;
  end

  always @(posedge clk) begin
    case (state)
      IDLE: begin
        busy <= 0;
        error <= 0;

        if (rd_en) begin
          $display("[%0t] FLASH read [%d] 0x%08x", $realtime, word_addr, memory[word_addr]);
          odata <= memory[word_addr];
          state <= READ;
        end else if (wr_en) begin
          // Already cleaned~
          if (memory[word_addr] == 32'd0) begin
            memory[word_addr] <= idata;
            state <= WRITE;
          end else begin
            $display("[MEM][FLASH] write to non-erased area");
            error <= 1;
          end
        end else if (erase_en) begin
          // CHECK: Erase whole memory? or from addr?
          integer i;
          for (i = 0; i < 1023; i=i+1) begin
            memory[i] <= 32'd0;
          end
          state <= ERASE;
        end

      end

      READ: begin
        state <= IDLE;
      end

      WRITE: begin
        busy <= 1;
        state <= IDLE;
      end

      ERASE: begin
        busy <= 1;
        state <= IDLE;
      end

      default: begin
        state <= IDLE;
      end
    endcase
  end

endmodule
