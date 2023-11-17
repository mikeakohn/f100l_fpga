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
    // nop
    2: data <= 16'hf000;
    // jcs 0, a, 0x2007
    3: data <= 16'h00a0;
    4: data <= 16'h2007;
    // set 15, A
    5: data <= 16'h00ef;
    // halt
    6: data <= 16'h0400;
    // set 14, A
    7: data <= 16'h00ee;
    // halt
    8: data <= 16'h0400;
    // set 13, A
    9: data <= 16'h00ed;
    // halt
    10: data <= 16'h0400;
    default: data <= 0;
  endcase
end

endmodule

