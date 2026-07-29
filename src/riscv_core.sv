import riscv_pkg::*;

module riscv_core( //top-level of CPU
  input logic clk, rst_n;
);


  register_file regs(.clk(clk),.rst_n(rst_n)

  input reg_addr_t rd1, rd2;  logic wr_en; reg_addr_t wr_addr; word_t wr_data; word_t rd1_data, rd2_data;);

  // Instantiates all pipeline stages: fetch, decode, execute, memory, writeback
  // Instantiates pipeline_controller for stall/flush generation
  // Interfaces with instruction memory and data cache

endmodule : riscv_core
