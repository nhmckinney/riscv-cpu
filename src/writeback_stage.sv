import riscv_pkg::*;

module writeback_stage(
  input logic mem_result_valid,
  input word_t mem_result,
  input reg_addr_t mem_rd,
  input logic mem_reg_write,
  input logic [1:0] mem_to_reg,
  input word_t pc_plus_4,

  output reg_addr_t wr_addr,
  output word_t wr_data,
  output logic wr_en
);

  always_comb begin
    wr_addr = mem_rd;
    wr_en = mem_result_valid && mem_reg_write;

    case (mem_to_reg)
      2'b00: wr_data = mem_result;  // ALU result
      2'b01: wr_data = mem_result;  // Loaded data (already extracted in memory stage)
      2'b10: wr_data = pc_plus_4;   // PC+4 for jumps (JAL/JALR)
      default: wr_data = '0;
    endcase
  end

endmodule : writeback_stage
