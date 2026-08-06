module cpu_top(
  input logic clk,
  input logic reset,
  input logic [4:0] reg_select,    // switches to select which register to display
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
    .debug_rd_addr(reg_select),
    .debug_rd_data(debug_rd_data),
    .debug_pc(debug_pc)
  );

  // Wire register file output to LEDs (lower 16 bits show register value)
  // Use switches to select which register to display:
  //   SW[0]=0 → register x3 (should be 8)
  //   SW[1]=0 → register x1 (should be 5)
  //   SW[2]=0 → register x2 (should be 3)
  // Status bits on upper LEDs
  assign LED[15:0] = debug_rd_data[15:0];

  // Overlay status indicators on specific LEDs (will OR with register value)
  // LED[0] shows stall condition
  // LED[1] shows branch_taken
  // LED[2] shows mem_result_valid

endmodule : cpu_top
