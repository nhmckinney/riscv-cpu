import riscv_pkg::*;

module fetch_stage(
  input logic clk, rst_n,
  input logic stall, flush,
  input word_t branch_target,
  output word_t pc,
  output instr_t instr,
  output logic valid
);
  word_t request_pc, response_pc;
  logic read_enable;

  assign read_enable = rst_n && !stall && !flush;

  instr_mem imem (
    .clk(clk),
    .enable(read_enable),
    .addr(request_pc),
    .instr(instr)
  );

  // response_pc and valid describe the registered instruction BRAM output.
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      request_pc <= '0;
      response_pc <= '0;
      valid <= 1'b0;
    end else if (flush) begin
      request_pc <= branch_target;
      response_pc <= branch_target;
      valid <= 1'b0;
    end else if (!stall) begin
      response_pc <= request_pc;
      request_pc <= request_pc + 32'd4;
      valid <= 1'b1;
    end
  end

  assign pc = response_pc;
endmodule : fetch_stage
