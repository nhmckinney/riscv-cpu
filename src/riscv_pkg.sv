package riscv_pkg;

  // Word width
  parameter int XLEN = 32;
  typedef logic [XLEN-1:0] word_t;

  // Instruction format
  typedef logic [31:0] instr_t;

  // Register address
  typedef logic [4:0] reg_addr_t;

  // Immediate values
  typedef logic [31:0] imm_t;

  // Opcodes (7 bits)
  typedef enum logic [6:0] {
    OP_INVALID = 7'b0000000,
    OP_LUI    = 7'b0110111,
    OP_AUIPC  = 7'b0010111,
    OP_JAL    = 7'b1101111,
    OP_JALR   = 7'b1100111,
    OP_BRANCH = 7'b1100011,
    OP_LOAD   = 7'b0000011,
    OP_STORE  = 7'b0100011,
    OP_ARITH  = 7'b0010011,
    OP_COMPUTE= 7'b0110011,
    OP_FENCE  = 7'b0001111,
    OP_SYSTEM = 7'b1110011
  } opcode_t;

  // ALU operations (from funct3 and funct7)
  typedef enum logic [3:0] {
    ALU_NOP   = 4'b1110,
    ALU_ADD   = 4'b0000,
    ALU_SUB   = 4'b1000,
    ALU_SLL   = 4'b0001,
    ALU_SLT   = 4'b0010,
    ALU_SLTU  = 4'b0011,
    ALU_XOR   = 4'b0100,
    ALU_SRL   = 4'b0101,
    ALU_SRA   = 4'b1101,
    ALU_OR    = 4'b0110,
    ALU_AND   = 4'b0111
  } alu_op_t;

  // Branch conditions (funct3)
  typedef enum logic [2:0] {
    BRANCH_EQ  = 3'b000,
    BRANCH_NE  = 3'b001,
    BRANCH_LT  = 3'b100,
    BRANCH_GE  = 3'b101,
    BRANCH_LTU = 3'b110,
    BRANCH_GEU = 3'b111
  } branch_cond_t;

  // Control signals
  typedef struct packed {
    logic [1:0] alu_src_a;      // 0: rs1, 1: pc, 2: zero
    logic [1:0] alu_src_b;      // 0: rs2, 1: imm, 2: 4
    logic       reg_write;
    logic       mem_read;
    logic       mem_write;
    logic [1:0] mem_to_reg;     // 0: alu, 1: mem, 2: pc+4
    logic       is_branch;
    logic       is_jump;
  } ctrl_signals_t;

endpackage
