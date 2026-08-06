import riscv_pkg::*;

//this module holds
//need to load a block of RAM with this on the FPGA

module instr_mem(
  input word_t addr,
  output instr_t instr
);

  parameter int MEM_SIZE = 256;  // 256 words = 1KB (sufficient for test programs on Basys3)
  logic [31:0] mem [0:MEM_SIZE-1];

  // combinational reading
  always_comb begin
    instr = mem[addr[11:2]];  // word-aligned addressing (addr >> 2)
  end

  // TODO: Initialize mem with program (via $readmemh or initial block)

endmodule : instr_mem
