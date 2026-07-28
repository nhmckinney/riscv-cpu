import riscv_pkg::*;

module fetch_stage(
  input logic clk, rst_n,
  input logic stall,                //if asserted, pause fetching and wait
  input logic flush,                //flushes current PC and replaces
  //both above are from pipeline_controller
  input word_t branch_target,       // from execute_stage (branch address)

  output word_t pc,                 // current PC
  output instr_t instr              // fetched instruction
);

  word_t pc_reg, pc_next;
  instr_t fetched_instr;

  // Instantiate instruction memory
  instr_mem imem (
    .addr(pc_reg),
    .instr(fetched_instr)
  );

  // PC update logic (sequential)
  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      pc_reg <= 32'b0;
    end else if (flush) begin
      pc_reg <= branch_target;  // branch misprediction: redirect to new addr
      //provided by execute stage
    end else if (~stall) begin
      pc_reg <= pc_next;            // normal: increment
    end
    // else: stall, hold PC
  end

  // PC increment or branch mux (combinational)
  always_comb begin
    if (flush) begin
      pc_next = branch_target;
    end else begin
      pc_next = pc_reg + 32'd4;     // next instruction (4 bytes)
    end
  end

  // Output current PC and instruction
  assign pc = pc_reg;
  assign instr = fetched_instr;

endmodule : fetch_stage
