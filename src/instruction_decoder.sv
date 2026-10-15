import riscv_pkg::*;

module instruction_decoder(
  input instr_t instr,
  output opcode_t opcode,
  output logic [2:0] funct3,
  output logic [6:0] funct7,
  output reg_addr_t rs1, rs2, rd,
  output imm_t imm,
  output ctrl_signals_t ctrl_sig,
  output alu_op_t alu_op,
  output logic illegal_instr,
  output logic ecall, ebreak
);

  always_comb begin
    opcode = opcode_t'(instr[6:0]);
    funct3 = instr[14:12];
    funct7 = instr[31:25];
    rs1 = instr[19:15];
    rs2 = instr[24:20];
    rd = instr[11:7];

    imm = '0;
    ctrl_sig = '0;
    alu_op = ALU_NOP;
    illegal_instr = 1'b0;
    ecall = 1'b0;
    ebreak = 1'b0;

    case (opcode)
      OP_LUI: begin
        imm = {instr[31:12], 12'b0};
        ctrl_sig.reg_write = 1'b1;
        ctrl_sig.alu_src_a = 2'b10; // zero + upper immediate
        ctrl_sig.alu_src_b = 2'b01;
        alu_op = ALU_ADD;
      end

      OP_AUIPC: begin
        imm = {instr[31:12], 12'b0};
        ctrl_sig.reg_write = 1'b1;
        ctrl_sig.alu_src_a = 2'b01; // PC + upper immediate
        ctrl_sig.alu_src_b = 2'b01;
        alu_op = ALU_ADD;
      end

      OP_JAL: begin
        imm = {{11{instr[31]}}, instr[31], instr[19:12],
               instr[20], instr[30:21], 1'b0};
        ctrl_sig.is_jump = 1'b1;
        ctrl_sig.reg_write = 1'b1;
        // The branch target is calculated separately in execute_stage.
        // Send this instruction's PC+4 through the ALU writeback path.
        ctrl_sig.alu_src_a = 2'b01;
        ctrl_sig.alu_src_b = 2'b10;
        alu_op = ALU_ADD;
      end

      OP_JALR: begin
        imm = {{20{instr[31]}}, instr[31:20]};
        if (funct3 != 3'b000) illegal_instr = 1'b1;
        ctrl_sig.is_jump = 1'b1;
        ctrl_sig.reg_write = 1'b1;
        ctrl_sig.alu_src_a = 2'b01;
        ctrl_sig.alu_src_b = 2'b10;
        alu_op = ALU_ADD;
      end

      OP_BRANCH: begin
        imm = {{19{instr[31]}}, instr[31], instr[7],
               instr[30:25], instr[11:8], 1'b0};
        case (funct3)
          3'b000, 3'b001, 3'b100, 3'b101, 3'b110, 3'b111:
            ctrl_sig.is_branch = 1'b1;
          default: illegal_instr = 1'b1;
        endcase
        // execute_stage compares the forwarded operands and computes PC+imm.
      end

      OP_LOAD: begin
        imm = {{20{instr[31]}}, instr[31:20]};
        case (funct3)
          3'b000, 3'b001, 3'b010, 3'b100, 3'b101: begin
            ctrl_sig.mem_read = 1'b1;
            ctrl_sig.reg_write = 1'b1;
            ctrl_sig.mem_to_reg = 2'b01;
            ctrl_sig.alu_src_b = 2'b01; // rs1 + offset
            alu_op = ALU_ADD;
          end
          default: illegal_instr = 1'b1;
        endcase
      end

      OP_STORE: begin
        imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
        case (funct3)
          3'b000, 3'b001, 3'b010: begin
            ctrl_sig.mem_write = 1'b1;
            ctrl_sig.alu_src_b = 2'b01; // rs1 + offset
            alu_op = ALU_ADD;
          end
          default: illegal_instr = 1'b1;
        endcase
      end

      OP_ARITH: begin
        imm = {{20{instr[31]}}, instr[31:20]};
        ctrl_sig.reg_write = 1'b1;
        ctrl_sig.alu_src_b = 2'b01;
        case (funct3)
          3'b000: alu_op = ALU_ADD;  // ADDI
          3'b010: alu_op = ALU_SLT;  // SLTI
          3'b011: alu_op = ALU_SLTU; // SLTIU
          3'b100: alu_op = ALU_XOR;  // XORI
          3'b110: alu_op = ALU_OR;   // ORI
          3'b111: alu_op = ALU_AND;  // ANDI
          3'b001: begin             // SLLI
            imm = {27'b0, instr[24:20]};
            if (funct7 == 7'b0000000) alu_op = ALU_SLL;
            else illegal_instr = 1'b1;
          end
          3'b101: begin             // SRLI / SRAI
            imm = {27'b0, instr[24:20]};
            if (funct7 == 7'b0000000) alu_op = ALU_SRL;
            else if (funct7 == 7'b0100000) alu_op = ALU_SRA;
            else illegal_instr = 1'b1;
          end
          default: illegal_instr = 1'b1;
        endcase
      end

      OP_COMPUTE: begin
        ctrl_sig.reg_write = 1'b1;
        case (funct3)
          3'b000: begin // ADD / SUB
            if (funct7 == 7'b0000000) alu_op = ALU_ADD;
            else if (funct7 == 7'b0100000) alu_op = ALU_SUB;
            else illegal_instr = 1'b1;
          end
          3'b101: begin // SRL / SRA
            if (funct7 == 7'b0000000) alu_op = ALU_SRL;
            else if (funct7 == 7'b0100000) alu_op = ALU_SRA;
            else illegal_instr = 1'b1;
          end
          3'b001, 3'b010, 3'b011, 3'b100, 3'b110, 3'b111: begin
            if (funct7 != 7'b0000000) illegal_instr = 1'b1;
            case (funct3)
              3'b001: alu_op = ALU_SLL;
              3'b010: alu_op = ALU_SLT;
              3'b011: alu_op = ALU_SLTU;
              3'b100: alu_op = ALU_XOR;
              3'b110: alu_op = ALU_OR;
              3'b111: alu_op = ALU_AND;
              default: alu_op = ALU_NOP;
            endcase
          end
          default: illegal_instr = 1'b1;
        endcase
      end

      OP_FENCE: begin
        // In this single-hart, in-order design a base FENCE has no work to do.
        // FENCE.I and other funct3 values are not implemented.
        if (funct3 != 3'b000) illegal_instr = 1'b1;
      end

      OP_SYSTEM: begin
        // ECALL and EBREAK have distinct architectural trap causes.
        // Other SYSTEM encodings need Zicsr or another extension.
        case (instr)
          32'h00000073: ecall = 1'b1;
          32'h00100073: ebreak = 1'b1;
          default: illegal_instr = 1'b1;
        endcase
      end

      default: illegal_instr = 1'b1;
    endcase

    // Invalid or unsupported encodings must not write a register, access
    // memory, or redirect the PC. A future trap unit can use these flags.
    if (illegal_instr) begin
      opcode = OP_INVALID;
      imm = '0;
      ctrl_sig = '0;
      alu_op = ALU_NOP;
    end
  end

endmodule : instruction_decoder
