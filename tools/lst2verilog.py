#!/usr/bin/env python3

import sys

print("// Ferrati F100-L FPGA Soft Processor")
print("//  Author: Michael Kohn")
print("//   Email: mike@mikekohn.net")
print("//     Web: https://www.mikekohn.net/")
print("//   Board: iceFUN iCE40 HX8K")
print("// License: MIT")
print("//")
print("// Copyright 2023 by Michael Kohn\n")

print("// This is a hardcoded program that blinks an external LED.\n")

print("module rom")
print("(")
print("  input  [9:0] address,")
print("  output [15:0] data_out")
print(");\n")

print("reg [15:0] data;")
print("assign data_out = data;\n")

print("always @(address) begin")
print("  case (address)")

indent = "    "
address = 0

fp = open(sys.argv[1], "r")

for line in fp:
  if not line.startswith("0x0"): continue
  line = line.strip()
  data = line[:12].strip()
  instruction = line[12:].strip()

  (a, opcode) = data.split(": ")

  a = int(a, 16)

  if address != a:
    print("Error: Address " + str(address) + " does not equal " + str(a))
    sys.exit(1)

  if instruction != "":
    print(indent + "// " + instruction)

  print(indent + str(address) + ": data <= 16'h" + opcode + ";")
  address += 1

fp.close()

print("    default: data <= 0;")
print("  endcase")
print("end\n")

print("endmodule\n")

