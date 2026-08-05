import riscv_pkg::*;

module alu(
  input alu_op_t alu_op,
  input word_t a,b, //operands

  output word_t result, //result of operation
  output logic zero_flag

);


  always_comb begin
    case (alu_op)
      ALU_ADD: result = a + b;
      ALU_SUB: result = a - b;
      ALU_SLL: result = a << b;
      ALU_SLT: result = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0;
      ALU_SLTU: result = (a < b) ? 32'b1 : 32'b0;
      ALU_XOR: result = a ^ b;
      ALU_SRL: result = a >> b;
      ALU_SRA: result = a >>> b;
      ALU_OR: result = a | b;
      ALU_AND: result = a & b;
      default: result = '0;
    endcase
  end


  always_comb begin
    zero_flag = (result == '0); 
    //zero flag is outputted for use by controller
  end


endmodule : alu
