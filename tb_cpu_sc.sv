// tb_cpu_sc.sv - testbench with instruction assembler and simple program
`timescale 1ns/1ps
module tb_cpu_sc;
  logic clk, rst_n;
  logic [31:0] pc;
  logic [31:0] instr;
  logic [31:0] pc_next;
  logic [31:0] alu_res;
  logic [31:0] rd2;
  logic [31:0] wdata;
  logic [4:0]  waddr;
  logic        wen;

  // instantiate CPU
  cpu_sc_top cpu(.clk(clk), .rst_n(rst_n), .instr_i(instr), .pc_i(pc), .pc_next_o(pc_next),
                 .alu_res_o(alu_res), .rd2_o(rd2), .reg_write_data_o(wdata), .reg_write_addr_o(waddr), .reg_write_en_o(wen));

  // clock
  initial clk = 0;
  always #5 clk = ~clk; // 100 MHz style (period 10 ns)

  // simple instruction memory inside testbench
  logic [31:0] imem [0:127];
  integer i;

  // Assembler helper functions (construct 32-bit instructions)
  function automatic logic [31:0] encode_rtype(input int funct7, input int rs2, input int rs1, input int funct3, input int rd, input int opcode);
    encode_rtype = (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode;
  endfunction

  function automatic logic [31:0] encode_itype(input int imm12, input int rs1, input int funct3, input int rd, input int opcode);
    encode_itype = ((imm12 & 12'hFFF) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode;
  endfunction

  function automatic logic [31:0] encode_stype(input int imm12, input int rs2, input int rs1, input int funct3, input int opcode);
    logic [11:0] imm;
    imm = imm12 & 12'hFFF;
    encode_stype = ((imm[11:5]) << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | ((imm[4:0]) << 7) | opcode;
  endfunction

  function automatic logic [31:0] encode_btype(input int imm13, input int rs2, input int rs1, input int funct3, input int opcode);
    logic [12:0] imm;
    imm = imm13 & 13'h1FFF;
    encode_btype = ((imm[12]) << 31) | ((imm[10:5]) << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | ((imm[4:1]) << 8) | ((imm[11]) << 7) | opcode;
  endfunction

  // opcode constants (subset)
  localparam OPC_RTYPE = 7'b0110011;
  localparam OPC_ITYPE = 7'b0010011;
  localparam OPC_LOAD  = 7'b0000011;
  localparam OPC_STORE = 7'b0100011;
  localparam OPC_BRANCH= 7'b1100011;
  localparam OPC_JAL   = 7'b1101111;

  // funct3/funct7 constants for important instructions
  // e.g., ADD: funct7=0, funct3=0
  initial begin
    // clear imem
    for (i=0;i<128;i=i+1) imem[i] = 32'h00000013; // NOP (ADDI x0,x0,0)

    // Program:
    // addi x1, x0, 10   ; x1 = 10
    // addi x2, x0, 20   ; x2 = 20
    // add  x3, x1, x2   ; x3 = 30
    // addi x4, x3, 5    ; x4 = 35
    // (store x4 to memory addr 0) sw x4, 0(x0)
    // lw x5, 0(x0)      ; x5 = 35
    // add x6, x5, x1    ; x6 = 45

    imem[0] = encode_itype(10, 0, 3'b000, 1, OPC_ITYPE); // addi x1,x0,10
    imem[1] = encode_itype(20, 0, 3'b000, 2, OPC_ITYPE); // addi x2,x0,20
    imem[2] = encode_rtype(7'b0000000, 2, 1, 3'b000, 3, OPC_RTYPE); // add x3,x1,x2
    imem[3] = encode_itype(5, 3, 3'b000, 4, OPC_ITYPE); // addi x4,x3,5
    imem[4] = encode_stype(0, 4, 0, 3'b010, OPC_STORE); // sw x4, 0(x0)
    imem[5] = encode_itype(0, 0, 3'b010, 5, OPC_LOAD); // lw x5, 0(x0)
    imem[6] = encode_rtype(7'b0000000, 1, 5, 3'b000, 6, OPC_RTYPE); // add x6,x5,x1
    imem[7] = encode_itype(0,0,3'b000,0,OPC_ITYPE); // NOP; end

    // reset & run
    rst_n = 0; pc = 0;
    #20 rst_n = 1;
    #5;

    // waveform dump (Questa will save wlf)
    $dumpvars(0, tb_cpu_sc);

    // run for several cycles
    for (i=0;i<20;i=i+1) begin
      instr = imem[pc >> 2];
      @(posedge clk);
      // update PC next cycle
      pc = cpu.pc_next_o; // read next pc from cpu
      #1;
    end

    // print some register/file info via observed writebacks (you can also probe regfile by dump)
    $display("Final writeback: addr=%0d en=%0b data=%0d", waddr, wen, wdata);
    $writememh("dmem_out.mem", imem);
    $finish;
  end

  // configure waveform saving for QuestaSim:
  initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0, tb_cpu_sc);
  end
endmodule
