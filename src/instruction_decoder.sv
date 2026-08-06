import riscv_pkg::*;

module instruction_decoder(
  input instr_t instr,
  output opcode_t opcode, 
  output logic [2:0] funct3, 
  output logic [6:0] funct7, 
  output reg_addr_t rs1, rs2, rd, 
  output imm_t imm,
  output ctrl_signals_t ctrl_sig,
  output alu_op_t alu_op
);

  always_comb begin
    // Extract fields
    opcode = opcode_t'(instr[6:0]);
    funct3 = instr[14:12];
    funct7 = instr[31:25];
    rs1 = instr[19:15];
    rs2 = instr[24:20];
    rd = instr[11:7];

    ctrl_sig = '0; //turn all flags off
    imm = '0; //reset immediate value
    alu_op = ALU_NOP; //reset alu operation
    //prevents inferred latched


    case (opcode)
      OP_LUI: begin //load upper immediate
        imm[31:12] = instr[31:12]; //extract upper immediate
        ctrl_sig.reg_write = 1'b1; 
        ctrl_sig.alu_src_b = 2'b01; //alu b input is imm
        ctrl_sig.mem_to_reg = 2'b00;  //route alu output to reg
      end
      OP_AUIPC: begin //add upper immediate to PC
        imm[31:12] = instr[31:12]; //extract upper immediate
        ctrl_sig.reg_write = 1'b1;
        ctrl_sig.alu_src_a = 2'b01; //alu a input is PC
        ctrl_sig.alu_src_b = 2'b01; //alu b input is imm
        ctrl_sig.mem_to_reg = 2'b00;  //route alu output to reg
      end
      OP_JAL: begin
        imm[20]    = instr[31];
        imm[19:12] = instr[19:12];
        imm[11]    = instr[20];
        imm[10:1]  = instr[30:21];
        imm[0]     = 1'b0;
        imm[31:21] = {11{instr[31]}};  // sign-extend
        ctrl_sig.is_jump = 1'b1;
        ctrl_sig.reg_write = 1'b1;
      end
      OP_JALR: begin
        imm[11:0] = instr[31:20];
        imm[31:12] = {20{instr[31]}};
        ctrl_sig.is_jump = 1'b1;
        ctrl_sig.reg_write = 1'b1;
      end
      OP_BRANCH: begin
        // B-format immediate: split across [31:25] and [11:7]
        imm[12]    = instr[31];
        imm[10:5]  = instr[30:25];
        imm[4:1]   = instr[11:8];
        imm[11]    = instr[7];
        imm[0]     = 1'b0;
        imm[31:13] = {19{instr[31]}};  // sign-extend
        ctrl_sig.is_branch = 1'b1;
        ctrl_sig.alu_src_b = 2'b01;  // compute: rs1 - rs2
        alu_op = ALU_SUB;            // subtract for comparison
      end
      OP_LOAD: begin
        // I-format immediate
        imm[11:0] = instr[31:20];
        imm[31:12] = {20{instr[31]}};
        ctrl_sig.mem_read = 1'b1;
        ctrl_sig.reg_write = 1'b1;
        ctrl_sig.mem_to_reg = 2'b01;  // mem output to reg
        ctrl_sig.alu_src_b = 2'b01;   // compute addr: rs1 + imm
        alu_op = ALU_ADD;
      end
      OP_STORE: begin
        // S-format immediate: split across [31:25] and [11:7]
        imm[11:5] = instr[31:25];
        imm[4:0]  = instr[11:7];
        imm[31:12] = {20{instr[31]}};
        ctrl_sig.mem_write = 1'b1;
        ctrl_sig.alu_src_b = 2'b01;   // compute addr: rs1 + imm
        alu_op = ALU_ADD;
      end
      OP_ARITH: begin //immediate arithmetic
        case (funct3)
          3'b000: alu_op = ALU_ADD;      // ADDI
          3'b001: alu_op = ALU_SLL;      // SLLI
          3'b010: alu_op = ALU_SLT;      // SLTI
          3'b011: alu_op = ALU_SLTU;     // SLTIU
          3'b100: alu_op = ALU_XOR;      // XORI
          3'b101: alu_op = (funct7[5] == 1'b0) ? ALU_SRL : ALU_SRA;  // SRLI vs SRAI
          3'b110: alu_op = ALU_OR;       // ORI
          3'b111: alu_op = ALU_AND;      // ANDI
          default: alu_op = ALU_ADD;
        endcase
        ctrl_sig.reg_write = 1'b1; //wr_en
        ctrl_sig.alu_src_b = 2'b01; //alu b input is imm
        ctrl_sig.mem_to_reg = 2'b00;  //route alu output to reg
        imm[11:0] = instr[31:20];
        imm[31:12] = {20{instr[31]}};  // sign-extend
      end

      OP_COMPUTE: begin //register to register 
      //uses the alu
        case (funct3)
          3'b000: alu_op = (funct7[5] == 1'b0) ? ALU_ADD : ALU_SUB;
          3'b001: alu_op = ALU_SLL;
          3'b010: alu_op = ALU_SLT;
          3'b011: alu_op = ALU_SLTU;
          3'b100: alu_op = ALU_XOR;
          3'b101: alu_op = (funct7[5] == 1'b0) ? ALU_SRL : ALU_SRA;
          3'b110: alu_op = ALU_OR;
          3'b111: alu_op = ALU_AND;
          default: alu_op = ALU_ADD;
        endcase
        ctrl_sig.reg_write = 1'b1; //wr_en
        ctrl_sig.mem_to_reg = 2'b00;  //route alu output to reg
      end
      OP_FENCE: begin
        //not implemented for single-core CPU
      end
      OP_SYSTEM: begin
        //not necessary yet
      end
    endcase
  end


endmodule : instruction_decoder
