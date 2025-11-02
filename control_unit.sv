// control_unit.sv
module control_unit (
  input  logic [6:0] opcode,
  input  logic [2:0] funct3,
  input  logic [6:0] funct7,
  output logic       reg_write,
  output logic       mem_to_reg,
  output logic       mem_read,
  output logic       mem_write,
  output logic       branch,
  output logic       alu_src,    // 1 if second operand is immediate
  output logic [3:0] alu_ctrl,   // ALU operation
  output logic       jump
);
  // default values
  always_comb begin
    reg_write  = 0;
    mem_to_reg = 0;
    mem_read   = 0;
    mem_write  = 0;
    branch     = 0;
    alu_src    = 0;
    alu_ctrl   = 4'h0;
    jump       = 0;

    case (opcode)
      7'b0110011: begin // R-type
        reg_write = 1;
        alu_src = 0;
        case ({funct7,funct3})
          10'b0000000000: alu_ctrl = 4'h0; // ADD
          10'b0100000000: alu_ctrl = 4'h1; // SUB
          10'b0000000111: alu_ctrl = 4'h2; // AND
          10'b0000000110: alu_ctrl = 4'h3; // OR
          10'b0000000100: alu_ctrl = 4'h4; // XOR
          10'b0000000001: alu_ctrl = 4'h5; // SLL
          10'b0000000101: alu_ctrl = 4'h6; // SRL
          10'b0100000101: alu_ctrl = 4'h7; // SRA
          10'b0000000010: alu_ctrl = 4'h8; // SLT
          10'b0000000011: alu_ctrl = 4'h9; // SLTU
          default: alu_ctrl = 4'h0;
        endcase
      end

      7'b0010011: begin // I-type ALU (ADDI, ANDI,...)
        reg_write = 1;
        alu_src = 1;
        case (funct3)
          3'b000: alu_ctrl = 4'h0; // ADDI
          3'b111: alu_ctrl = 4'h2; // ANDI
          3'b110: alu_ctrl = 4'h3; // ORI
          3'b100: alu_ctrl = 4'h4; // XORI
          3'b001: alu_ctrl = 4'h5; // SLLI
          3'b101: begin
            if (funct7 == 7'b0000000) alu_ctrl = 4'h6; // SRLI
            else alu_ctrl = 4'h7; // SRAI
          end
          default: alu_ctrl = 4'h0;
        endcase
      end

      7'b0000011: begin // LW
        reg_write = 1;
        mem_to_reg = 1;
        mem_read = 1;
        alu_src = 1;
        alu_ctrl = 4'h0; // ADD for address calc
      end

      7'b0100011: begin // SW
        mem_write = 1;
        alu_src = 1;
        alu_ctrl = 4'h0; // ADD
      end

      7'b1100011: begin // BEQ/BNE/BLT etc. (branch)
        branch = 1;
        alu_src = 0;
        case (funct3)
          3'b000: alu_ctrl = 4'h1; // SUB (for BEQ)
          3'b100: alu_ctrl = 4'h8; // SLT (BLT)
          default: alu_ctrl = 4'h1;
        endcase
      end

      7'b1101111: begin // JAL
        reg_write = 1;
        jump = 1;
        alu_src = 0;
      end

      default: begin
        // NOP / unsupported
      end
    endcase
  end
endmodule
