# Simple program: add two numbers
# x1 = 5
# x2 = 3
# x3 = x1 + x2 (result: 8)

  .section .text
  .globl _start

_start:
  addi x1, x0, 5      # x1 = 5
  addi x2, x0, 3      # x2 = 3
  add x3, x1, x2      # x3 = x1 + x2 = 8

  # Infinite loop (halt)
  beq x0, x0, .       # branch to self
