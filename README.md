# RV32I FPGA CPU

5-stage pipelined RISC-V processor with integrated L1 cache on Basys3 Artix-7.

## Architecture

- **Pipeline**: Fetch → Decode → Execute → Memory → Writeback
- **ISA**: RV32I (11 opcodes, all immediate formats)
- **Hazards**: Load-use stalls, branch flushing
- **Cache**: Integrated 2-way set-associative L1 (from cache-project)

## Implementation Status

- ✅ Instruction decoder (all RV32I opcodes, immediate extraction)
- ✅ ALU (10 operations)
- ✅ Execute stage (branch evaluation, pipeline register)
- ✅ Writeback stage (result muxing to register file)
- ⏳ Memory stage (cache interface, load width extraction)
- ⏳ Pipeline controller (hazard detection, stall logic)

