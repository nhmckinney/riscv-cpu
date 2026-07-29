import riscv_pkg::*;

module pipeline_controller(
  
);

  // Pipeline control FSM
  // Manages fetch → decode → execute → memory → writeback stages
  // Handles stalls (data hazard, cache miss), flushes (branch misprediction)
  // Generates valid/ready signals for each pipeline stage

endmodule : pipeline_controller
