import riscv_pkg::*;

// Machine mode only. All exceptions are resolved before the instruction
// enters EX/MEM; older fixed-latency memory/writeback operations may finish.
module trap_unit(
  input logic clk, rst_n,
  input logic instruction_valid,
  input word_t instruction_pc,
  input logic exception_valid,
  input word_t exception_cause, exception_tval,
  input logic mret,
  input logic csr_en,
  input logic [11:0] csr_addr,
  input logic [2:0] csr_funct3,
  input logic csr_source_zero,
  input word_t csr_source,
  input logic irq_software, irq_timer, irq_external,
  output word_t csr_rdata,
  output logic csr_illegal,
  output logic trap_taken, return_taken, redirect_valid,
  output word_t redirect_pc, trap_cause, trap_tval
);
  localparam word_t IRQ_MASK = 32'h00000888;
  localparam word_t STATUS_MASK = 32'h00000088; // MIE, MPIE
  localparam word_t MPP_MACHINE = 32'h00001800;

  word_t mstatus, mie, mtvec, mscratch, mepc, mcause, mtval, mip;
  word_t csr_wdata;
  logic csr_known, csr_write, interrupt_pending;
  word_t interrupt_cause;

  assign mip = (irq_external ? 32'h00000800 : 32'b0) |
               (irq_timer ? 32'h00000080 : 32'b0) |
               (irq_software ? 32'h00000008 : 32'b0);

  always_comb begin
    csr_known = 1'b1;
    csr_rdata = '0;
    case (csr_addr)
      12'h300: csr_rdata = mstatus;
      12'h301: csr_rdata = 32'h40000100; // RV32I; fixed ISA, writes ignored
      12'h304: csr_rdata = mie;
      12'h305: csr_rdata = mtvec;
      12'h340: csr_rdata = mscratch;
      12'h341: csr_rdata = mepc;
      12'h342: csr_rdata = mcause;
      12'h343: csr_rdata = mtval;
      12'h344: csr_rdata = mip; // external pending lines; writes ignored
      12'hf11, 12'hf12, 12'hf13, 12'hf14: csr_rdata = '0;
      default: csr_known = 1'b0;
    endcase

    // CSRRS/CSRRC suppress writes based on the encoded source register/zimm,
    // not on its value. CSRRW always writes, even for source x0.
    csr_write = (csr_funct3[1:0] == 2'b01) || !csr_source_zero;
    case (csr_funct3[1:0])
      2'b01: csr_wdata = csr_source;
      2'b10: csr_wdata = csr_rdata | csr_source;
      2'b11: csr_wdata = csr_rdata & ~csr_source;
      default: csr_wdata = '0;
    endcase
    csr_illegal = csr_en && (!csr_known ||
                  (csr_funct3[1:0] == 2'b00) ||
                  (csr_write && (csr_addr[11:10] == 2'b11)));
  end

  always_comb begin
    interrupt_pending = mstatus[3] && (|(mip & mie));
    // Standard machine interrupt priority: external, software, timer.
    if (mip[11] && mie[11]) interrupt_cause = 32'h8000000b;
    else if (mip[3] && mie[3]) interrupt_cause = 32'h80000003;
    else interrupt_cause = 32'h80000007;

    trap_cause = exception_valid ? exception_cause :
                 (csr_illegal ? CAUSE_ILLEGAL_INSTR : interrupt_cause);
    trap_tval = exception_valid ? exception_tval : '0;
    trap_taken = instruction_valid &&
                 (exception_valid || csr_illegal || interrupt_pending);
    return_taken = instruction_valid && mret && !trap_taken;
    redirect_valid = trap_taken || return_taken;
    redirect_pc = trap_taken ? mtvec : mepc;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mstatus <= MPP_MACHINE;
      mie <= '0;
      mtvec <= '0;
      mscratch <= '0;
      mepc <= '0;
      mcause <= '0;
      mtval <= '0;
    end else if (trap_taken) begin
      mepc <= {instruction_pc[31:2], 2'b00};
      mcause <= trap_cause;
      mtval <= trap_tval;
      mstatus[7] <= mstatus[3];
      mstatus[3] <= 1'b0;
    end else if (return_taken) begin
      mstatus[3] <= mstatus[7];
      mstatus[7] <= 1'b1;
    end else if (instruction_valid && csr_en && !csr_illegal && csr_write) begin
      case (csr_addr)
        12'h300: mstatus <= (csr_wdata & STATUS_MASK) | MPP_MACHINE;
        12'h304: mie <= csr_wdata & IRQ_MASK;
        12'h305: mtvec <= {csr_wdata[31:2], 2'b00}; // direct mode only
        12'h340: mscratch <= csr_wdata;
        12'h341: mepc <= {csr_wdata[31:2], 2'b00}; // IALIGN=32
        12'h342: mcause <= csr_wdata;
        12'h343: mtval <= csr_wdata;
        default: begin end
      endcase
    end
  end
endmodule : trap_unit
