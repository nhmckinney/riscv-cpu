// Required in every 18-240 file, but commented out to prevent synthesis issues
// `default_nettype none

/*
 * This module should be interfaced with a combinational 7-Segment Display
 * module in order to display 8 BCD values upon the Boolean board. It is
 * intended to abstract away the sequential logic required to use the
 * 7-Segment Displays present on the Boolean board for 18-240 students.
 *
 * Date:   1/27/25
 * Author: Rudy Sorensen (rsorense)
 */

module SSegDisplayDriver (
  input  logic            clk,
  input  logic            reset,
  input  logic [6:0] HEX0,
  input  logic [6:0] HEX1,
  input  logic [6:0] HEX2,
  input  logic [6:0] HEX3,
  input  logic [6:0] HEX4,
  input  logic [6:0] HEX5,
  input  logic [6:0] HEX6,
  input  logic [6:0] HEX7,
  input  logic [7:0] dpoints,
  output logic [3:0] D1_AN,
  output logic [3:0] D2_AN,
  output logic [7:0] D1_SEG,
  output logic [7:0] D2_SEG
  );

  logic cycle_cnt_clr;
  logic index_cnt_en;
  logic [1:0] anode_index;
  logic [3:0] anode_index_onecold;
  logic [16:0] cycle_cnt;

  /*
   * This counter reset value should be calculated by hand using the frequency
   * of your source clock to achieve the target frequency of 250Hz to 10KHz.
   *
   * The lower limit to the frequency comes from the fact that the human eye
   * de-saturates after around 20ms, while the upper limit is derived from the
   * need for the display to be on for at least 100us so that the value can
   * actually be perceived.
   *
   * Since the Boolean board has a 100MHz clock, we will count to 100,000. This
   * means that each segment will be lit for 1ms and flashed again 3ms later
   * because we are cycling through 4 values for each segment.
   */

  localparam CNT_LIMIT = 17'd100_000;

  assign cycle_cnt_clr = cycle_cnt == CNT_LIMIT;
  assign index_cnt_en = cycle_cnt_clr;

  SSDCounter #(17) cycle_cntr (
    .clk,
    .reset,
    .clr(cycle_cnt_clr),
    .cnt(cycle_cnt),
    .en(1'b1)
    );

  SSDCounter #(2) index_cntr (
    .clk,
    .reset,
    .clr(1'b0),
    .cnt(anode_index),
    .en(index_cnt_en)
    );

  OneColdDecoder #(4) anode_decode (
    .sel(anode_index),
    .out(anode_index_onecold)
    );

  /*
   *  AN3   AN1        AN3   AN1
   *  HX7   HX5        HX3   HX1
   *   | AN2 | AN0      | AN2 | AN0
   *   | HX6 | HX4      | HX2 | HX0
   * +-|--|--|--|--+  +-|--|--|--|--+
   * |             |  |             |
   * |  DISPLAY 1  |  |  DISPLAY 2  |
   * |             |  |             |
   * +-------------+  +-------------+
   *
   * The layout of the 7-Segment displays on the Boolean board is shown above to
   * aid understanding of the below block of code. Note that the HEX inputs are
   * not actually connected to the anodes. This visualization is just meant to
   * show the relationship between values from the HEX input and the anodes on
   * the 7-Segment displays.
   */

  always_comb begin
    D1_AN = anode_index_onecold;
    D2_AN = anode_index_onecold;

    case (anode_index)
      2'd0: begin
        D2_SEG = {~dpoints[0], HEX0};
        D1_SEG = {~dpoints[4], HEX4};
      end
      2'd1: begin
        D2_SEG = {~dpoints[1], HEX1};
        D1_SEG = {~dpoints[5], HEX5};
      end
      2'd2: begin
        D2_SEG = {~dpoints[2], HEX2};
        D1_SEG = {~dpoints[6], HEX6};
      end
      2'd3: begin
        D2_SEG = {~dpoints[3], HEX3};
        D1_SEG = {~dpoints[7], HEX7};
      end
    endcase

  end

endmodule : SSegDisplayDriver

module OneColdDecoder #(
  parameter NUM_OUTPUTS = 4
  ) (
  input  logic [$clog2(NUM_OUTPUTS)-1:0] sel,
  output logic [NUM_OUTPUTS-1:0] out
  );

  always_comb begin
    out = {NUM_OUTPUTS{1'b1}};
    out[sel] = 1'b0;
  end

endmodule : OneColdDecoder

module SSDCounter #(
  parameter WIDTH = 8
  ) (
  input  logic clk,
  input  logic reset,
  input  logic clr,
  input  logic en,
  output logic [WIDTH-1:0] cnt
  );

  always_ff @(posedge clk, posedge reset) begin
    if (reset)
      cnt <= '0;
    else if (clr)
      cnt <= '0;
    else if (en)
      cnt <= cnt + 1'b1;
  end

endmodule : SSDCounter
