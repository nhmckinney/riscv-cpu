import riscv_pkg::*;

module cpu_top;

  // Basys3 FPGA wrapper for riscv_core
  // Instantiates riscv_core and adds I/O mux for LEDs, buttons, 7-seg display
  // Displays pipeline metrics: IPC, hit rate, latency, PC

endmodule : cpu_top
