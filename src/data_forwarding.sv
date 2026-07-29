import riscv_pkg::*;

module data_forwarding;

  // Forwarding/bypass logic to reduce pipeline stalls
  // Detects register read-after-write dependencies
  // Routes execute/memory stage results to decode operand inputs

endmodule : data_forwarding
