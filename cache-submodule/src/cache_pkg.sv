
// Shared parameters and typedefs 

package cache_pkg;

    parameter int ADDR_WIDTH   = 32;
    parameter int DATA_WIDTH   = 32;
    parameter int LINE_SIZE    = 16;   // bytes per cache line
    parameter int NUM_SETS     = 16;
    parameter int WAYS         = 2;    // set-associativity
    parameter int MEM_LATENCY  = 4;    // mem_if response latency, in cycles

    

    // Derived address breakdown widths.
    // addr = { tag | index | line_offset }
    
    parameter int OFFSET_WIDTH = $clog2(LINE_SIZE);
    parameter int INDEX_WIDTH  = $clog2(NUM_SETS);
    parameter int TAG_WIDTH    = ADDR_WIDTH - INDEX_WIDTH - OFFSET_WIDTH;
    parameter int WAY_WIDTH    = (WAYS > 1) ? $clog2(WAYS) : 1;

    
    typedef logic [ADDR_WIDTH-1:0]        addr_t;
    typedef logic [DATA_WIDTH-1:0]        data_t;
    typedef logic [TAG_WIDTH-1:0]         tag_t;
    typedef logic [INDEX_WIDTH-1:0]       index_t;
    typedef logic [OFFSET_WIDTH-1:0]      offset_t;
    typedef logic [WAY_WIDTH-1:0]         way_t;
    typedef logic [(LINE_SIZE*8)-1:0]     line_data_t; // full cache line

    // Decoded address bundle, passed between controller and sub-blocks
    typedef struct packed {
        tag_t    tag;
        index_t  index;
        offset_t offset;
    } addr_fields_t;

    // Per-way metadata stored in tag_array
    typedef struct packed {
        logic   valid;
        logic   dirty;
        tag_t   tag;
    } tag_entry_t;

    // Request type driven into cache_controller
    typedef enum logic [1:0] {
        REQ_NONE  = 2'b00,
        REQ_READ  = 2'b01,
        REQ_WRITE = 2'b10
    } req_kind_e;

    // mem_if transaction type
    typedef enum logic {
        MEM_READ  = 1'b0,
        MEM_WRITE = 1'b1
    } mem_op_e;

endpackage : cache_pkg
