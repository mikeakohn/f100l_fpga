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
  input bus_enable,
  input write_enable,
  input clk,
  input raw_clk,
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

reg [15:0] ram_data_in;
reg [15:0] peripherals_data_in;
reg [15:0] block_ram_data_in;

reg ram_write_enable;
reg peripherals_write_enable;
reg block_ram_write_enable;

// FIXME: The RAM probably need an enable also.
wire peripherals_enable;
assign peripherals_enable = address[14:13] == 2'b10;

wire block_ram_chip_enable;
assign block_ram_chip_enable = bus_enable & address[14] & address[13];

// Based on the selected bank of memory (address[14:13]) select if
// memory should read from ram.v, rom.v, peripherals.v.
assign data_out = address[14] == 0 ?
  (address[13] == 0 ? ram_data_out         : rom_data_out) :
  (address[13] == 0 ? peripherals_data_out : block_ram_data_out);

// Based on the selected bank of memory, decided which module the
// memory write should be sent to.
always @(posedge clk) begin
  if (write_enable) begin
    case (address[14:13])
      2'b00:
        begin
          ram_data_in <= data_in;

          ram_write_enable <= 1;
          peripherals_write_enable <= 0;
          block_ram_write_enable <= 0;
        end
      2'b01:
        begin
          ram_write_enable <= 0;
          peripherals_write_enable <= 0;
          block_ram_write_enable <= 0;
        end
      2'b10:
        begin
          peripherals_data_in <= data_in;

          ram_write_enable <= 0;
          peripherals_write_enable <= 1;
          block_ram_write_enable <= 0;
        end
      2'b11:
        begin
          block_ram_data_in <= data_in;

          ram_write_enable <= 0;
          peripherals_write_enable <= 0;
          block_ram_write_enable <= 1;
        end
    endcase
  end else begin
    ram_write_enable <= 0;
    peripherals_write_enable <= 0;
    block_ram_write_enable <= 0;
  end
end

rom rom_0(
  .address   (address[9:0]),
  .data_out  (rom_data_out)
);

ram ram_0(
  .address      (address[9:0]),
  .data_in      (ram_data_in),
  .data_out     (ram_data_out),
  .write_enable (ram_write_enable),
  .clk          (raw_clk),
);

peripherals peripherals_0(
  .enable       (peripherals_enable),
  .address      (address[5:0]),
  .data_in      (peripherals_data_in),
  .data_out     (peripherals_data_out),
  .write_enable (peripherals_write_enable),
  .clk          (clk),
  .raw_clk      (raw_clk),
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
  .spi_miso     (spi_miso),
);

ram ram_1(
  .address      (address[9:0]),
  .data_in      (block_ram_data_in),
  .data_out     (block_ram_data_out),
  .write_enable (block_ram_write_enable),
  .clk          (raw_clk),
);

/*
block_ram block_ram_0(
  .address      (address[13:0]),
  .data_in      (block_ram_data_in),
  .data_out     (block_ram_data_out),
  .chip_enable  (block_ram_chip_enable),
  .write_enable (block_ram_write_enable),
  .clk          (clk),
  .double_clk   (double_clk)
);
*/

endmodule

