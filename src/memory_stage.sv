import riscv_pkg::*;

module memory_stage(
  input logic clk, rst_n,

  // From execute pipeline register
  input word_t exec_alu_result,
  input word_t exec_rs2_data,
  input reg_addr_t exec_rd,
  input ctrl_signals_t exec_ctrl_sig,
  input logic [2:0] exec_funct3,
  input opcode_t exec_opcode,

  // Simple single-cycle data memory interface (no cache)
  output logic mem_req_valid,
  output logic mem_req_write,
  output word_t mem_req_addr,
  output word_t mem_req_wdata,
  input word_t mem_resp_rdata,

  // Outputs to writeback stage (registered)
  output word_t mem_result,
  output logic mem_result_valid,
  output reg_addr_t mem_rd,
  output logic mem_reg_write,
  output ctrl_signals_t mem_ctrl_sig,
  output logic [2:0] mem_funct3,
  output opcode_t mem_opcode
);

  word_t extracted_load_data;

  // Extract loaded data based on funct3 (load width)
  always_comb begin
    extracted_load_data = '0;

    if (exec_ctrl_sig.mem_read) begin
      case (exec_funct3)
        3'b000: begin  // LB (load byte, sign-extend)
          case (exec_alu_result[1:0])
            2'b00: extracted_load_data = {{24{mem_resp_rdata[7]}}, mem_resp_rdata[7:0]};
            2'b01: extracted_load_data = {{24{mem_resp_rdata[15]}}, mem_resp_rdata[15:8]};
            2'b10: extracted_load_data = {{24{mem_resp_rdata[23]}}, mem_resp_rdata[23:16]};
            2'b11: extracted_load_data = {{24{mem_resp_rdata[31]}}, mem_resp_rdata[31:24]};
          endcase
        end
        3'b001: begin  // LH (load halfword, sign-extend)
          case (exec_alu_result[1])
            1'b0: extracted_load_data = {{16{mem_resp_rdata[15]}}, mem_resp_rdata[15:0]};
            1'b1: extracted_load_data = {{16{mem_resp_rdata[31]}}, mem_resp_rdata[31:16]};
          endcase
        end
        3'b010: begin  // LW (load word)
          extracted_load_data = mem_resp_rdata;
        end
        3'b100: begin  // LBU (load byte, zero-extend)
          case (exec_alu_result[1:0])
            2'b00: extracted_load_data = {24'b0, mem_resp_rdata[7:0]};
            2'b01: extracted_load_data = {24'b0, mem_resp_rdata[15:8]};
            2'b10: extracted_load_data = {24'b0, mem_resp_rdata[23:16]};
            2'b11: extracted_load_data = {24'b0, mem_resp_rdata[31:24]};
          endcase
        end
        3'b101: begin  // LHU (load halfword, zero-extend)
          case (exec_alu_result[1])
            1'b0: extracted_load_data = {16'b0, mem_resp_rdata[15:0]};
            1'b1: extracted_load_data = {16'b0, mem_resp_rdata[31:16]};
          endcase
        end
        default: extracted_load_data = '0;
      endcase
    end
  end

  // Drive simple memory request (single-cycle interface)
  always_comb begin
    mem_req_valid = exec_ctrl_sig.mem_read || exec_ctrl_sig.mem_write;
    mem_req_write = exec_ctrl_sig.mem_write;
    mem_req_addr = exec_alu_result;
    mem_req_wdata = exec_rs2_data;
  end

  



// For simulation: memory operations are single-cycle (no stalling)
// In real FPGA with cache, this would be gated by cache_resp_valid
  word_t mem_result_next;
  logic mem_result_valid_next;

  always_comb begin
    if (exec_ctrl_sig.mem_read) begin
      mem_result_next = extracted_load_data;
      mem_result_valid_next = 1'b1;
    end
    else if (~exec_ctrl_sig.mem_read && ~exec_ctrl_sig.mem_write) begin
      mem_result_next = exec_alu_result;
      mem_result_valid_next = 1'b1;
    end
    else if (exec_ctrl_sig.mem_write) begin
      mem_result_next = exec_alu_result;
      mem_result_valid_next = 1'b1;
    end
    else begin
      mem_result_next = '0;
      mem_result_valid_next = 1'b0;
    end
  end





  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      mem_result <= '0;
      mem_result_valid <= 1'b0;
      mem_rd <= '0;
      mem_reg_write <= 1'b0;
      mem_ctrl_sig <= '0;
      mem_funct3 <= '0;
      mem_opcode <= OP_INVALID;
    end
    else begin
      mem_result <= mem_result_next;
      mem_result_valid <= mem_result_valid_next;
      mem_rd <= exec_rd;
      mem_reg_write <= exec_ctrl_sig.reg_write;
      mem_ctrl_sig <= exec_ctrl_sig;
      mem_funct3 <= exec_funct3;
      mem_opcode <= exec_opcode;
    end
  end

endmodule : memory_stage
