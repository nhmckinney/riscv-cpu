`timescale 1ns / 1ps

module cpu_top_tb;

  logic clk, reset;
  logic [15:0] LED;
  logic [4:0] debug_rd_addr;
  logic [31:0] debug_rd_data, debug_pc;

  cpu_top dut(
    .clk(clk),
    .reset(reset),
    .LED(LED),
    .debug_rd_addr(debug_rd_addr),
    .debug_rd_data(debug_rd_data),
    .debug_pc(debug_pc)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100 MHz
  end

  // Helper task to read register
  task read_reg(input [4:0] reg_idx);
    debug_rd_addr = reg_idx;
    #1;
    $display("  x%0d = 0x%08h", reg_idx, debug_rd_data);
  endtask

  // Test stimulus
  initial begin
    $display("=== RV32I CPU Simulation ===");
    $display("Test: Simple ADD operation (x1=5, x2=3, x3=x1+x2)");
    $display("");

    reset = 1;
    debug_rd_addr = 0;
    #20 reset = 0;

    // Run for 20 cycles and monitor
    repeat(20) begin
      @(posedge clk);
      #1;
      $display("Cycle %0d: PC=0x%08h | Stall=%b | Branch=%b | MemValid=%b",
               $time/10, debug_pc, LED[0], LED[1], LED[2]);
    end

    $display("");
    $display("=== Register File State ===");
    read_reg(1);
    read_reg(2);
    read_reg(3);

    $display("");
    debug_rd_addr = 3;
    #1;
    if (debug_rd_data == 32'd8) begin
      $display("✓ TEST PASSED: x3 = 8 (expected result)");
    end else begin
      $display("✗ TEST FAILED: x3 = %0d (expected 8)", debug_rd_data);
    end

    $finish;
  end

endmodule : cpu_top_tb
