module cpu (
  input clk,
  input rst,
  input little_endian_en,
  output [31:0] memory_addr,
  input [31:0] data_from_memory,
  output reg[31:0] data_to_memory,
  output write_to_memory,  // 1: write, 0: read
  input memory_error
);
  localparam IDLE = 4'b0000, 
             FETCH1 = 4'b0001, 
             FETCH2 = 4'b0010, 
             FETCH3 = 4'b0011, 
             DECODE1 = 4'b0100, 
             DECODE2 = 4'b0101, 
             MEM1 = 4'b0110, 
             MEM2 = 4'b0111, 
             MEM3 = 4'b1000, 
             EXECUTE = 4'b1001,
             WRITE_BACK = 4'b1010,
             DONE = 4'b1011;

  reg [3:0] state;

  reg [31:0] instruction_register;
  reg [31:0] address_register, read_data_register, write_data_register;

  reg [31:0] general_register[0:14];
  reg [31:0] pc;

  // assign memory_addr = (state == FETCH1) ? pc : address_register;
  assign memory_addr = address_register;

  // decoder interface
  reg decode_enable;
  wire decode_valid;
  wire [3:0] dec_opcode;
  wire [3:0] dec_rd;
  wire [3:0] dec_rn;
  wire [3:0] dec_rm;
  wire [1:0] dec_shift;
  wire [4:0] dec_shift_amount;
  wire dec_use_rs;
  wire dec_use_imm32;
  wire dec_use_register;
  wire [3:0] dec_rs;
  wire [3:0] dec_rotate_imm;
  wire [7:0] dec_imm8;
  wire dec_is_load;
  wire dec_is_unsigned_byte;
  wire dec_is_not_postindex;
  wire dec_is_added_offset;
  wire dec_is_branch;
  wire dec_is_write_back;
  wire [11:0] dec_offset_12;
  wire dec_branch_with_link;
  wire [23:0] dec_branch_offset;
  wire [31:0] dec_sign_extended_branch_offset;
  wire dec_access_memory;
  wire positive_branch_offset;

  assign positive_branch_offset = (dec_branch_offset[23] == 0);
  assign dec_sign_extended_branch_offset = (positive_branch_offset == 1) ? {8'h00, dec_branch_offset} : {8'hff, dec_branch_offset};

  instruction_decoder instruction_decoder (
    .clk(clk),
    .enable(decode_enable),
    .instruction(instruction_register),
    .opcode(dec_opcode),
    .rd(dec_rd),
    .rn(dec_rn),
    .rm(dec_rm),
    .shift(dec_shift),
    .shift_amount(dec_shift_amount),
    .use_rs(dec_use_rs),
    .use_imm32(dec_use_imm32),
    .use_register(dec_use_register),
    .rs(dec_rs),
    .rotate_imm(dec_rotate_imm),
    .imm8(dec_imm8),
    .access_memory(dec_access_memory),
    .is_load(dec_is_load),
    .is_unsigned_byte(dec_is_unsigned_byte),
    .is_not_postindex(dec_is_not_postindex),
    .is_added_offset(dec_is_added_offset),
    .is_write_back(dec_is_write_back),
    .offset_12(dec_offset_12),
    .is_branch(dec_is_branch),
    .branch_with_link(dec_branch_with_link),
    .signed_immmed_24(dec_branch_offset),
    .valid(decode_valid)
  );
  assign write_to_memory = (state < DECODE2) ? 0 : instruction_decoder.mem_write;

  // barrel shifter
  reg [31:0] shift_value;
  reg [4:0] shift_amt;
  wire [31:0] shifter_operand;

  barrel_shifter barrel_shifter (
    .shift_in(shift_value),
    .shift_type(dec_shift),
    .shift_imm(shift_amt),
    .rs(dec_rs[7:0]),
    .is_imm_32(dec_use_imm32),
    .is_use_rs(dec_use_rs),
    .carry_in(carry_flag),
    .shifter_operand(shifter_operand),
    .shift_carry_out(carry_flag)
  );

  // interal registers to communicate with ALU
  reg execute_enable;
  reg [31:0] alu_a;     // operand 1. operand 2 from shifter
  wire [31:0] alu_out;  // result

  alu alu (
    .enable(execute_enable),
    .opcode(dec_opcode),
    .operand1(alu_a),
    .operand2(shifter_operand),
    .carry_in(carry_flag),
    .result(alu_out),
    .negative_flag(neg_flag),
    .zero_flag(zero_flag),
    .carry_out_flag(carry_flag)
  );

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      state <= IDLE;
    end else begin
      case (state)
        IDLE: begin
          integer i;
          for (i = 0; i < 15; i = i + 1) begin
            general_register[i] <= 32'd0;
          end

          pc <= 32'h0000_0000;
          address_register <= 32'h0000_0000;
          read_data_register <= 32'd0;
          write_data_register <= 32'd0;

          state <= FETCH1;
        end

        FETCH1: begin
          pc <= pc + 4;
          decode_enable <= 1;
          state <= DECODE1;
        end

        DECODE1: begin
          state <= DECODE2;
        end

        DECODE2: begin
          if (dec_access_memory) begin
            if (dec_use_register) begin
              address_register <= general_register[dec_rn] + general_register[dec_rm];
            end else begin
              address_register <= general_register[dec_rn] + dec_offset_12;
            end
            state <= MEM1;
          end else begin
            if (dec_is_branch) begin
              pc <= pc + 4 + (dec_sign_extended_branch_offset << 2);
              state <= DONE;
            end else begin
              if (dec_use_imm32) begin
                shift_value <= dec_imm8;
                shift_amt <= dec_rotate_imm;
              end else begin
                shift_value <= general_register[dec_rm];
                shift_amt <= dec_shift_amount;
              end
              alu_a <= general_register[dec_rn];
              execute_enable <= 1;
              state <= EXECUTE;
            end
          end
        end

        MEM1: begin
          if (write_to_memory) begin
            write_data_register <= general_register[dec_rd];
          end else begin
            // memory reading..
          end
          state <= MEM2;
        end

        MEM2: begin
          if (write_to_memory) begin
            data_to_memory <= write_data_register;
          end else begin
            read_data_register <= data_from_memory;
          end
          state <= MEM3;
        end

        MEM3: begin
          if (write_to_memory) begin
            // memory writing..
          end else begin
            general_register[dec_rd] <= read_data_register;
          end
          state <= DONE;
        end

        EXECUTE: begin
          state <= WRITE_BACK; 
        end

        WRITE_BACK: begin
          general_register[dec_rd] <= alu_out;
          state <= DONE;
        end

        DONE: begin
          state <= FETCH1;
          execute_enable <= 0;
          decode_enable <= 0;
          address_register <= pc;
        end
      endcase
    end
  end

  always @(data_from_memory) begin
    read_data_register = data_from_memory;
    if (state == DECODE1) begin
      if (little_endian_en)
            instruction_register = (data_from_memory[7:0] << 24)
                                    | (data_from_memory[15:8] << 16)
                                    | (data_from_memory[23:16] << 8)
                                    | (data_from_memory[31:24]);
      else
        instruction_register = data_from_memory;
    end
  end

endmodule
