// tag_compare.sv
//
// Combinational hit/miss detection. Given the incoming address's tag
// and the set's tag_entry_t array from tag_array, determines whether
// any way hits, which way hit, and (on miss) requests a victim way
// from replacement_policy.

import cache_pkg::*;

module tag_compare (
    input  tag_t                  req_tag,
    input  tag_entry_t            set_entries [WAYS],

    output logic                  hit,
    output way_t                  hit_way,

    // On miss, victim_way is expected to be driven combinationally
    // by replacement_policy based on this same set's LRU state; wired
    // in cache_controller, not read internally here.
    input  way_t                  victim_way,
    output logic                  victim_dirty,
    output tag_t                  victim_tag
);

    always_comb begin
        hit = 1'b0;
        hit_way = '0;

        for (int w = 0; w < WAYS; w++) begin
            if (set_entries[w].valid && set_entries[w].tag == req_tag) begin
                hit = 1'b1;
                hit_way = way_t'(w);
            end
        end
    end

    assign victim_dirty = set_entries[victim_way].dirty;
    assign victim_tag = set_entries[victim_way].tag;

endmodule : tag_compare
