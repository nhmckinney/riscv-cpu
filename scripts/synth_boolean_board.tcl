# Run from any directory with: vivado -mode batch -source scripts/synth_boolean_board.tcl
set repo_dir [file normalize [file join [file dirname [info script]] ..]]
set output_dir [file join $repo_dir build boolean_board]
file mkdir $output_dir

# The package must be first in the SystemVerilog source list.
set sources [list [file join $repo_dir src riscv_pkg.sv]]
foreach source [lsort [glob [file join $repo_dir src *.sv]]] {
  if {[file tail $source] ne "riscv_pkg.sv"} {
    lappend sources $source
  }
}
read_verilog -sv $sources
read_xdc [file join $repo_dir constraints boolean_board.xdc]

synth_design -top boolean_board_top -part xc7s50csga324-1
report_utilization -file [file join $output_dir utilization.rpt]
report_timing_summary -file [file join $output_dir synthesis_timing.rpt]
write_checkpoint -force [file join $output_dir synthesized.dcp]
