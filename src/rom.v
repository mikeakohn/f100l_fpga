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
    // lda #0x0019
    0: data <= 16'h8000;
    1: data <= 16'h0019;
    // sto 0x001
    2: data <= 16'h4001;
    // lda #0x0020
    3: data <= 16'h8000;
    4: data <= 16'h0020;
    // ads 0x001
    5: data <= 16'h5001;
    // lda 0x001
    6: data <= 16'h8001;
    // halt
    7: data <= 16'h0400;
    default: data <= 0;
  endcase
end

endmodule

