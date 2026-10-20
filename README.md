# RV32I CPU RTL

Five-stage RISC-V CPU prototype in SystemVerilog, with fetch, decode, execute, memory, and writeback modules. The repository also contains hazard/branch control, a Basys3-facing wrapper and constraints, and a separate L1 cache design.

## Current status

| Area | Status |
| --- | --- |
| Core pipeline | Stage modules are connected in `src/riscv_core.sv`. |
| Hazard and branch control | `src/pipeline_controller.sv` implements stalls and flushes; needs more tests. |
| Memory and cache integration are in the works |
