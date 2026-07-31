import riscv_pkg::*;

module alu(
  input alu_op_t alu_op;
  input word_t a,b; //operands

  output word_t result; //result of operation
  output logic zero_flag;

);


  always_comb begin
    switch (alu_op) begin
      case (ALU_ADD): begin
        result = a + b;
    end
      case (ALU_SUB):  begin
        result = a - b;
    end
      case (ALU_SLL): begin //shift left logical
        result = a << b;
    end
      case (ALU_SLT):  begin
        result = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0;
    end
      case (ALU_SLTU): begin
        result = (a < b) ? 32'b1 : 32'b0;
    end
      case (ALU_XOR):  begin
        result = a ^ b;
    end
      case (ALU_SRL): begin
        result = a >> b;
    end
      case (ALU_SRA) : begin
        result = a >>> b;
    end
      case (ALU_OR): begin
        result = a | b;
    end
      case (ALU_AND): begin
        result = a & b;
    end
      default: result = '0;
    end
  end


  always_comb begin
    zero_flag = (result == '0); 
    //zero flag is outputted for use by controller
  end


endmodule : alu
