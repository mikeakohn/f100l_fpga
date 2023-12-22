// Ferrati F100-L FPGA Soft Processor
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2023 by Michael Kohn

// The purpose of this module is to route reads and writes to the 4
// different memory banks. Originally the idea was to have ROM and RAM
// be SPI EEPROM (this may be changed in the future) so there would also
// need a "ready" signal that would pause the CPU until the data can be
// clocked in and out of of the SPI chips.

module memory_bus
(
  input  [15:0] address,
  input  [15:0] data_in,
  output [15:0] data_out,
  output [7:0] debug,
  input bus_enable,
  input write_enable,
  input clk,
  input raw_clk,
  output [3:0] servos,
  output speaker_p,
  output speaker_m,
  output ioport_0,
  output ioport_1,
  output ioport_2,
  output ioport_3,
  input  button_0,
  input  reset,
  output spi_clk,
  output spi_mosi,
  input  spi_miso
);

wire [15:0] rom_data_out;
wire [15:0] ram_data_out;
wire [15:0] peripherals_data_out;
wire [15:0] block_ram_data_out;

/*
wire [15:0] ram_0_data_in;
wire [15:0] peripherals_data_in;
wire [15:0] ram_1_data_in;
*/

wire ram_write_enable;
wire peripherals_write_enable;
wire block_ram_write_enable;

assign ram_write_enable = (address[14:13] == 2'b00) && write_enable;
assign peripherals_write_enable = (address[14:13] == 2'b10) && write_enable;
assign block_ram_write_enable = (address[14:13] == 2'b11) && write_enable;

// FIXME: The RAM probably need an enable also.
wire peripherals_enable;
assign peripherals_enable = (address[14:13] == 2'b10) && bus_enable;

// Based on the selected bank of memory (address[14:13]) select if
// memory should read from ram.v, rom.v, peripherals.v.
assign data_out = address[14] == 0 ?
  (address[13] == 0 ? ram_data_out         : rom_data_out) :
  (address[13] == 0 ? peripherals_data_out : block_ram_data_out);

rom rom_0(
  .address   (address[9:0]),
  .data_out  (rom_data_out)
);

ram ram_0(
  .address      (address[9:0]),
  //.data_in      (ram_0_data_in),
  .data_in      (data_in),
  .data_out     (ram_data_out),
  .write_enable (ram_write_enable),
  .clk          (raw_clk)
);

peripherals peripherals_0(
  .enable       (peripherals_enable),
  .address      (address[5:0]),
  //.data_in      (peripherals_data_in),
  .data_in      (data_in),
  .data_out     (peripherals_data_out),
  .debug        (debug),
  .write_enable (peripherals_write_enable),
  .clk          (clk),
  .raw_clk      (raw_clk),
  .servos       (servos),
  .speaker_p    (speaker_p),
  .speaker_m    (speaker_m),
  .ioport_0     (ioport_0),
  .ioport_1     (ioport_1),
  .ioport_2     (ioport_2),
  .ioport_3     (ioport_3),
  .button_0     (button_0),
  .reset        (reset),
  .spi_clk      (spi_clk),
  .spi_mosi     (spi_mosi),
  .spi_miso     (spi_miso)
);

ram ram_1(
  .address      (address[9:0]),
  //.data_in      (ram_1_data_in),
  .data_in      (data_in),
  .data_out     (block_ram_data_out),
  .write_enable (block_ram_write_enable),
  .clk          (raw_clk)
);

endmodule

