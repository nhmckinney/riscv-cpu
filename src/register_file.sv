import riscv_pkg::*;

module register_file(
  input logic clk,
  input logic rst_n,
  input reg_addr_t rd1,
  input reg_addr_t rd2,
  input logic wr_en,
  input reg_addr_t wr_addr,
  input word_t wr_data,
  output word_t rd1_data,
  output word_t rd2_data,
  input reg_addr_t debug_rd_addr,
  output word_t debug_rd_data
);

  logic [31:0] registers [0:31]; //32 registers which each store a word
  //XLEN is our word size

  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      for (int i = 0; i < 32; i++) begin
        registers[i] <= '0;
      end
    end
    else begin
      if (wr_en) begin //synchronous write enable
        registers[wr_addr] <= wr_data;
      end
    end
  end


  always_comb begin
    rd1_data = (rd1 == 0) ? '0 : registers[rd1];
    rd2_data = (rd2 == 0) ? '0 : registers[rd2];
    debug_rd_data = (debug_rd_addr == 0) ? '0 : registers[debug_rd_addr];
    //x0 register is hardwired to 0
  end

endmodule : register_file
