import cache_pkg::*;

module replacement_policy (
    input  logic                  clk,
    input  logic                  rst_n,

    // Update on access: mark way as most-recently-used for this set
    input  logic                  touch_en,
    input  index_t                touch_index,
    input  way_t                  touch_way,

    // Victim query (combinational, current LRU state for the set)
    input  index_t                victim_index,
    output way_t                  victim_way
);

    // LRU state: for each set, track which way was least-recently-used.
    // For a 2-way cache, a single bit suffices: 0 means way 0 is LRU, 1 means way 1 is LRU.
    logic lru_state [NUM_SETS];

    assign victim_way = way_t'(lru_state[victim_index]);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int s = 0; s < NUM_SETS; s++) begin
                lru_state[s] <= 1'b0;
            end
        end else if (touch_en) begin
            lru_state[touch_index] <= ~touch_way;
        end
    end

endmodule : replacement_policy
