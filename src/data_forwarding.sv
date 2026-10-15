import riscv_pkg::*;

module data_forwarding(
  // Source operands for the instruction currently entering Execute
  input reg_addr_t rs1, rs2,
  input word_t rs1_data, rs2_data,

  // Newest possible producer: the EX/MEM pipeline register
  input logic exmem_reg_write,
  input logic exmem_mem_read,
  input reg_addr_t exmem_rd,
  input word_t exmem_result,

  // Older possible producer: the MEM/WB writeback path
  input logic memwb_reg_write,
  input reg_addr_t memwb_rd,
  input word_t memwb_result,

  output word_t forwarded_rs1_data,
  output word_t forwarded_rs2_data
);

  // Forwarding/bypass logic to reduce pipeline stalls
  // Detects register read-after-write dependencies
  // Start with the register-file values. Later forwarding checks override
  // these defaults only when a real dependency is present.
  always_comb begin
    forwarded_rs1_data = rs1_data;
    forwarded_rs2_data = rs2_data;

    if (memwb_reg_write && (memwb_rd != '0)) begin
      if (memwb_rd == rs1) begin
        forwarded_rs1_data = memwb_result;
      end
      if (memwb_rd == rs2) begin
        forwarded_rs2_data = memwb_result;
      end
    end

    if (exmem_reg_write && ~exmem_mem_read && (exmem_rd != '0)) begin
      if (exmem_rd == rs1) begin
        forwarded_rs1_data = exmem_result;
      end
      if (exmem_rd == rs2) begin
        forwarded_rs2_data = exmem_result;
      end
    end
  end

endmodule : data_forwarding
