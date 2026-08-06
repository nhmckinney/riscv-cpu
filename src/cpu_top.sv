module cpu_top(
  input logic clk,
  input logic reset,
  input logic [4:0] sw,         // switches to select register
  input logic btnC,              // button to toggle between register/PC display
  output logic [15:0] LED
);

  logic rst_n;
  assign rst_n = ~reset;

  // Debug signals from CPU (internal only, not top-level ports)
  logic stall, branch_taken, mem_result_valid;
  word_t debug_rd_data;
  word_t debug_pc;

  riscv_core cpu(
    .clk(clk),
    .rst_n(rst_n),
    .stall_out(stall),
    .branch_taken_out(branch_taken),
    .mem_result_valid_out(mem_result_valid),
    .debug_rd_addr(sw),
    .debug_rd_data(debug_rd_data),
    .debug_pc(debug_pc)
  );

  // Multiplexer to toggle between register value and PC on LEDs
  // btnC = 0 → show selected register value (from debug_rd_data)
  // btnC = 1 → show program counter (from debug_pc)
  logic [15:0] led_value;
  assign led_value = btnC ? debug_pc[15:0] : debug_rd_data[15:0];

  // Wire to LEDs (lower 16 bits of selected value)
  assign LED[15:0] = led_value;

endmodule : cpu_top
