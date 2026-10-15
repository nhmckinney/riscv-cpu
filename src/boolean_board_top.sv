// Boolean Board interface for the built-in RV32I demo program.
// SW[4:0] selects a register; SW[5] selects PC instead.
// BTN[0] resets the CPU and display scan counters (active high).
module boolean_board_top(
  input  logic       CLOCK_100,
  input  logic [5:0] SW,
  input  logic [0:0] BTN,
  output logic [2:0] LD,
  output logic [3:0] D0_AN, D1_AN,
  output logic [7:0] D0_SEG, D1_SEG
);

  logic [31:0] register_value, pc_value, display_value;
  logic stall, branch_taken, mem_result_valid;
  logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7;

  riscv_core cpu (
    .clk(CLOCK_100),
    .rst_n(~BTN[0]),
    .stall_out(stall),
    .branch_taken_out(branch_taken),
    .mem_result_valid_out(mem_result_valid),
    .debug_rd_addr(SW[4:0]),
    .debug_rd_data(register_value),
    .debug_pc(pc_value)
  );

  assign display_value = SW[5] ? pc_value : register_value;
  assign LD = {mem_result_valid, branch_taken, stall};

  // These inputs are hexadecimal nibbles; the reference decoder also
  // renders A-F, so no binary-to-decimal conversion is needed.
  SevenSegmentDisplay hex_decoder (
    .BCD0(display_value[3:0]),
    .BCD1(display_value[7:4]),
    .BCD2(display_value[11:8]),
    .BCD3(display_value[15:12]),
    .BCD4(display_value[19:16]),
    .BCD5(display_value[23:20]),
    .BCD6(display_value[27:24]),
    .BCD7(display_value[31:28]),
    .blank(8'b0),
    .HEX0, .HEX1, .HEX2, .HEX3,
    .HEX4, .HEX5, .HEX6, .HEX7
  );

  // The course driver calls its right-hand display D2; the board XDC
  // calls that physical display D0.
  SSegDisplayDriver display_driver (
    .clk(CLOCK_100),
    .reset(BTN[0]),
    .HEX0, .HEX1, .HEX2, .HEX3,
    .HEX4, .HEX5, .HEX6, .HEX7,
    .dpoints(8'b0),
    .D1_AN,
    .D2_AN(D0_AN),
    .D1_SEG,
    .D2_SEG(D0_SEG)
  );

endmodule : boolean_board_top
