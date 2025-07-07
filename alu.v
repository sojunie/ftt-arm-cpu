module alu #(
  parameter DATA_WIDTH=32
)(
  input enable,
  input [3:0] opcode,
  input [DATA_WIDTH-1:0] operand1,
  input [DATA_WIDTH-1:0] operand2,
  input carry_in,
  input enable_flag_update,  // enable CPSR flag update, from s suffix
  output reg [DATA_WIDTH-1:0] result,
  output reg negative_flag,
  output reg zero_flag,
  output reg carry_out_flag,
  output reg overflow_flag
);
  reg [DATA_WIDTH:0] alu_out;
  wire [DATA_WIDTH:0] alu_a;
  wire [DATA_WIDTH:0] alu_b;
  wire [DATA_WIDTH:0] alu_two_comple_a;
  wire [DATA_WIDTH:0] alu_two_comple_b;
  wire not_affect_overflow;

  assign alu_a = {1'b0, operand1};
  assign alu_b = {1'b0, operand2};
  assign alu_two_comple_a = {1'b0, ~operand1} + 1'b1;
  assign alu_two_comple_b = {1'b0, ~operand2} + 1'b1;
  assign not_affect_overflow = opcode == OPCODE_AND
                              || opcode == OPCODE_EOR
                              || opcode == OPCODE_ORR
                              || opcode == OPCODE_MOV
                              || opcode == OPCODE_MVN
                              || opcode == OPCODE_BIC;

  localparam OPCODE_AND = 4'b0000,
             OPCODE_EOR = 4'b0001,
             OPCODE_SUB = 4'b0010,
             OPCODE_RSB = 4'b0011,
             OPCODE_ADD = 4'b0100,
             OPCODE_ADC = 4'b0101,
             OPCODE_SBC = 4'b0110,
             OPCODE_RSC = 4'b0111,
             OPCODE_TST = 4'b1000,
             OPCODE_TEQ = 4'b1001,
             OPCODE_CMP = 4'b1010,
             OPCODE_CMN = 4'b1011,
             OPCODE_ORR = 4'b1100,
             OPCODE_MOV = 4'b1101,
             OPCODE_BIC = 4'b1110,
             OPCODE_MVN = 4'b1111;

  always @(*) begin
    if (enable) begin
      alu_out = 0;
      // $display("[ALU] a: %09x, b: %09x", alu_a, alu_b);
      case (opcode)
        OPCODE_AND: alu_out = alu_a & alu_b;
        OPCODE_EOR: alu_out = alu_a ^ alu_b;
        OPCODE_ORR: alu_out = alu_a | alu_b;
        OPCODE_MOV: alu_out = alu_b;
        OPCODE_MVN: alu_out = {1'b0, ~operand2};
        OPCODE_BIC: alu_out = alu_a & {1'b0, ~operand2};

        OPCODE_SUB: alu_out = alu_a + alu_two_comple_b;
        OPCODE_RSB: alu_out = alu_b + alu_two_comple_a;
        OPCODE_ADD: alu_out = alu_a + alu_b;
        OPCODE_ADC: alu_out = alu_a + alu_b + carry_in;
        OPCODE_SBC: alu_out = alu_a + alu_two_comple_b - ~carry_in;
        OPCODE_RSC: alu_out = alu_b + alu_two_comple_a - ~carry_in;

        OPCODE_TST: alu_out = alu_a & alu_b;
        OPCODE_TEQ: alu_out = alu_a ^ alu_b;
        OPCODE_CMP: alu_out = alu_a + alu_two_comple_b;
        OPCODE_CMN: alu_out = alu_a + alu_b;
        
        default: result = 0;
      endcase

      result = alu_out[DATA_WIDTH-1:0];
      if (enable_flag_update) begin
        zero_flag = (result == 0);
        negative_flag = result[DATA_WIDTH-1];
        if (!not_affect_overflow) begin
          overflow_flag = (operand1[DATA_WIDTH-1] & operand2[DATA_WIDTH-1] & ~result[DATA_WIDTH-1]) 
                          | (~operand1[DATA_WIDTH-1] & ~operand2[DATA_WIDTH-1] & result[DATA_WIDTH-1]);
          carry_out_flag = alu_out[DATA_WIDTH];
        end else begin
          carry_out_flag = carry_in;
        end
      end
    end
  end

endmodule
