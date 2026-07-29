// tag_array.sv
//
// Storage for tag/valid/dirty metadata, NUM_SETS x WAYS entries.
// Purely storage + combinational read

import cache_pkg::*;

module tag_array (
    input  logic                  clk,
    input  logic                  rst_n,

    // Read port combinational
    input  index_t                rd_index,
    output tag_entry_t            rd_entries [WAYS],

    // Write port (synchronous, single way)
    input  logic                  wr_en,
    input  index_t                wr_index,
    input  way_t                  wr_way,
    input  tag_entry_t             wr_entry
);

    tag_entry_t mem [NUM_SETS][WAYS];

    // Combinational read: return all ways for the requested set
    assign rd_entries = mem[rd_index];

    // Synchronous write: single way
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int s = 0; s < NUM_SETS; s++) begin
                for (int w = 0; w < WAYS; w++) begin
                    mem[s][w].valid <= 1'b0;
                    mem[s][w].dirty <= 1'b0;
                    mem[s][w].tag <= '0;
                end
            end
        end else if (wr_en) begin
            mem[wr_index][wr_way] <= wr_entry;
        end
    end

endmodule : tag_array
