# f100l_fpga

Implentation of F100-L in an FPGA using Verilog.

Code is based on the Intel 8008 project:

https://www.mikekohn.net/micro/intel_8008_fpga.php

All instructions should be implented right now, but this is still a
work in progress. Website and longer documentation coming soon...

Memory Map
----------

This implementation of the F100-L has 4 banks of memory. Each address
contains a 16 bit word instead of 8 bit byte like a typical CPU.

* Bank 0: 0x0000 RAM (1024 words) Implicit BlockRam.
* Bank 1: 0x2000 ROM
* Bank 2: 0x4000 Peripherals
* Bank 3: 0x6000 RAM (1024 words)

