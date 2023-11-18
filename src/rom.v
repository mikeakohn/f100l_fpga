// Ferrati F100-L FPGA Soft Processor
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2023 by Michael Kohn

// This is a hardcoded program that blinks an external LED.

module rom
(
  input  [9:0] address,
  output [15:0] data_out
);

reg [15:0] data;
assign data_out = data;

always @(address) begin
  case (address)
    // lda #0x0015
    0: data <= 16'h8000;
    1: data <= 16'h0015;
    // cmp #0x0014
    2: data <= 16'hb000;
    3: data <= 16'h0014;
    // jbs z, cr, 0x2009
    4: data <= 16'h0191;
    5: data <= 16'h2009;
    // lda #0x0100
    6: data <= 16'h8000;
    7: data <= 16'h0100;
    // halt
    8: data <= 16'h0400;
    // lda #0x0080
    9: data <= 16'h8000;
    10: data <= 16'h0080;
    // halt
    11: data <= 16'h0400;
    default: data <= 0;
  endcase
end

endmodule

