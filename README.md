# f100l_fpga

Implentation of the Ferranti F100-L CPU in an FPGA using Verilog.

Code is based on the Intel 8008 project:

https://www.mikekohn.net/micro/intel_8008_fpga.php

All instructions should be implented right now, but this is still a
work in progress. Website and longer documentation coming soon...

Differences
===========

Right now, unsure if the shift.d instructions work properly if the
operand is the accumulator.

Registers
=========

The only registers in this CPU are:

    A  accumulator
    CR condition register
    PC program counter (not accessible)

The chip stores the address of the stack pointer in RAM location 0 and
during call / return instructions will load the stack pointer to know
where to save / restore PC, afterwords modifying the stack pointer in
location 0 with the new value.

Addressing Modes
================

The F100-L has several addressing modes, not available on all instructions.
The naken_asm assembler uses the following syntax:

    #value       (immediate)
    address      (11 bit)
    long address (15 bit)
    [address]    (8 bit address)
    [address]+   (8 bit address, pre-increment)
    [address]-   (8 bit address, post-decrement)

The original syntax was (which can still be used with naken_asm to
assemble) is:

    ,value     (immediate)
    address    (11 bit short)
    .address   (15 bit)
    /address   (8 bit address)
    /address+  (8 bit address, pre-increment)
    /address-  (8 bit address, post-decrement)

Some examples:

    lda #0x1234 (load accumulator with 0x1234)
    add 10      (add accumulator with value in location 10)
    lda [20]    (load ea from loc 20, load accum from value from address ea)
    lda [20]+   (load ea from loc 20, load accum from value from address
                 ea + 1. Store ea + 1 back to location 20).
    lda [20]-   (load ea from loc 20, load accum from value from address
                 ea. Store ea - 1 back to location 20).

Flags
=====

Flags are stored in the CR register which contains the following bits:

    00000000_0FMCSVZI

    F - Fail
    M - Multi length
    C - Carry flag
    S - Sign flag
    V - Overflow flag
    Z - Zero flag
    I - Program Interrupt Lock-out

Instructions
============

The first four bits of every opcode give information on how to
decode.

ALU
---

Instructions whose first 4 bits are not 0 mostly take the same bit
encoding, and are mostly ALU:

    add   0x9000  Add with carry and store to accumulator.
    ads   0x5000  Add with carry and store back to source.
    and   0xc000  Logical AND with accumulator.
    cal   0x2000  Call function ([P]+ or [P]- modes are invalid).
    cmp   0xb000  Same as sub updating flags without saving result.
    icz   0x7000  Increment source and jump if result is 0.
    jmp   0xf000  Jump always (source is loaded directly to PC).
    lda   0x8000  Load accumulator.
    neq   0xd000  XOR accumulator with source.
    sbs   0x6000  Subtract with carry and store back to source.
    sto   0x4000  Store to source.
    sub   0xa000  Subtract with carry and store to accumulator.

Bit Manipulation
----------------

When the instructions first 4 bits are 0 and bits[11:10] are 0, then
these are bit set / clr instructions:

    clr <bit>, A
    clr <bit>, CR
    clr <bit>, <long address>
    set <bit>, A
    set <bit>, CR
    set <bit>, <long address>

Examples:

    clr 4, a
    set 5, cr

Shifts
------

There are 4 shift instructions:

    sla, sra, sll, srl

The instructions are shift left / right with both logical / arithmetic
versions.

    sla <bit>, A
    sla <bit>, CR
    sla <bit>, <address>
    sra <bit>, A
    sra <bit>, CR
    sra <bit>, <address>
    sll <bit>, A
    sll <bit>, CR
    sll <bit>, <address>
    srl <bit>, A
    srl <bit>, CR
    srl <bit>, <address>

There are also single bit rotation instructions (sle / sre):

   sle <bit>, A
   sle <bit>, CR
   sle <bit>, <address>
   sre <bit>, A
   sre <bit>, CR
   sre <bit>, <address>

Branches
--------

Jump if bit is clear:

    jbc <bit>, A, <address>
    jbc <bit>, CR, <address>
    jbc <bit>, <address>, <address>

Jump if bit is set:

    jbs <bit>, A, <address>
    jbs <bit>, CR, <address>
    jbs <bit>, <address>, <address>

Jump if bit is clear and set it if the jump happened:

    jcs <bit>, A, <address>
    jcs <bit>, CR, <address>
    jcs <bit>, <address>, <address>

Jump if bit is set and clear it if the jump happened:

    jsc <bit>, A, <address>
    jsc <bit>, CR, <address>
    jsc <bit>, <address>, <address>

Call / Return
-------------

Three instructions are used for calling and returning from functions.

    cal <address>
    cal #address
    cal long <address>
    cal [address]
    rtn
    rtc

The address to jump to is computed the same way ALU instructions work.
For example cal #address will direcly set the PC to whatever that immediate
value is. The cal [address] will first load a value from the location of
address, and then load the data from that address to be the address to
jump to.

The cal function will:

    Load LSP (stack pointer) value from address location 0.
    Increment LSP and store PC where LSP points to.
    Increment LSP and store CR where LSP points to.
    Store LSP's new value back to address location 0.

The rtn function will:

    Load LSP (stack pointer) value from address location 0.
    Set PC to the value that LSP points to, then decrements LSP.
    Set CR to the value that LSP points to, then decrements LSP.
    Store LSP's new value back to address location 0.

The rtc function will:

    Load LSP (stack pointer) value from address location 0.
    Set PC to the value that LSP points to, then decrements LSP.
    Decrements LSP (discarding the value of CR).
    Store LSP's new value back to address location 0.

Memory Map
==========

This implementation of the F100-L has 4 banks of memory. Each address
contains a 16 bit word instead of 8 bit byte like a typical CPU.

* Bank 0: 0x0000 RAM (1024 words) Implicit BlockRam.
* Bank 1: 0x2000 ROM
* Bank 2: 0x4000 Peripherals
* Bank 3: 0x6000 RAM (1024 words)

