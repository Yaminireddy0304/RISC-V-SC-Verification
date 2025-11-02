// data_mem.sv - simple byte-addressable memory
module data_mem (
  input  logic         clk,
  input  logic         mem_write,
  input  logic         mem_read,
  input  logic [31:0]  addr,
  input  logic [31:0]  wd,
  output logic [31:0]  rd
);
  logic [7:0] mem [0:1023]; // 1 KB memory

  // read (combinational)
  always_comb begin
    rd = {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};
  end

  // write (byte-enable simple)
  always_ff @(posedge clk) begin
    if (mem_write) begin
      mem[addr]   <= wd[7:0];
      mem[addr+1] <= wd[15:8];
      mem[addr+2] <= wd[23:16];
      mem[addr+3] <= wd[31:24];
    end
  end

  // init memory to zero
  initial begin
    integer i;
    for (i=0; i<1024; i=i+1) mem[i] = 8'd0;
  end
endmodule
