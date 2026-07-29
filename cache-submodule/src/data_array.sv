// data_array.sv
//
// Storage for cache line data, NUM_SETS x WAYS entries, each LINE_SIZE
// bytes wide. Purely storage; word-level read/write within a line is
// handled by the caller using rd_index/rd_way plus the byte offset.

import cache_pkg::*;

module data_array (
    input  logic                  clk,
    input  logic                  rst_n,

    // Read port (combinational)
    input  index_t                rd_index,
    input  way_t                  rd_way,
    output line_data_t            rd_line,

    // Write port (synchronous, full-line write, e.g. on a fill)
    input  logic                  wr_en,
    input  index_t                wr_index,
    input  way_t                  wr_way,
    input  line_data_t            wr_line,

    // Partial-word write port (synchronous, single word within a line,
    // e.g. on a write-hit that shouldn't require a full line rewrite)
    input  logic                  wr_word_en,
    input  index_t                wr_word_index,
    input  way_t                  wr_word_way,
    input  offset_t               wr_word_offset,
    input  data_t                 wr_word_data
);

    line_data_t mem [NUM_SETS][WAYS];

    assign rd_line = mem[rd_index][rd_way];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int s = 0; s < NUM_SETS; s++) begin
                for (int w = 0; w < WAYS; w++) begin
                    mem[s][w] <= '0;
                end
            end
        end else begin
            if (wr_en) begin
                mem[wr_index][wr_way] <= wr_line;
            end
            if (wr_word_en) begin
                mem[wr_word_index][wr_word_way][(wr_word_offset * DATA_WIDTH) +: DATA_WIDTH] <= wr_word_data;
            end
        end
    end

endmodule : data_array
