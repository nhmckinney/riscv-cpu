// cache_controller.sv
//
// Top-level cache datapath + control. Instantiates tag_array,
// data_array, tag_compare, replacement_policy, and miss_fsm; wires
// them together and exposes a simple request/response interface.
//
// Request/response protocol: single-request-at-a-time to start
// (req_valid/req_ready handshake in, resp_valid pulses out with
// hit/miss status). Pipelining multiple outstanding requests is a
// reasonable stretch goal once this works, not part of the initial
// bring-up.

import cache_pkg::*;

module cache_controller (
    input  logic                  clk,
    input  logic                  rst_n,

    // Request in
    input  logic                  req_valid,
    output logic                  req_ready,
    input  addr_t                 req_addr,
    input  req_kind_e             req_kind,      // REQ_READ / REQ_WRITE
    input  data_t                 req_wdata,     // valid for REQ_WRITE

    // Response out
    output logic                  resp_valid,
    output data_t                 resp_rdata,    // valid for REQ_READ
    output logic                  resp_hit,      // instrumentation: was it a hit

    // main memory connection
    output logic                  mem_req_valid,
    output mem_op_e                mem_req_op,
    output addr_t                  mem_req_addr,
    output line_data_t             mem_req_wdata,
    input  logic                   mem_req_done,
    input  line_data_t             mem_rd_line,

    // Instrumentation (for hit-rate / latency reporting in the testbench
    // or on-board via LEDs/UART)
    output logic                  instr_access_valid, // pulses per completed request
    output logic                  instr_hit,
    output logic [31:0]           instr_cycle_count    // free-running cycle counter
);

    // Decode incoming address
    addr_fields_t req_addr_fields;
    assign req_addr_fields.tag    = req_addr[ADDR_WIDTH-1 : INDEX_WIDTH + OFFSET_WIDTH];
    assign req_addr_fields.index  = req_addr[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH];
    assign req_addr_fields.offset = req_addr[OFFSET_WIDTH - 1 : 0];

    // Tag array
    tag_entry_t tag_entries [WAYS];
    tag_array tag_store (
        .clk(clk),
        .rst_n(rst_n),
        .rd_index(req_addr_fields.index),
        .rd_entries(tag_entries),
        .wr_en(tag_wr_en),
        .wr_index(tag_wr_index),
        .wr_way(tag_wr_way),
        .wr_entry(tag_wr_entry)
    );

    // Data array
    line_data_t data_rd_line, data_wr_line;
    data_array data_store (
        .clk(clk),
        .rst_n(rst_n),
        .rd_index(req_addr_fields.index),
        .rd_way(hit_way),
        .rd_line(data_rd_line),
        .wr_en(data_wr_en),
        .wr_index(data_wr_index),
        .wr_way(data_wr_way),
        .wr_line(data_wr_line),
        .wr_word_en(data_wr_word_en),
        .wr_word_index(data_wr_word_index),
        .wr_word_way(data_wr_word_way),
        .wr_word_offset(data_wr_word_offset),
        .wr_word_data(data_wr_word_data)
    );

    // Tag compare for hit/miss detection
    logic hit;
    way_t hit_way, victim_way;
    logic victim_dirty;
    tag_t victim_tag;
    tag_compare tag_cmp (
        .req_tag(req_addr_fields.tag),
        .set_entries(tag_entries),
        .hit(hit),
        .hit_way(hit_way),
        .victim_way(victim_way),
        .victim_dirty(victim_dirty),
        .victim_tag(victim_tag)
    );

    // Replacement policy
    replacement_policy lru (
        .clk(clk),
        .rst_n(rst_n),
        .touch_en(touch_en),
        .touch_index(touch_index),
        .touch_way(touch_way),
        .victim_index(req_addr_fields.index),
        .victim_way(victim_way)
    );

    // Miss handler
    logic tag_wr_en, data_wr_en, data_wr_word_en;
    index_t tag_wr_index, data_wr_index, data_wr_word_index;
    way_t tag_wr_way, data_wr_way, data_wr_word_way;
    tag_entry_t tag_wr_entry;
    offset_t data_wr_word_offset;
    data_t data_wr_word_data;
    logic touch_en;
    index_t touch_index;
    way_t touch_way;
    logic miss_fsm_busy;

    miss_fsm miss_handler (
        .clk(clk),
        .rst_n(rst_n),
        .miss_valid(req_valid && !hit && req_ready),
        .miss_addr(req_addr_fields),
        .miss_kind(req_kind),
        .miss_wdata(req_wdata),
        .miss_wr_offset(req_addr_fields.offset),
        .victim_way(victim_way),
        .victim_dirty(victim_dirty),
        .victim_tag(victim_tag),
        .victim_line(data_rd_line),
        .mem_req_valid(mem_req_valid),
        .mem_req_op(mem_req_op),
        .mem_req_addr(mem_req_addr),
        .mem_req_wdata(mem_req_wdata),
        .mem_req_done(mem_req_done),
        .mem_rd_line(mem_rd_line),
        .fill_wr_en(tag_wr_en),
        .fill_tag_entry(tag_wr_entry),
        .fill_line(data_wr_line),
        .fill_touch_en(touch_en),
        .busy(miss_fsm_busy),
        .done()
    );

    // Control logic
    assign req_ready = !miss_fsm_busy;

    // On hit: extract word from cached line
    data_t hit_word;
    assign hit_word = data_rd_line[(req_addr_fields.offset * DATA_WIDTH) +: DATA_WIDTH];

    // Response path
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            resp_valid <= 1'b0;
            resp_rdata <= '0;
            resp_hit <= 1'b0;
        end else begin
            if (req_valid && req_ready) begin
                resp_valid <= 1'b1;
                resp_hit <= hit;
                if (hit) begin
                    if (req_kind == REQ_READ) begin
                        resp_rdata <= hit_word;
                    end
                    // Write hits handled by miss_fsm (or future write-back logic)
                end
            end else begin
                resp_valid <= 1'b0;
            end
        end
    end

    // Instrumentation
    logic [31:0] cycle_counter;
    assign instr_cycle_count = cycle_counter;
    assign instr_access_valid = resp_valid;
    assign instr_hit = resp_hit;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_counter <= '0;
        end else begin
            cycle_counter <= cycle_counter + 1;
        end
    end

endmodule : cache_controller
