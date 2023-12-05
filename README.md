# f100l_fpga

Implentation of the Ferranti F100-L CPU in an FPGA using Verilog.

Website:

https://www.mikekohn.net/micro/f100_l_fpga.php

Code is based on the Intel 8008 project:

https://www.mikekohn.net/micro/intel_8008_fpga.php

Features
========

IO, Button input, speaker tone generator, SPI, and Mandelbrot acceleration.

Issues
======

Right now, the shift.d instructions using A is probably not doing
what docs say it should do. Not sure how that one is supposed to work.

This should be easy to fix if someone can give me an explanation on
what it's supposed to do.

The cal #<address> form also hasn't been tested. Not sure I quite
understand what that is supposed to be.

Registers
=========

The only registers in this CPU are:

    A  accumulator
    CR condition register
    PC program counter (not accessible)

The chip stores the address of the stack pointer in RAM location 0 and
during call / return instructions will load the stack pointer to know
where to save / restore PC and CR, afterwords modifying the stack pointer in
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

For the lda [20]+, if memory location 20 has the value 0x8000, the 0x8000
is pre-incremented. The data at location 0x8001 will be loaded into the
accumulator. Memory location 20 will then be updated with the value 0x8001.

For the lda[20]-, if memory location 20 has the value 0x8001, the accumulator
will be loaded with the value contained at location 0x8001 and location 20
will be updated with the value 0x8000 (post-decremented).

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

Both the F and I flags are not used by this Verilog design.

Instructions
============

The first four bits of every opcode give information on how to
decode.

ALU
---

Instructions whose first 4 bits are not 0 mostly take the same bit
encoding and are mostly ALU:

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

    clr #<bit>, A
    clr #<bit>, CR
    clr #<bit>, <long address>
    set #<bit>, A
    set #<bit>, CR
    set #<bit>, <long address>

Examples:

    clr #4, a
    set #5, cr
    set c, cr
    clr z, cr

Shifts
------

There are 4 shift instructions:

    sla, sra, sll, srl

The instructions are shift left / right with both logical / arithmetic
versions.

    sla #<bit>, A
    sla #<bit>, CR
    sla #<bit>, <address>
    sra #<bit>, A
    sra #<bit>, CR
    sra #<bit>, <address>
    sll #<bit>, A
    sll #<bit>, CR
    sll #<bit>, <address>
    srl #<bit>, A
    srl #<bit>, CR
    srl #<bit>, <address>

There are also single bit rotation instructions (sle / sre):

    sle #<bit>, A
    sle #<bit>, CR
    sle #<bit>, <address>
    sre #<bit>, A
    sre #<bit>, CR
    sre #<bit>, <address>

Branches
--------

Jump if bit is clear:

    jbc #<bit>, A, <address>
    jbc #<bit>, CR, <address>
    jbc #<bit>, <address>, <address>

Jump if bit is set:

    jbs #<bit>, A, <address>
    jbs #<bit>, CR, <address>
    jbs #<bit>, <address>, <address>

Jump if bit is clear and set it if the jump happened:

    jcs #<bit>, A, <address>
    jcs #<bit>, CR, <address>
    jcs #<bit>, <address>, <address>

Jump if bit is set and clear it if the jump happened:

    jsc #<bit>, A, <address>
    jsc #<bit>, CR, <address>
    jsc #<bit>, <address>, <address>

To make code a little cleaner, naken_asm implements things like:

    jbs z, A, <address>
    jz <address>
    jnz <address>

Call / Return
-------------

Three instructions are used for calling and returning from functions.

    cal <address>
    cal #address
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

On start-up by default, the chip will load a program from a AT93C86A
2kB EEPROM with a 3-Wire (SPI-like) interface but wll run the code
from the ROM. To start the program loaded to RAM, the program select
button needs to be held down while the chip is resetting.

The peripherals area contain the following:

* 0x4000: input from push button
* 0x4001: SPI TX buffer
* 0x4002: SPI RX buffer
* 0x4003: SPI control: bit 2: 8/16, bit 1: start strobe, bit 0: busy
* 0x4008: ioport_A output (in my test case only 1 pin is connected)
* 0x4009: MIDI note value (60-96) to play a tone on the speaker or 0 to stop
* 0x400a: ioport_B output (3 pins)
* 0x400b: mandelbrot real value
* 0x400c: mandelbrot imaginary value
* 0x400d: mandelbrot control: bit 1: start, bit 0: busy
* 0x400e: mandelbrot result (bottom 4 bits)

IO
--

iport_A is just 1 output in my test circuit to an LED.
iport_B is 3 outputs used in my test circuit for SPI (RES/CS/DC) to the LCD.

MIDI
----

The MIDI note peripheral allows the iceFUN board to play tones at specified
frequencies based on MIDI notes.

SPI
---

The SPI peripheral has 3 memory locations. One location for reading
data after it's received, one location for filling the transmit buffer,
and one location for signaling.

For signaling, setting bit 1 to a 1 will cause whatever is in the TX
buffer to be transmitted. Until the data is fully transmitted, bit 0
will be set to 1 to let the user know the SPI bus is busy.

There is also the ability to do 16 bit transfers by setting bit 2 to 1.

Mandelbrot
----------

This is a special peripheral for computing Z = Z^2 + C on a single
(real, imaginary) coordinate. This is here just to show how using an
FPGA can be beneficial for things. There is an example of how it's
used in the tests/lcd.asm program. It uses a 16 bit fixed point system
in the format of 6.10. One memory address holds the real value, one
holds the imaginary, and one does the signaling. Doing the mandelbrot
in software was taking around 1 minute 10 seconds. Using the Mandelbrot
peripheral it takes around 1 second to calculate.

