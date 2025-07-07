module barrel_shifter (
  input [31:0] shift_in,   // rm or imm8
  input [1:0] shift_type,
  input [4:0] shift_imm,   // immediate shift(5-bit shift_imm, 0~31) & 32-bit immediate(4-bit rotate_imm, 0~15)
  input [7:0] rs, // 8-bit rs[7:0] (0~256)
  input is_imm_32,   // from bit[25]
  input is_use_rs,   // from bit[4]
  input carry_in,    // from C flag?
  output reg [31:0] shifter_operand,
  output reg shift_carry_out
);
  localparam LSL = 2'b00,  // logigal shift left
             LSR = 2'b01,  // logical shift right
             ASR = 2'b10,  // arithmetic shift right
             ROR = 2'b11;  // rotate right

  wire [7:0] shift_amount;
  wire [3:0] rotate_imm;
  wire [7:0] imm8;

  assign shift_amount = is_use_rs ? rs : {3'd0, shift_imm};
  assign rotate_imm = is_imm_32 ? shift_imm[3:0] : shift_imm;
  assign imm8 = shift_in[7:0];

  always @(*) begin
    if (is_imm_32) begin
      shifter_operand = (imm8 >> (rotate_imm * 2)) | (imm8 << (32 - (rotate_imm * 2)));
      if (rotate_imm == 0) begin
        shift_carry_out = carry_in;
      end else begin
        shift_carry_out = shifter_operand[31];
      end
    end else begin
      // Directly from register value
      if (shift_type == 2'd0 && shift_imm == 5'd0 && is_imm_32 == 1'b0) begin
        shifter_operand = shift_in;
        shift_carry_out = carry_in;
      end else begin
        case (shift_type)
          LSL: begin
            if (shift_amount == 0) begin
              shifter_operand = shift_in;
              shift_carry_out = carry_in;
            end
            else if (shift_amount < 32) begin
              shifter_operand = (shift_in << shift_amount);
              shift_carry_out = shift_in[32-shift_amount];
            end
            else if (shift_amount == 32) begin
              shifter_operand = 32'd0;
              shift_carry_out = shift_in[0];
            end
            else begin
              shifter_operand = 32'd0;
              shift_carry_out = 0;
            end
          end

          LSR: begin
            if (shift_amount == 0) begin
              shifter_operand = 32'd0;
              shift_carry_out = shift_in[31];
            end 
            else if (shift_amount < 32) begin
              shifter_operand = (shift_in >> shift_amount);
              shift_carry_out = shift_in[shift_amount-1];
            end
            else if (shift_amount == 32) begin
              shifter_operand = 32'd0;
              shift_carry_out = shift_in[31];
            end
            else begin
              shifter_operand = 32'd0;
              shift_carry_out = 0;
            end
          end

          ASR: begin
            if (shift_amount == 0) begin
              if (is_use_rs) begin
                shifter_operand = shift_in;
                shift_carry_out = carry_in;
              end else begin
                if (shift_in[31] == 0) begin
                  shifter_operand = 32'd0;
                  shift_carry_out = shift_in[31];
                end else begin
                  shifter_operand = 32'hffff_ffff;
                  shift_carry_out = shift_in[31];
                end
              end
            end 
            else if (shift_amount < 32) begin
              shifter_operand = $signed(shift_in) >>> shift_amount;
              shift_carry_out = shift_in[shift_amount-1];
            end
            else begin
              if (is_use_rs) begin
                if (shift_in[31] == 0) begin
                  shifter_operand = 32'd0;
                  shift_carry_out = shift_in[31];
                end else begin
                  shifter_operand = 32'hffff_ffff;
                  shift_carry_out = shift_in[31];
                end
              end
            end
          end

          ROR: begin
            if (is_use_rs) begin
              if (shift_amount == 0) begin
                shifter_operand = shift_in;
                shift_carry_out = carry_in;
              end
              else if (shift_amount[4:0] == 5'd0) begin
                shifter_operand = shift_in;
                shift_carry_out = shift_in[31];
              end
              else begin
                shifter_operand = (shift_in >> shift_amount[4:0]) | (shift_in << (32-shift_amount[4:0]));
                shift_carry_out = shift_in[shift_amount[4:0]-1];
              end
            end else begin
              if (shift_amount == 0) begin
                // rrx operation
                shifter_operand = (shift_in >> 1) | (carry_in << 31);
                shift_carry_out = shift_in[0];
              end else begin
                shifter_operand = (shift_in >> shift_amount) | (shift_in << (32-shift_amount));
                shift_carry_out = shift_in[shift_amount-1];
              end
            end
          end
          default: begin
          end
        endcase
      end
    end
  end

endmodule
