import riscv_pkg::*;

//This modules allows the different stages of the CPU to communicate stalls and flushes

module pipeline_controller(
  input logic clk, rst_n,

  // From decode stage
  input reg_addr_t decode_rs1, decode_rs2,
  input opcode_t decode_opcode,
  input logic [2:0] decode_funct3,

  // From execute stage
  input reg_addr_t exec_rd,
  input logic exec_reg_write, exec_mem_read,

  // Branch signal
  input logic branch_taken,

  // Control outputs
  output logic stall,
  output logic execute_bubble,
  output logic fetch_flush
);

  logic decode_uses_rs1, decode_uses_rs2;

  always_comb begin
    case (decode_opcode)
      OP_LUI, OP_AUIPC, OP_JAL: begin
        decode_uses_rs1 = 1'b0;
        decode_uses_rs2 = 1'b0;
      end
      OP_JALR, OP_LOAD, OP_ARITH: begin
        decode_uses_rs1 = 1'b1;
        decode_uses_rs2 = 1'b0;
      end
      OP_BRANCH, OP_STORE, OP_COMPUTE: begin
        decode_uses_rs1 = 1'b1;
        decode_uses_rs2 = 1'b1;
      end
      OP_SYSTEM: begin
        // CSR register forms consume rs1; immediate forms use its encoding.
        decode_uses_rs1 = (decode_funct3 == 3'b001) ||
                          (decode_funct3 == 3'b010) ||
                          (decode_funct3 == 3'b011);
        decode_uses_rs2 = 1'b0;
      end
      default: begin
        decode_uses_rs1 = 1'b0;
        decode_uses_rs2 = 1'b0;
      end
    endcase
  end




  // ALU dependencies are handled by forwarding. A load-use dependency still
  // needs one bubble because the EX/MEM value is the address, not loaded data.
  logic load_use_hazard;

  always_comb begin
    load_use_hazard = exec_reg_write && exec_mem_read && (exec_rd != '0) && (
      (decode_uses_rs1 && (exec_rd == decode_rs1)) ||
      (decode_uses_rs2 && (exec_rd == decode_rs2))
    );
  end

  


  //stall and flush signals
  always_comb begin
    stall = load_use_hazard;

    // Hold the consumer in Decode while the load advances to MEM/WB.
    execute_bubble = load_use_hazard;

    // Do not act on a branch condition computed from stale operands.
    fetch_flush = branch_taken && ~stall;
  end

endmodule : pipeline_controller
