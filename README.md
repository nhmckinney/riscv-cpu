# RISC-V CPU

5-stage pipelined RISC-V processor with integrated L1 cache. Building toward a full SoC on Basys3 Artix-7.

## Status

- Project bootstrap (architecture planning done)
- Module headers created: `instruction_decoder`, `alu`, `register_file`, `pipeline_controller`
- RTL implementation in progress (Phase 1: datapath)

## What's in Here

**RTL modules** (`src/`):
- `riscv_pkg.sv` — params and instruction encodings (RV32I base ISA)
- `instruction_decoder.sv` — combinational instruction decoder (opcode, funct3/7, immediates, control signals)
- `alu.sv` — arithmetic/logic unit (ADD, SUB, AND, OR, XOR, SLT, shifts)
- `register_file.sv` — 32 x 32-bit register file (async read, sync write)
- `pipeline_controller.sv` — control FSM (fetch → decode → execute → memory → writeback, stalls, flushes)
- `riscv_core.sv` — top-level 5-stage pipeline (coming soon)

**Integration**:
- `cache_controller.sv` (from `https://github.com/nhmckinney/cache-project`)
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
