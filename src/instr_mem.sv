import riscv_pkg::*;

//this module holds
//need to load a block of RAM with this on the FPGA

module instr_mem(
  input word_t addr,
  output instr_t instr
);

  parameter int MEM_SIZE = 256;  // 256 words = 1KB (sufficient for test programs on Basys3)
  localparam int ADDR_BITS = $clog2(MEM_SIZE);
  logic [31:0] mem [0:MEM_SIZE-1];

  // combinational reading
  always_comb begin
    instr = mem[addr[ADDR_BITS+1:2]];  // word-aligned addressing (addr >> 2)
  end

  // Initialize instruction memory with test program
  initial begin
    // add_test.s: addi x1, x0, 5; addi x2, x0, 3; add x3, x1, x2; beq x0, x0, .
    mem[0] = 32'h00500093;  // addi x1, x0, 5
    mem[1] = 32'h00300113;  // addi x2, x0, 3
    mem[2] = 32'h002081b3;  // add x3, x1, x2
    mem[3] = 32'h00000063;  // beq x0, x0, 0 (infinite loop)
    // Rest of memory filled with zeros (NOPs)
    for (int i = 4; i < MEM_SIZE; i++) begin
      mem[i] = 32'h00000013;  // nop (addi x0, x0, 0)
    end
  end

endmodule : instr_mem
