# RV32I CPU RTL

Five-stage RISC-V CPU prototype in SystemVerilog, with fetch, decode, execute, memory, and writeback modules. The repository also contains hazard/branch control, a Basys3-facing wrapper and constraints, and a separate L1 cache design.

## Current status

| Area | Status |
| --- | --- |
| Core pipeline | Stage modules are connected in `src/riscv_core.sv`. |
| Hazard and branch control | `src/pipeline_controller.sv` implements stalls and flushes; broader behavior needs more tests. |
| Data memory | The core currently instantiates `src/simple_data_mem.sv`. |
| L1 cache | RTL is present in `cache-submodule/`, but it is not connected to `riscv_core` yet. |
| End-to-end verification | The Icarus smoke test checks a short ADD program and confirms `x3 = 8`. |

The decoder and ALU contain RV32I logic, but this smoke test does not establish full ISA compliance, cache miss handling, or FPGA timing closure.

## Run the CPU smoke test

Install Icarus Verilog, then run from the repository root:

```sh
iverilog -g2012 -s cpu_top_tb -o cpu_top_tb.vvp src/riscv_pkg.sv src/alu.sv src/instruction_decoder.sv src/register_file.sv src/instr_mem.sv src/fetch_stage.sv src/decode_stage.sv src/execute_stage.sv src/simple_data_mem.sv src/memory_stage.sv src/writeback_stage.sv src/pipeline_controller.sv src/riscv_core.sv src/cpu_top.sv sim/cpu_top_tb.sv
vvp cpu_top_tb.vvp
```

`sim/cpu_top_tb.sv` runs `addi x1, x0, 5`, `addi x2, x0, 3`, and `add x3, x1, x2`. The current test ends with `TEST PASSED: x3 = 8 (expected result)`. Icarus may print constant-select sensitivity warnings during compilation.

## Repository map

- `src/`: CPU stages, decoder, register file, memory, and controller.
- `sim/`: ADD smoke test and example assembly.
- `cache-submodule/`: separate two-way set-associative cache RTL and its own testbench. See also the [cache project](https://github.com/nhmckinney/cache-project).
- `constraints/`: Basys3 pin constraints.

## Next steps

Connect the L1 cache to the core memory stage, expand self-checking programs for loads, stores, branches, and hazards, and validate synthesis and timing on the target FPGA.
