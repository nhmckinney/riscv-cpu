import riscv_pkg::*;
import cache_pkg::*;

module memory_stage(
  input logic clk, rst_n,

  // From execute pipeline register
  input word_t exec_alu_result,
  input word_t exec_rs2_data,
  input reg_addr_t exec_rd,
  input ctrl_signals_t exec_ctrl_sig,
  input logic [2:0] exec_funct3,
  input opcode_t exec_opcode,

  // Cache interface
  output logic cache_req_valid,
  input logic cache_req_ready,
  output cache_pkg::addr_t cache_req_addr,
  output cache_pkg::req_kind_e cache_req_kind,
  output cache_pkg::data_t cache_req_wdata,

  input logic cache_resp_valid,
  input cache_pkg::data_t cache_resp_rdata,
  input logic cache_resp_hit,

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

  always_comb begin
    extracted_load_data = '0;

    if (exec_ctrl_sig.mem_read && cache_resp_valid) begin
      case (exec_funct3)
        3'b000: begin  // LB (load byte, sign-extend)
          case (exec_alu_result[1:0])
            2'b00: extracted_load_data = {{24{cache_resp_rdata[7]}}, cache_resp_rdata[7:0]};
            2'b01: extracted_load_data = {{24{cache_resp_rdata[15]}}, cache_resp_rdata[15:8]};
            2'b10: extracted_load_data = {{24{cache_resp_rdata[23]}}, cache_resp_rdata[23:16]};
            2'b11: extracted_load_data = {{24{cache_resp_rdata[31]}}, cache_resp_rdata[31:24]};
          endcase
        end
        3'b001: begin  // LH (load halfword, sign-extend)
          case (exec_alu_result[1])
            1'b0: extracted_load_data = {{16{cache_resp_rdata[15]}}, cache_resp_rdata[15:0]};
            1'b1: extracted_load_data = {{16{cache_resp_rdata[31]}}, cache_resp_rdata[31:16]};
          endcase
        end
        3'b010: begin  // LW (load word)
          extracted_load_data = cache_resp_rdata;
        end
        3'b100: begin  // LBU (load byte, zero-extend)
          case (exec_alu_result[1:0])
            2'b00: extracted_load_data = {24'b0, cache_resp_rdata[7:0]};
            2'b01: extracted_load_data = {24'b0, cache_resp_rdata[15:8]};
            2'b10: extracted_load_data = {24'b0, cache_resp_rdata[23:16]};
            2'b11: extracted_load_data = {24'b0, cache_resp_rdata[31:24]};
          endcase
        end
        3'b101: begin  // LHU (load halfword, zero-extend)
          case (exec_alu_result[1])
            1'b0: extracted_load_data = {16'b0, cache_resp_rdata[15:0]};
            1'b1: extracted_load_data = {16'b0, cache_resp_rdata[31:16]};
          endcase
        end
        default: extracted_load_data = '0;
      endcase
    end
  end

  //drive cache request
  always_comb begin
    cache_req_valid = exec_ctrl_sig.mem_read || exec_ctrl_sig.mem_write;
    cache_req_addr = exec_alu_result;
    cache_req_kind = exec_ctrl_sig.mem_write ? cache_pkg::REQ_WRITE : cache_pkg::REQ_READ;
    cache_req_wdata = exec_rs2_data;
  end

  




// mux between loaded data and ALU result
  word_t mem_result_next;
  logic mem_result_valid_next;

  always_comb begin
    if (exec_ctrl_sig.mem_read && cache_resp_valid) begin
      mem_result_next = extracted_load_data;
      mem_result_valid_next = 1'b1;
    end
    else if (~exec_ctrl_sig.mem_read && ~exec_ctrl_sig.mem_write) begin
      mem_result_next = exec_alu_result;
      mem_result_valid_next = 1'b1;
    end
    else if (exec_ctrl_sig.mem_write && cache_resp_valid) begin
      mem_result_next = exec_alu_result;  // for non-load ops, pass through ALU result
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
      mem_opcode <= '0;
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
