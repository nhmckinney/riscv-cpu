// miss_fsm.sv
//
// Multi-cycle miss handler. Intended state sequence on a miss:
//   IDLE
//     -> CHECK_DIRTY   (combinational: look at victim_dirty from tag_compare)
//     -> WRITEBACK      (if victim dirty: issue MEM_WRITE to mem_if, wait req_done)
//     -> FILL_REQ       (issue MEM_READ to mem_if for the new line)
//     -> FILL_WAIT      (wait for mem_if req_done)
//     -> FILL_COMMIT    (write tag_array + data_array, touch replacement_policy)
//     -> IDLE
//
// This module owns the stall signal back to cache_controller: the
// pipeline should hold the requesting transaction until miss_fsm
// returns to IDLE with done asserted.

import cache_pkg::*;

typedef enum logic [2:0] {
    MISS_IDLE,
    MISS_CHECK_DIRTY,
    MISS_WRITEBACK,
    MISS_FILL_REQ,
    MISS_FILL_WAIT,
    MISS_FILL_COMMIT
} miss_state_e;

module miss_fsm (
    input  logic                  clk,
    input  logic                  rst_n,

    // Miss request in (from cache_controller, on a tag_compare miss)
    input  logic                  miss_valid,
    input  addr_fields_t          miss_addr,
    input  req_kind_e              miss_kind,     // REQ_READ or REQ_WRITE
    input  data_t                  miss_wdata,    // valid for REQ_WRITE
    input  offset_t                miss_wr_offset,

    // Victim info (from tag_compare / replacement_policy, sampled at miss_valid)
    input  way_t                   victim_way,
    input  logic                   victim_dirty,
    input  tag_t                   victim_tag,
    input  line_data_t             victim_line,   // for writeback

    // Interface to mem_if
    output logic                   mem_req_valid,
    output mem_op_e                mem_req_op,
    output addr_t                  mem_req_addr,
    output line_data_t             mem_req_wdata,
    input  logic                   mem_req_done,
    input  line_data_t             mem_rd_line,

    // Interface to tag_array / data_array (fill commit)
    output logic                   fill_wr_en,
    output tag_entry_t              fill_tag_entry,
    output line_data_t             fill_line,

    // Interface to replacement_policy (touch on fill commit)
    output logic                   fill_touch_en,

    // Status back to cache_controller
    output logic                   busy,
    output logic                   done          // pulses one cycle on completion
);

    miss_state_e state, next_state;
    addr_fields_t miss_addr_saved;
    req_kind_e miss_kind_saved;
    data_t miss_wdata_saved;
    offset_t miss_wr_offset_saved;
    way_t victim_way_saved;
    line_data_t fetched_line;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= MISS_IDLE;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        next_state = state;
        mem_req_valid = 1'b0;
        mem_req_op = MEM_READ;
        mem_req_addr = {miss_addr_saved.tag, miss_addr_saved.index, {OFFSET_WIDTH{1'b0}}};
        mem_req_wdata = '0;
        fill_wr_en = 1'b0;
        fill_tag_entry = '0;
        fill_line = '0;
        fill_touch_en = 1'b0;
        busy = 1'b0;
        done = 1'b0;

        case (state)
            MISS_IDLE: begin
                if (miss_valid) begin
                    next_state = MISS_CHECK_DIRTY;
                end
            end

            MISS_CHECK_DIRTY: begin
                busy = 1'b1;
                if (victim_dirty) begin
                    next_state = MISS_WRITEBACK;
                end else begin
                    next_state = MISS_FILL_REQ;
                end
            end

            MISS_WRITEBACK: begin
                busy = 1'b1;
                mem_req_valid = 1'b1;
                mem_req_op = MEM_WRITE;
                mem_req_addr = {victim_tag_saved, miss_addr_saved.index, {OFFSET_WIDTH{1'b0}}};
                mem_req_wdata = victim_line_saved;
                if (mem_req_done) begin
                    next_state = MISS_FILL_REQ;
                end
            end

            MISS_FILL_REQ: begin
                busy = 1'b1;
                mem_req_valid = 1'b1;
                mem_req_op = MEM_READ;
                mem_req_addr = {miss_addr_saved.tag, miss_addr_saved.index, {OFFSET_WIDTH{1'b0}}};
                if (mem_req_done) begin
                    next_state = MISS_FILL_WAIT;
                end
            end

            MISS_FILL_WAIT: begin
                busy = 1'b1;
                if (mem_req_done) begin
                    next_state = MISS_FILL_COMMIT;
                end
            end

            MISS_FILL_COMMIT: begin
                busy = 1'b1;
                fill_wr_en = 1'b1;
                fill_tag_entry.valid = 1'b1;
                fill_tag_entry.dirty = 1'b0;
                fill_tag_entry.tag = miss_addr_saved.tag;
                fill_line = fetched_line;
                fill_touch_en = 1'b1;
                next_state = MISS_IDLE;
                done = 1'b1;
            end

            default: next_state = MISS_IDLE;
        endcase
    end

    // Sample miss inputs and victim info on entry
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            miss_addr_saved <= '0;
            miss_kind_saved <= REQ_NONE;
            miss_wdata_saved <= '0;
            miss_wr_offset_saved <= '0;
            victim_way_saved <= '0;
        end else if (state == MISS_IDLE && next_state == MISS_CHECK_DIRTY) begin
            miss_addr_saved <= miss_addr;
            miss_kind_saved <= miss_kind;
            miss_wdata_saved <= miss_wdata;
            miss_wr_offset_saved <= miss_wr_offset;
            victim_way_saved <= victim_way;
        end
    end

    // Capture fetched line on fill_wait->fill_commit transition
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fetched_line <= '0;
        end else if (state == MISS_FILL_WAIT && mem_req_done) begin
            fetched_line <= mem_rd_line;
        end
    end

    // Latch victim_dirty and victim_tag for writeback (needed across cycles)
    logic victim_dirty_saved;
    tag_t victim_tag_saved;
    line_data_t victim_line_saved;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            victim_dirty_saved <= 1'b0;
            victim_tag_saved <= '0;
            victim_line_saved <= '0;
        end else if (state == MISS_IDLE && next_state == MISS_CHECK_DIRTY) begin
            victim_dirty_saved <= victim_dirty;
            victim_tag_saved <= victim_tag;
            victim_line_saved <= victim_line;
        end
    end

endmodule : miss_fsm
