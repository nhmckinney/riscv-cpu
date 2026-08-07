import riscv_pkg::*;

// Simple single-cycle data memory for simulation (no cache)
module simple_data_mem(
  input logic clk, rst_n,

  // Memory interface
  input logic mem_req_valid,
  input logic mem_req_write,
  input word_t mem_req_addr,
  input word_t mem_req_wdata,
  output word_t mem_resp_rdata
);

  parameter int MEM_SIZE = 256;  // 256 words = 1KB
  logic [31:0] mem [0:MEM_SIZE-1];

  // Synchronous write, combinational read
  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      // Initialize memory to zeros
      for (int i = 0; i < MEM_SIZE; i++) begin
        mem[i] <= '0;
      end
    end
    else if (mem_req_valid && mem_req_write) begin
      mem[mem_req_addr[9:2]] <= mem_req_wdata;  // word-aligned addressing
    end
  end

  // Combinational read
  assign mem_resp_rdata = mem_req_valid ? mem[mem_req_addr[9:2]] : '0;

endmodule : simple_data_mem
