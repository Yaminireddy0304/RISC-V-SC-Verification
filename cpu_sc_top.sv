// cpu_sc_top.sv - single-cycle CPU; instruction is provided externally (by testbench IMEM)
module cpu_sc_top (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [31:0] instr_i,   // externally supplied instruction (testbench IMEM)
  input  logic [31:0] pc_i,      // externally supply PC (testbench will increment)
  output logic [31:0] pc_next_o, // next PC (pc+4 or branch/jump)
  // debug signals
  output logic [31:0] alu_res_o,
  output logic [31:0] rd2_o,
  output logic [31:0] reg_write_data_o,
  output logic [4:0]  reg_write_addr_o,
  output logic        reg_write_en_o
);

  // parsed fields
  logic [6:0] opcode;
  logic [4:0] rd, rs1, rs2;
  logic [2:0] funct3;
  logic [6:0] funct7;

  assign opcode = instr_i[6:0];
  assign rd     = instr_i[11:7];
  assign funct3 = instr_i[14:12];
  assign rs1    = instr_i[19:15];
  assign rs2    = instr_i[24:20];
  assign funct7 = instr_i[31:25];

  // wires
  logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;
  logic [31:0] reg_rdata1, reg_rdata2;
  logic [31:0] alu_b;
  logic [31:0] alu_res;
  logic        zero_flag;

  // control
  logic reg_write, mem_to_reg, mem_read, mem_write, branch, alu_src, jump;
  logic [3:0] alu_ctrl;

  // modules
  imm_gen immgen(.instr(instr_i), .imm_i(imm_i), .imm_s(imm_s), .imm_b(imm_b), .imm_u(imm_u), .imm_j(imm_j));
  control_unit cu(.opcode(opcode), .funct3(funct3), .funct7(funct7),
                  .reg_write(reg_write), .mem_to_reg(mem_to_reg), .mem_read(mem_read),
                  .mem_write(mem_write), .branch(branch), .alu_src(alu_src), .alu_ctrl(alu_ctrl), .jump(jump));

  // register file instance
  regfile rf(.clk(clk), .we(reg_write), .ra1(rs1), .ra2(rs2), .wa(rd), .wd(reg_write_data_o),
             .rd1(reg_rdata1), .rd2(reg_rdata2));

  // data memory instance
  logic [31:0] mem_rd;
  data_mem dmem(.clk(clk), .mem_write(mem_write), .mem_read(mem_read), .addr(alu_res), .wd(reg_rdata2), .rd(mem_rd));

  // ALU operand selection
  assign alu_b = alu_src ? imm_i : reg_rdata2;
  alu u_alu(.a(reg_rdata1), .b(alu_b), .alu_ctrl(alu_ctrl), .result(alu_res), .zero(zero_flag));

  // PC update (simplified)
  always_comb begin
    pc_next_o = pc_i + 32'd4;
    if (jump) pc_next_o = pc_i + imm_j;
    else if (branch) begin
      if (zero_flag) pc_next_o = pc_i + imm_b;
    end
  end

  // writeback mux
  always_comb begin
    if (mem_to_reg) reg_write_data_o = mem_rd;
    else reg_write_data_o = alu_res;
  end

  // debug outputs
  assign alu_res_o = alu_res;
  assign rd2_o = reg_rdata2;
  assign reg_write_addr_o = rd;
  assign reg_write_en_o = reg_write;

endmodule
