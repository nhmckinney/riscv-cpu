import riscv_pkg::*;

module decode_stage(
  input logic clk, rst_n,
  input instr_t instr

  output ctrl_signals_t ctrl_sig;
  output 
  output imm_t imm;

);

  instruction_decoder decode_mod(.instr(instr),.opcode(opcode),
  output logic [2:0] funct3,
  output logic [6:0] funct7,
  output reg_addr_t rs1, rs2, rd,.imm(imm_next),.ctrl_sig(ctrl_sig_next),.alu_op(alu_op_next)
);



  ctrl_signals_t ctrl_sig, ctrl_sig_next;

  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      //need to implement
    end
    else begin
      ctrl_sig <= ctrl_sig_next;
      imm <= imm_next;
    end
  end

  
  // Pipeline register holding decoded instruction signals
  // Instantiates register_file reads
  // Outputs: control signals, register operands, immediate

endmodule : decode_stage
