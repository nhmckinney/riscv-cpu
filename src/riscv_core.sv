import riscv_pkg::*;

module riscv_core(
  input logic clk, rst_n
);

  //fetch stage
  word_t fetch_pc, fetch_instr_word;
  instr_t fetch_instr;
  logic fetch_stall, fetch_flush;
  word_t branch_target;

  fetch_stage fetch(
    .clk(clk),
    .rst_n(rst_n),
    .stall(fetch_stall),
    .flush(fetch_flush),
    .branch_target(branch_target),
    .pc(fetch_pc),
    .instr(fetch_instr_word)
  );
  assign fetch_instr = fetch_instr_word;







  // decode stage
  opcode_t decode_opcode;
  logic [2:0] decode_funct3;
  logic [6:0] decode_funct7;
  reg_addr_t decode_rs1, decode_rs2, decode_rd;
  imm_t decode_imm;
  ctrl_signals_t decode_ctrl_sig;
  alu_op_t decode_alu_op;

  // instruction decoder is instantiated within
  decode_stage decode(
    .clk(clk),
    .rst_n(rst_n),
    .instr(fetch_instr),
    .opcode(decode_opcode),
    .funct3(decode_funct3),
    .funct7(decode_funct7),
    .rs1(decode_rs1),
    .rs2(decode_rs2),
    .rd(decode_rd),
    .imm(decode_imm),
    .ctrl_sig(decode_ctrl_sig),
    .alu_op(decode_alu_op)
  );







//register file
  word_t rs1_data, rs2_data;
  reg_addr_t wb_wr_addr;
  logic wb_wr_en;
  word_t wb_wr_data;

  register_file regs(
    .clk(clk),
    .rst_n(rst_n),
    .rd1(decode_rs1),
    .rd2(decode_rs2),
    .rd1_data(rs1_data),
    .rd2_data(rs2_data),
    .wr_en(wb_wr_en),
    .wr_addr(wb_wr_addr),
    .wr_data(wb_wr_data)
  );







  //execute stage
  word_t exec_alu_result, exec_rs2_data;
  reg_addr_t exec_rd;
  ctrl_signals_t exec_ctrl_sig;
  logic [2:0] exec_funct3;
  opcode_t exec_opcode;
  logic exec_branch_taken;
  word_t exec_branch_target;

  execute_stage exec(
    .clk(clk),
    .rst_n(rst_n),
    .pc(fetch_pc),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .imm(decode_imm),
    .alu_op(decode_alu_op),
    .alu_src_a(decode_ctrl_sig.alu_src_a),
    .alu_src_b(decode_ctrl_sig.alu_src_b),
    .rs1(decode_rs1),
    .rs2(decode_rs2),
    .rd(decode_rd),
    .ctrl_sig(decode_ctrl_sig),
    .opcode(decode_opcode),
    .funct3(decode_funct3),
    .exec_alu_result(exec_alu_result),
    .exec_rs2_data(exec_rs2_data),
    .exec_rd(exec_rd),
    .exec_ctrl_sig(exec_ctrl_sig),
    .exec_funct3(exec_funct3),
    .exec_opcode(exec_opcode),
    .branch_taken(exec_branch_taken),
    .branch_target(exec_branch_target)
  );









  // need to finish
  word_t mem_alu_result, mem_rs2_data;
  reg_addr_t mem_rd;
  logic mem_reg_write;
  ctrl_signals_t mem_ctrl_sig;
  logic [2:0] mem_funct3;
  opcode_t mem_opcode;
  word_t mem_result;
  logic mem_result_valid;









  // ===== WRITEBACK STAGE =====
  writeback_stage wb(
    .mem_result_valid(mem_result_valid),
    .mem_result(mem_result),
    .mem_rd(mem_rd),
    .mem_reg_write(mem_reg_write),
    .mem_to_reg(mem_ctrl_sig.mem_to_reg),
    .pc_plus_4(fetch_pc + 32'd4),
    .wr_addr(wb_wr_addr),
    .wr_data(wb_wr_data),
    .wr_en(wb_wr_en)
  );










  // pipeline controller
  assign fetch_stall = 1'b0; 
  assign fetch_flush = exec_branch_taken;
  assign branch_target = exec_branch_target;

endmodule : riscv_core
