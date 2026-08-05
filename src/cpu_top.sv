module cpu_top(
  input logic clk,
  input logic reset,
  output logic [15:0] LED,

  // Debug ports
  input reg_addr_t debug_rd_addr,
  output word_t debug_rd_data,
  output word_t debug_pc
);

  logic rst_n;
  assign rst_n = ~reset;

  // Debug signals from CPU
  logic stall, branch_taken, mem_result_valid;

  riscv_core cpu(
    .clk(clk),
    .rst_n(rst_n),
    .stall_out(stall),
    .branch_taken_out(branch_taken),
    .mem_result_valid_out(mem_result_valid),
    .debug_rd_addr(debug_rd_addr),
    .debug_rd_data(debug_rd_data),
    .debug_pc(debug_pc)
  );

  // Wire debug signals to LEDs to prevent Vivado from optimizing away logic
  assign LED[0] = stall;
  assign LED[1] = branch_taken;
  assign LED[2] = mem_result_valid;
  assign LED[15:3] = '0;

endmodule : cpu_top
