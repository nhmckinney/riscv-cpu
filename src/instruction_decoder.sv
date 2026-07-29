import riscv_pkg::*;

module instruction_decoder(
  input instr_t instr,
  output opcode_t opcode, //done
  output logic [2:0] funct3, //done
  output logic [6:0] funct7, //done
  output reg_addr_t rs1, rs2, rd, //done
  output imm_t imm,
  output ctrl_signals_t ctrl_sig,
  output alu_op_t alu_op
);

  always_comb begin
    // Extract fields
    opcode = instr[6:0];
    funct3 = instr[14:12];
    funct7 = instr[31:25];
    rs1 = instr[19:15];
    rs2 = instr[24:20];
    rd = instr[11:7];
    
    // Decode immediate based on format (I/S/B/U/J)
    // Generate control signals based on opcode
    // Generate ALU op based on opcode + funct3/funct7
  end

always_comb begin 
    ctrl_sig = '0;
    imm = '0;
    switch (opcode) begin
      case OP_LUI: begin
      end
      case OP_AUIPC: begin
      end
      case OP_JAL: begin
        ctrl_sig[10] = 1'b1;
      end
      case OP_JALR: begin
        ctrl_sig[10] = 1'b1;
      end
      case OP_BRANCH: begin
      end
      case OP_LOAD: begin
      end
      case OP_STORE: begin
      end
      case OP_ARITH: begin
      end
      case OP_COMPUTE: begin
      end
      case OP_FENCE: begin
      end
      case OP_SYSTEM: begin
      end
    end
  end


endmodule : instruction_decoder
