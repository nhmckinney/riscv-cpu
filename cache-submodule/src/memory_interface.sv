// memory_interface.sv
//
// Backing store model. Fixed MEM_LATENCY-cycle response (start simple;
// a later stretch goal is variable/bursty latency to stress-test
// miss_fsm's stall behavior -- keep that as a parameterizable mode,
// not a rewrite, when you get there).
//
// Single outstanding request at a time to start; miss_fsm should not
// issue a new request before req_done is seen for the previous one.

import cache_pkg::*;

module memory_interface #(
    parameter int MEM_SIZE_LINES = 4096  // backing store depth, in lines
) (
    input  logic                  clk,
    input  logic                  rst_n,

    // Request
    input  logic                  req_valid,
    input  mem_op_e                req_op,
    input  addr_t                  req_addr,      // line-aligned
    input  line_data_t            req_wdata,     // valid for MEM_WRITE

    // Response
    output logic                  req_done,      // pulses when latency elapses
    output line_data_t            rd_line        // valid for MEM_READ on req_done
);

endmodule : memory_interface
