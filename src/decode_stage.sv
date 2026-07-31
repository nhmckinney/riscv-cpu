import riscv_pkg::*;

module decode_stage(
  input logic clk, rst_n,
  input instr_t instr,

  output opcode_t opcode;
  output logic [2:0] funct3, 
  output logic [6:0] funct7,
  output reg_addr_t rs1, rs2, rd;
  output imm_t imm;
  output ctrl_signals_t ctrl_sig;
  output alu_op_t alu_op;

);

  instruction_decoder decode_mod(.instr(instr),.opcode(opcode_next),
                                 .funct3(funct3_next),.funct7(funct7_next),
                                 .rs1(rs1_next), .rs2(rs2_next), .rd(rd_next),
                                 .imm(imm_next),.ctrl_sig(ctrl_sig_next),
                                 .alu_op(alu_op_next));

  opcode_t opcode_next;
  logic [2:0] funct3_next;
  logic [6:0] funct7_next;
  reg_addr_t rs1_next, rs2_next, rd_next;
  imm_t imm_next;
  ctrl_signals_t ctrl_sig_next;
  alu_op_t alu_op_next;


  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      opcode <= '0;
      funct3 <= '0;
      funct7 <= '0;
      rs1 <= '0;
      rs2 <= '0;
      rd <= '0;
      imm <= '0;
      ctrl_sig <= '0;
      alu_op <= '0;
    end
    else begin
      opcode <= opcode_next;
      funct3 <= funct3_next;
      funct7 <= funct7_next;
      rs1 <= rs1_next;
      rs2 <= rs2_next;
      rd <= rd_next;
      imm <= imm_next;
      ctrl_sig <= ctrl_sig_next;
      alu_op <= alu_op_next;
    end
  end



endmodule : decode_stage
