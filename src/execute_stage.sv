import riscv_pkg::*;

module execute_stage(
  input logic clk, rst_n,

  // From decode stage
  input word_t pc,
  input word_t rs1_data, rs2_data,
  input imm_t imm,
  input alu_op_t alu_op,
  input logic [1:0] alu_src_a, alu_src_b,
  input reg_addr_t rs1, rs2, rd,
  input ctrl_signals_t ctrl_sig,
  input opcode_t opcode,
  input logic [2:0] funct3,

  // Outputs to memory stage (registered)
  output word_t exec_alu_result,
  output word_t exec_rs2_data,
  output reg_addr_t exec_rd,
  output ctrl_signals_t exec_ctrl_sig,
  output logic [2:0] exec_funct3,
  output opcode_t exec_opcode,

  // Branch/jump outputs for pipeline controller & fetch
  output logic branch_taken,
  output word_t branch_target //need PC
);


  word_t alu_a, alu_b;

  always_comb begin
    case (alu_src_a)
      2'b00: alu_a = rs1_data;  // register
      2'b01: alu_a = pc;        // PC
      default: alu_a = '0;
    endcase

    case (alu_src_b)
      2'b00: alu_b = rs2_data;  // register
      2'b01: alu_b = imm;       // immediate
      2'b10: alu_b = 32'd4;     // PC+4 increment
      default: alu_b = '0;
    endcase
  end


  word_t alu_result;
  logic alu_zero;

  alu alu_inst(
    .alu_op(alu_op),
    .a(alu_a),
    .b(alu_b),
    .result(alu_result),
    .zero_flag(alu_zero)
  );


  logic branch_condition_met;

  always_comb begin
    branch_condition_met = 1'b0;

    if (ctrl_sig.is_branch) begin
      case (funct3)
        3'b000: branch_condition_met = (rs1_data == rs2_data);           // BEQ
        3'b001: branch_condition_met = (rs1_data != rs2_data);           // BNE
        3'b100: branch_condition_met = ($signed(rs1_data) < $signed(rs2_data));  // BLT
        3'b101: branch_condition_met = ($signed(rs1_data) >= $signed(rs2_data)); // BGE
        3'b110: branch_condition_met = (rs1_data < rs2_data);            // BLTU
        3'b111: branch_condition_met = (rs1_data >= rs2_data);           // BGEU
        default: branch_condition_met = 1'b0;
      endcase
    end
  end




  always_comb begin
    if (ctrl_sig.is_jump) begin
      branch_taken = 1'b1;
      branch_target = alu_result;  //PC + imm for JAL, or rs1+imm for JALR
    end
    else if (ctrl_sig.is_branch && branch_condition_met) begin
      branch_taken = 1'b1;
      branch_target = alu_result;  // PC + imm
    end
    else begin
      branch_taken = 1'b0;
      branch_target = '0;
    end
  end




  //register results for next stages
  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      exec_alu_result <= '0;
      exec_rs2_data <= '0;
      exec_rd <= '0;
      exec_ctrl_sig <= '0;
      exec_funct3 <= '0;
      exec_opcode <= '0;
    end
    else begin
      exec_alu_result <= alu_result;
      exec_rs2_data <= rs2_data;
      exec_rd <= rd;
      exec_ctrl_sig <= ctrl_sig;
      exec_funct3 <= funct3;
      exec_opcode <= opcode;
    end
  end

endmodule : execute_stage
