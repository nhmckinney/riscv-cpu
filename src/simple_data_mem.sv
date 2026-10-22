import riscv_pkg::*;

// Single-port, read-first BRAM with byte write enables.
module simple_data_mem(
  input logic clk, rst_n,

  // Memory interface
  input logic mem_req_valid,
  input logic mem_req_write,
  input word_t mem_req_addr,
  input word_t mem_req_wdata,
  input logic [3:0] mem_req_wstrb,
  output word_t mem_resp_rdata
);

  parameter int MEM_SIZE = 256;  // 256 words = 1KB
  localparam int ADDR_BITS = $clog2(MEM_SIZE);
  (* ram_style = "block" *) logic [31:0] mem [0:MEM_SIZE-1];

  // Vivado places these initial values in the FPGA configuration image.
  // CPU reset disables requests; it does not clear the stored program data.
  initial begin
    for (int i = 0; i < MEM_SIZE; i++)
      mem[i] = '0;
  end

  always_ff @(posedge clk) begin
    if (rst_n && mem_req_valid) begin
      if (mem_req_write) begin
        for (int lane = 0; lane < 4; lane++) begin
          if (mem_req_wstrb[lane])
            mem[mem_req_addr[ADDR_BITS+1:2]][8*lane +: 8] <=
              mem_req_wdata[8*lane +: 8];
        end
      end
      mem_resp_rdata <= mem[mem_req_addr[ADDR_BITS+1:2]];
    end
  end

endmodule : simple_data_mem
