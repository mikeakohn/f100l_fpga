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
    // lda #0x0f01
    0: data <= 16'h8000;
    1: data <= 16'h0f01;
    // sto 0x005
    2: data <= 16'h4005;
    // lda #0x3050
    3: data <= 16'h8000;
    4: data <= 16'h3050;
    // setm
    5: data <= 16'h01e5;
    // sll #8, 0x0005
    6: data <= 16'h0368;
    7: data <= 16'h0005;
    // lda 0x005
    8: data <= 16'h8005;
    // halt
    9: data <= 16'h0400;
    default: data <= 0;
  endcase
end

endmodule

