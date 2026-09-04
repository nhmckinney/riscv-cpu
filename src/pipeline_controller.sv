import riscv_pkg::*;

//This modules allows the different stages of the CPU to communicate stalls and flushes

module pipeline_controller(
  input logic clk, rst_n,

  // From decode stage
  input reg_addr_t decode_rs1, decode_rs2,
  input opcode_t decode_opcode,

  // From execute stage
  input reg_addr_t exec_rd,
  input logic exec_reg_write,

  // From memory stage
  input reg_addr_t mem_rd,
  input logic mem_reg_write, mem_read,
  input logic mem_result_valid,

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
      default: begin
        decode_uses_rs1 = 1'b0;
        decode_uses_rs2 = 1'b0;
      end
    endcase
  end




  // A stall-only pipeline must wait for every pending register write, not just
  // loads. The producer in Execute is newer than the producer in Memory, but
  // either one means the register file still contains an old value.
  logic exec_raw_hazard, mem_raw_hazard;

  always_comb begin
    exec_raw_hazard = exec_reg_write && (exec_rd != '0) && (
      (decode_uses_rs1 && (exec_rd == decode_rs1)) ||
      (decode_uses_rs2 && (exec_rd == decode_rs2))
    );

    mem_raw_hazard = mem_reg_write && (mem_rd != '0) && (
      (decode_uses_rs1 && (mem_rd == decode_rs1)) ||
      (decode_uses_rs2 && (mem_rd == decode_rs2))
    );
  end

  


  //stalls the entire CPU upon a cache miss
  logic cache_miss_stall;

  always_comb begin
    cache_miss_stall = mem_read && ~mem_result_valid;
  end


  //stall and flush signals
  always_comb begin
    stall = exec_raw_hazard || mem_raw_hazard || cache_miss_stall;

    // On a RAW hazard, hold the consumer in Decode and inject a bubble into
    // Execute so the older instructions can continue toward Writeback.
    execute_bubble = exec_raw_hazard || mem_raw_hazard;

    // Do not act on a branch condition computed from stale operands.
    fetch_flush = branch_taken && ~stall;
  end

endmodule : pipeline_controller
