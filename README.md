# RV32I FPGA CPU

A five-stage RISC-V CPU prototype in SystemVerilog with forwarding and
load-use stalls. The FPGA demo targets the Boolean Board.

## Synthesize

Run from the repository root with Vivado installed:

```sh
vivado -mode batch -source scripts/synth_boolean_board.tcl
```
