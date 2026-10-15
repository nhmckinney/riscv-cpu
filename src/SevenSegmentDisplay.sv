// `default_nettype none

module SevenSegmentDisplay
  (input logic [3:0] BCD7, BCD6, BCD5, BCD4, BCD3, BCD2, BCD1, BCD0,
   input logic [7:0] blank,
   output logic [6:0] HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);

   logic [6:0] nums [8];
   logic [6:0] out [8];

   BCDtoSevenSegment num0(.bcd(BCD0), .segment(nums[0]));
   BCDtoSevenSegment num1(.bcd(BCD1), .segment(nums[1]));
   BCDtoSevenSegment num2(.bcd(BCD2), .segment(nums[2]));
   BCDtoSevenSegment num3(.bcd(BCD3), .segment(nums[3]));
   BCDtoSevenSegment num4(.bcd(BCD4), .segment(nums[4]));
   BCDtoSevenSegment num5(.bcd(BCD5), .segment(nums[5]));
   BCDtoSevenSegment num6(.bcd(BCD6), .segment(nums[6]));
   BCDtoSevenSegment num7(.bcd(BCD7), .segment(nums[7]));

   assign out[0] = (blank[0]) ? 8'b0 : nums[0];
   assign out[1] = (blank[1]) ? 8'b0 : nums[1];
   assign out[2] = (blank[2]) ? 8'b0 : nums[2];
   assign out[3] = (blank[3]) ? 8'b0 : nums[3];
   assign out[4] = (blank[4]) ? 8'b0 : nums[4];
   assign out[5] = (blank[5]) ? 8'b0 : nums[5];
   assign out[6] = (blank[6]) ? 8'b0 : nums[6];
   assign out[7] = (blank[7]) ? 8'b0 : nums[7];

   assign HEX0 = ~out[0];
   assign HEX1 = ~out[1];
   assign HEX2 = ~out[2];
   assign HEX3 = ~out[3];
   assign HEX4 = ~out[4];
   assign HEX5 = ~out[5];
   assign HEX6 = ~out[6];
   assign HEX7 = ~out[7];

endmodule: SevenSegmentDisplay

module BCDtoSevenSegment
  (input logic [3:0] bcd,
   output logic [6:0] segment);

  always_comb
    case (bcd)
      4'h0: segment = 7'b011_1111;
      4'h1: segment = 7'b000_0110;
      4'h2: segment = 7'b101_1011;
      4'h3: segment = 7'b100_1111;
      4'h4: segment = 7'b110_0110;
      4'h5: segment = 7'b110_1101;
      4'h6: segment = 7'b111_1101;
      4'h7: segment = 7'b000_0111;
      4'h8: segment = 7'b111_1111;
      4'h9: segment = 7'b110_0111;
      4'hA: segment = 7'b111_0111;
      4'hB: segment = 7'b111_1100;
      4'hC: segment = 7'b011_1001;
      4'hD: segment = 7'b101_1110;
      4'hE: segment = 7'b111_1001;
      4'hF: segment = 7'b111_0001;
      default: segment = 7'b000_0000;
    endcase

endmodule: BCDtoSevenSegment
