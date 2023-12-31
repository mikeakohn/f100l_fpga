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
org = 0
in_data = False

fp = open(sys.argv[1], "r")

for line in fp:
  if line.startswith(".org"):
    line = line.replace(".org", "").strip()
    address = int(line, 0)
    org = address
    continue

  if line.startswith("data sections:"):
    in_data = True

  if in_data:
    if not line.startswith("2"): continue
    data = line.split(":")[1]
    data = data[:48].strip()
    tokens = data.split()
    print("    // data " + str(tokens))
    for i in range(0, len(tokens), 2):
      data = tokens[i + 1] + tokens[i + 0]
      print(indent + str(address - org) + ": data <= 16'h" + data + ";")
      address += 1
    continue

  if not line.startswith("0x2"): continue
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

  print(indent + str(address - org) + ": data <= 16'h" + opcode + ";")
  address += 1

fp.close()

print("    default: data <= 0;")
print("  endcase")
print("end\n")

print("endmodule\n")

