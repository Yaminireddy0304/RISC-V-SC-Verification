// regfile.sv
module regfile (
  input  logic        clk,
  input  logic        we,
  input  logic [4:0]  ra1, ra2, wa,
  input  logic [31:0] wd,
  output logic [31:0] rd1, rd2
);
  logic [31:0] regs [31];

  // x0 is hardwired to 0
  assign rd1 = (ra1==0) ? 32'd0 : regs[ra1];
  assign rd2 = (ra2==0) ? 32'd0 : regs[ra2];

  initial begin
    integer i;
    for (i=0;i<32;i=i+1) regs[i] = 32'd0;
  end

  always_ff @(posedge clk) begin
    if (we && (wa != 5'd0)) regs[wa] <= wd;
  end
endmodule
