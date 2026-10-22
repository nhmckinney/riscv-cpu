import riscv_pkg::*;

module riscv_core(
  input logic clk, rst_n,
  input logic irq_software, irq_timer, irq_external,

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
  logic fetch_valid;
  logic stall, execute_bubble, fetch_flush;
  logic hazard_bubble, branch_flush;
  word_t branch_target;

  fetch_stage fetch(
    .clk(clk),
    .rst_n(rst_n),
    .stall(stall),
    .flush(fetch_flush),
    .branch_target(branch_target),
    .pc(fetch_pc),
    .instr(fetch_instr_word),
    .valid(fetch_valid)
  );
  assign fetch_instr = fetch_instr_word;







  // decode stage
  opcode_t decode_opcode;
  logic [2:0] decode_funct3;
  logic [6:0] decode_funct7;
  word_t decode_pc;
  reg_addr_t decode_rs1, decode_rs2, decode_rd;
  imm_t decode_imm;
  ctrl_signals_t decode_ctrl_sig;
  alu_op_t decode_alu_op;
  instr_t decode_instr;
  logic decode_valid, decode_illegal, decode_ecall, decode_ebreak;
  logic decode_mret, decode_csr;

  // instruction decoder is instantiated within
  decode_stage decode(
    .clk(clk),
    .rst_n(rst_n),
    .stall(stall),
    .flush(fetch_flush),
    .fetch_valid(fetch_valid),
    .fetch_pc(fetch_pc),
    .instr(fetch_instr),
    .decode_pc(decode_pc),
    .opcode(decode_opcode),
    .funct3(decode_funct3),
    .funct7(decode_funct7),
    .rs1(decode_rs1),
    .rs2(decode_rs2),
    .rd(decode_rd),
    .imm(decode_imm),
    .ctrl_sig(decode_ctrl_sig),
    .alu_op(decode_alu_op),
    .valid(decode_valid), .decode_instr(decode_instr),
    .illegal_instr(decode_illegal), .ecall(decode_ecall),
    .ebreak(decode_ebreak), .mret(decode_mret), .csr_en(decode_csr)
  );







//register file
  word_t rs1_data, rs2_data;
  word_t forwarded_rs1_data, forwarded_rs2_data;
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
  word_t csr_rdata, effective_addr, exception_cause, exception_tval;
  word_t trap_target, trap_cause, trap_tval;
  logic csr_illegal, exception_valid, misaligned_data;
  logic trap_taken, mret_taken, trap_redirect;

  assign effective_addr = forwarded_rs1_data + decode_imm;
  assign misaligned_data =
    ((decode_funct3[1:0] == 2'b01) && effective_addr[0]) ||
    ((decode_funct3[1:0] == 2'b10) && (|effective_addr[1:0]));

  always_comb begin
    exception_valid = 1'b0;
    exception_cause = '0;
    exception_tval = '0;
    if (decode_illegal || csr_illegal) begin
      exception_valid = 1'b1;
      exception_cause = CAUSE_ILLEGAL_INSTR;
      exception_tval = decode_instr;
    end else if (decode_ecall) begin
      exception_valid = 1'b1;
      exception_cause = CAUSE_ECALL_M;
    end else if (decode_ebreak) begin
      exception_valid = 1'b1;
      exception_cause = CAUSE_BREAKPOINT;
      exception_tval = decode_pc;
    end else if (decode_ctrl_sig.mem_read && misaligned_data) begin
      exception_valid = 1'b1;
      exception_cause = CAUSE_LOAD_MISALIGNED;
      exception_tval = effective_addr;
    end else if (decode_ctrl_sig.mem_write && misaligned_data) begin
      exception_valid = 1'b1;
      exception_cause = CAUSE_STORE_MISALIGNED;
      exception_tval = effective_addr;
    end else if (exec_branch_taken && (|exec_branch_target[1:0])) begin
      exception_valid = 1'b1;
      exception_cause = CAUSE_INSTR_MISALIGNED;
      exception_tval = exec_branch_target;
    end
  end

  trap_unit traps (
    .clk, .rst_n,
    .instruction_valid(decode_valid && !stall),
    .instruction_pc(decode_pc),
    .exception_valid, .exception_cause, .exception_tval,
    .mret(decode_mret), .csr_en(decode_csr),
    .csr_addr(decode_instr[31:20]), .csr_funct3(decode_funct3),
    .csr_source_zero(decode_rs1 == '0),
    .csr_source(decode_funct3[2] ? {27'b0, decode_rs1} : forwarded_rs1_data),
    .irq_software, .irq_timer, .irq_external,
    .csr_rdata, .csr_illegal, .trap_taken, .return_taken(mret_taken),
    .redirect_valid(trap_redirect), .redirect_pc(trap_target),
    .trap_cause, .trap_tval
  );

  assign execute_bubble = hazard_bubble || trap_redirect || !decode_valid;
  assign fetch_flush = trap_redirect || branch_flush;

  data_forwarding forwarding(
    .rs1(decode_rs1),
    .rs2(decode_rs2),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .exmem_reg_write(exec_ctrl_sig.reg_write),
    .exmem_mem_read(exec_ctrl_sig.mem_read),
    .exmem_rd(exec_rd),
    .exmem_result(exec_alu_result),
    .memwb_reg_write(wb_wr_en),
    .memwb_rd(wb_wr_addr),
    .memwb_result(wb_wr_data),
    .forwarded_rs1_data(forwarded_rs1_data),
    .forwarded_rs2_data(forwarded_rs2_data)
  );

  execute_stage exec(
    .clk(clk),
    .rst_n(rst_n),
    .bubble(execute_bubble),
    .result_override(decode_csr),
    .override_value(csr_rdata),
    .pc(decode_pc),
    .rs1_data(forwarded_rs1_data),
    .rs2_data(forwarded_rs2_data),
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









  // Synchronous data BRAM.
  logic mem_req_valid, mem_req_write;
  logic [3:0] mem_req_wstrb;
  word_t mem_req_addr, mem_req_wdata, mem_resp_rdata;

  simple_data_mem data_mem(
    .clk(clk),
    .rst_n(rst_n),
    .mem_req_valid(mem_req_valid),
    .mem_req_write(mem_req_write),
    .mem_req_addr(mem_req_addr),
    .mem_req_wdata(mem_req_wdata),
    .mem_req_wstrb(mem_req_wstrb),
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
    .mem_req_wstrb(mem_req_wstrb),
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
    .decode_funct3(decode_funct3),
    .exec_rd(exec_rd),
    .exec_reg_write(exec_ctrl_sig.reg_write),
    .exec_mem_read(exec_ctrl_sig.mem_read),
    .branch_taken(exec_branch_taken),
    .stall(stall),
    .execute_bubble(hazard_bubble),
    .fetch_flush(branch_flush)
  );

  assign branch_target = trap_redirect ? trap_target : exec_branch_target;

  // Debug outputs
  assign stall_out = stall;
  assign branch_taken_out = exec_branch_taken;
  assign mem_result_valid_out = mem_result_valid;
  assign debug_pc = fetch_pc;

endmodule : riscv_core
