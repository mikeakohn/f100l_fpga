// Ferrati F100-L FPGA Soft Processor
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2022-2023 by Michael Kohn

// Page 4 of MemoryUsageGuideforiCE40Devices.pdf from Lattice has a timing
// diagram of how BlockRam should work. This was a struggle to get working.
// The timing diagram seems to imply a state machine is needed. That said,
// the Verilog compilers can infer that the code wants to use BlockRam by
// some pretty straight forward code (probably rom.v and it seems like
// ram.v too, but ram.v doesn't seem to do it, maybe because clk is on
// the sensitivy list and not write_enable?).. not sure how that could
// possibly do a state machine. Anyway, it seems to work here without
// the state machine, probably because the BlockRam clock is at least
// double the speed of the main clock. Also, it seems the RE / WE signals
// need to be reverse to work. It didn't work until I put ~ on them.
//
// Note: This appears to be glitchy.

module block_ram
(
  input  [13:0] address,
  input  [15:0] data_in,
  output [15:0] data_out,
  input chip_enable,
  input write_enable,
  input clk,
  input double_clk
);

reg [15:0] data;
wire [15:0] data_read;

assign data_out = data[15:0];

//reg state[2:0];

wire re;
wire we;

assign we = chip_enable &  write_enable;
assign re = chip_enable & ~write_enable;

reg [1:0] state = 0;

always @(posedge double_clk) begin
  if (chip_enable) begin
    data <= data_read;
  end
end

SB_RAM40_4K #(
  .INIT_0(256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff),
  .INIT_1(256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff),
  .INIT_2(256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff),
  .INIT_3(256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff),
  .INIT_4(256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff),
  .INIT_5(256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff),
  .INIT_6(256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff),
  .INIT_7(256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff),
  .INIT_8(256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff),
  .INIT_9(256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff),
  .INIT_A(256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff),
  .INIT_B(256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff),
  .INIT_C(256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff),
  .INIT_D(256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff),
  .INIT_E(256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff),
  .INIT_F(256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff),
  .READ_MODE(0),
  .WRITE_MODE(0)
) ram00 (
  .WADDR (address[10:0]),
  .WDATA (data_in),
  .WE    (~we),
  .WCLKE (1'b1),
  .WCLK  (double_clk),
  .MASK  (16'h0000),
  .RADDR (address[10:0]),
  .RDATA (data_read),
  .RE    (~re),
  .RCLKE (1'b1),
  .RCLK  (double_clk)
);

endmodule

