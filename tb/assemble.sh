#!/bin/bash

# Assemble RISC-V assembly to machine code hex dump
# Usage: ./assemble.sh add_test.s

if [ -z "$1" ]; then
  echo "Usage: $0 <assembly_file>"
  exit 1
fi

ASM_FILE="$1"
OBJ_FILE="${ASM_FILE%.s}.o"
BIN_FILE="${ASM_FILE%.s}.bin"
HEX_FILE="${ASM_FILE%.s}.hex"

echo "Assembling $ASM_FILE..."
riscv64-unknown-elf-as "$ASM_FILE" -o "$OBJ_FILE"

echo "Converting to binary..."
riscv64-unknown-elf-objcopy -O binary "$OBJ_FILE" "$BIN_FILE"

echo "Generating hex dump..."
hexdump -C "$BIN_FILE" > "$HEX_FILE"

echo "Done:"
echo "  Binary: $BIN_FILE"
echo "  Hex:    $HEX_FILE"
echo ""
echo "Hex dump:"
cat "$HEX_FILE"
