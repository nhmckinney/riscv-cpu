# Cache Project

L1 cache implementation (2-way set-associative). Currently working on getting it to synthesize on a Basys3.

## Status

- Core RTL done (tag/data arrays, hit/miss detection, miss FSM)
- Basys3 constraints and test counter module
- Next: validate synthesis, integrate cache to hardware

## What's in Here

**RTL modules** (`src/`):
- `cache_controller.sv` — main logic
- `tag_array.sv`, `data_array.sv` — storage
- `tag_compare.sv`, `replacement_policy.sv`, `miss_fsm.sv` — cache operations
- `cache_pkg.sv` — params (16 sets, 2 ways, 32-bit words)

**Basys3 stuff**:
- `basys3.xdc` — pin constraints for Artix-7
- `basys3_top.sv` — simple counter test (LEDs + 7-seg display)

**Testing**:
- `tb/cache_tb.sv` — comprehensive testbench (requires Verilator; Icarus Verilog doesn't support advanced SystemVerilog features used here)

## Quick Start

To synthesize the test counter on Basys3:
1. Create Vivado project (Artix-7, XC7A35T)
2. Add files from `src/` and `basys3.xdc` constraint
3. Set top module to `basys3_top`
4. Synthesize → implement → generate bitstream
5. Program and watch the counter increment on LEDs/7-seg

## Next Steps

See `futurePlans.md` for the roadmap (clock domain crossing, performance stuff, etc.)
