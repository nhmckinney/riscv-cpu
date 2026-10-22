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

  // Synchronous single-port data BRAM interface
  output logic mem_req_valid,
  output logic mem_req_write,
  output word_t mem_req_addr,
  output word_t mem_req_wdata,
  output logic [3:0] mem_req_wstrb,
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

  word_t extracted_load_data, registered_alu_result;
  logic [1:0] mem_addr_offset;

  // The RAM output and these registered controls belong to the same request.
  always_comb begin
    extracted_load_data = '0;

    if (mem_ctrl_sig.mem_read) begin
      case (mem_funct3)
        3'b000: begin  // LB (load byte, sign-extend)
          case (mem_addr_offset)
            2'b00: extracted_load_data = {{24{mem_resp_rdata[7]}}, mem_resp_rdata[7:0]};
            2'b01: extracted_load_data = {{24{mem_resp_rdata[15]}}, mem_resp_rdata[15:8]};
            2'b10: extracted_load_data = {{24{mem_resp_rdata[23]}}, mem_resp_rdata[23:16]};
            2'b11: extracted_load_data = {{24{mem_resp_rdata[31]}}, mem_resp_rdata[31:24]};
          endcase
        end
        3'b001: begin  // LH (load halfword, sign-extend)
          case (mem_addr_offset[1])
            1'b0: extracted_load_data = {{16{mem_resp_rdata[15]}}, mem_resp_rdata[15:0]};
            1'b1: extracted_load_data = {{16{mem_resp_rdata[31]}}, mem_resp_rdata[31:16]};
          endcase
        end
        3'b010: begin  // LW (load word)
          extracted_load_data = mem_resp_rdata;
        end
        3'b100: begin  // LBU (load byte, zero-extend)
          case (mem_addr_offset)
            2'b00: extracted_load_data = {24'b0, mem_resp_rdata[7:0]};
            2'b01: extracted_load_data = {24'b0, mem_resp_rdata[15:8]};
            2'b10: extracted_load_data = {24'b0, mem_resp_rdata[23:16]};
            2'b11: extracted_load_data = {24'b0, mem_resp_rdata[31:24]};
          endcase
        end
        3'b101: begin  // LHU (load halfword, zero-extend)
          case (mem_addr_offset[1])
            1'b0: extracted_load_data = {16'b0, mem_resp_rdata[15:0]};
            1'b1: extracted_load_data = {16'b0, mem_resp_rdata[31:16]};
          endcase
        end
        default: extracted_load_data = '0;
      endcase
    end
  end

  // Issue the EX/MEM request; the BRAM samples it on the next rising edge.
  always_comb begin
    mem_req_addr = exec_alu_result;
    // Little-endian stores place the low byte/halfword in the addressed lanes.
    mem_req_wdata = exec_rs2_data << {exec_alu_result[1:0], 3'b000};
    mem_req_wstrb = 4'b0000;

    if (exec_ctrl_sig.mem_write) begin
      case (exec_funct3)
        3'b000: mem_req_wstrb = 4'b0001 << exec_alu_result[1:0]; // SB
        3'b001: begin // SH: only naturally aligned accesses are supported.
          if (exec_alu_result[0] == 1'b0)
            mem_req_wstrb = 4'b0011 << exec_alu_result[1:0];
        end
        3'b010: begin // SW
          if (exec_alu_result[1:0] == 2'b00)
            mem_req_wstrb = 4'b1111;
        end
        default: mem_req_wstrb = 4'b0000;
      endcase
    end

    // Defensive mask: the core takes alignment traps before EX/MEM, so a
    // misaligned store must never reach this interface during normal execution.
    mem_req_write = exec_ctrl_sig.mem_write && (|mem_req_wstrb);
    mem_req_valid = exec_ctrl_sig.mem_read || mem_req_write;
  end

  // BRAM already registers read data. Register only the matching metadata
  // and ALU bypass, then extract the load width in the writeback cycle.
  assign mem_result = mem_ctrl_sig.mem_read ? extracted_load_data : registered_alu_result;

  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      registered_alu_result <= '0;
      mem_addr_offset <= '0;
      mem_result_valid <= 1'b0;
      mem_rd <= '0;
      mem_reg_write <= 1'b0;
      mem_ctrl_sig <= '0;
      mem_funct3 <= '0;
      mem_opcode <= OP_INVALID;
    end
    else begin
      registered_alu_result <= exec_alu_result;
      mem_addr_offset <= exec_alu_result[1:0];
      mem_result_valid <= 1'b1;
      mem_rd <= exec_rd;
      mem_reg_write <= exec_ctrl_sig.reg_write;
      mem_ctrl_sig <= exec_ctrl_sig;
      mem_funct3 <= exec_funct3;
      mem_opcode <= exec_opcode;
    end
  end

endmodule : memory_stage
