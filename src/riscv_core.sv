import riscv_pkg::*;

module riscv_core(
  input logic clk, rst_n,

  // Debug outputs to prevent optimization
  output logic stall_out,
  output logic branch_taken_out,
  output logic mem_result_valid_out,

  // Debug register file read
  input reg_addr_t debug_rd_addr,
  output word_t debug_rd_data,
  output word_t debug_pc
);

  //fetch stage
  word_t fetch_pc, fetch_instr_word;
  instr_t fetch_instr;
  logic stall, fetch_flush;
  word_t branch_target;

  fetch_stage fetch(
    .clk(clk),
    .rst_n(rst_n),
    .stall(stall),
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
    .wr_data(wb_wr_data),
    .debug_rd_addr(debug_rd_addr),
    .debug_rd_data(debug_rd_data)
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









  // Simple data memory (no cache for simulation)
  logic mem_req_valid, mem_req_write;
  word_t mem_req_addr, mem_req_wdata, mem_resp_rdata;

  simple_data_mem data_mem(
    .clk(clk),
    .rst_n(rst_n),
    .mem_req_valid(mem_req_valid),
    .mem_req_write(mem_req_write),
    .mem_req_addr(mem_req_addr),
    .mem_req_wdata(mem_req_wdata),
    .mem_resp_rdata(mem_resp_rdata)
  );

  // Memory stage
  reg_addr_t mem_rd;
  logic mem_reg_write;
  ctrl_signals_t mem_ctrl_sig;
  logic [2:0] mem_funct3;
  opcode_t mem_opcode;
  word_t mem_result;
  logic mem_result_valid;

  memory_stage mem(
    .clk(clk),
    .rst_n(rst_n),
    .exec_alu_result(exec_alu_result),
    .exec_rs2_data(exec_rs2_data),
    .exec_rd(exec_rd),
    .exec_ctrl_sig(exec_ctrl_sig),
    .exec_funct3(exec_funct3),
    .exec_opcode(exec_opcode),
    .mem_req_valid(mem_req_valid),
    .mem_req_write(mem_req_write),
    .mem_req_addr(mem_req_addr),
    .mem_req_wdata(mem_req_wdata),
    .mem_resp_rdata(mem_resp_rdata),
    .mem_result(mem_result),
    .mem_result_valid(mem_result_valid),
    .mem_rd(mem_rd),
    .mem_reg_write(mem_reg_write),
    .mem_ctrl_sig(mem_ctrl_sig),
    .mem_funct3(mem_funct3),
    .mem_opcode(mem_opcode)
  );







  //Writeback stage
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










  //Pipeline controller
  pipeline_controller pc(
    .clk(clk),
    .rst_n(rst_n),
    .decode_rs1(decode_rs1),
    .decode_rs2(decode_rs2),
    .decode_opcode(decode_opcode),
    .exec_rd(exec_rd),
    .exec_reg_write(exec_ctrl_sig.reg_write),
    .mem_rd(mem_rd),
    .mem_reg_write(mem_reg_write),
    .mem_read(mem_ctrl_sig.mem_read),
    .mem_result_valid(mem_result_valid),
    .branch_taken(exec_branch_taken),
    .stall(stall),
    .fetch_flush(fetch_flush)
  );

  assign branch_target = exec_branch_target;

  // Debug outputs
  assign stall_out = stall;
  assign branch_taken_out = exec_branch_taken;
  assign mem_result_valid_out = mem_result_valid;
  assign debug_pc = fetch_pc;

endmodule : riscv_core
