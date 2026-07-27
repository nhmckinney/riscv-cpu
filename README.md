# RISC-V CPU

5-stage pipelined RISC-V processor with integrated L1 cache. Building toward a full SoC on Basys3 Artix-7.

## Status

- Project bootstrap (architecture planning)
- Integrated cache controller from `cache-project`
- RTL implementation in progress

## What's in Here

**RTL modules** (`src/`):
- `riscv_core.sv` — 5-stage pipeline (fetch, decode, execute, memory, writeback)
- `alu.sv` — arithmetic/logic unit
- `register_file.sv` — 32 registers (x0-x31)
- `control_unit.sv` — instruction decoding and pipeline control
- `riscv_pkg.sv` — params and instruction encodings (RV32I base ISA)

**Integration**:
- `cache_controller.sv` (from `../cache-project/src/`)
- Memory interface connecting CPU to L1 cache

**Testing**:
- `tb/riscv_tb.sv` — instruction execution tests
- `tb/integration_tb.sv` — CPU + cache integration tests

## Quick Start

1. Architecture review: See futurePlans.md for pipeline design and test strategy
2. Implement ALU and control unit first (data path)
3. Build pipeline stages incrementally
4. Integrate L1 cache into memory stage

## Next Steps

See `futurePlans.md` for implementation roadmap (local-only planning doc).
