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
    // lda #0x00ff
    0: data <= 16'h8000;
    1: data <= 16'h00ff;
    // sto long 0x0000
    2: data <= 16'h4800;
    3: data <= 16'h0000;
    // lda #0x0021
    4: data <= 16'h8000;
    5: data <= 16'h0021;
    // sto 0x005
    6: data <= 16'h4005;
    // lda #0x0035
    7: data <= 16'h8000;
    8: data <= 16'h0035;
    // sto 0x006
    9: data <= 16'h4006;
    // set f, cr
    10: data <= 16'h01e6;
    // cal long 0x2010
    11: data <= 16'h2800;
    12: data <= 16'h2010;
    // setm
    13: data <= 16'h01e5;
    // sle #0, cr
    14: data <= 16'h0170;
    // halt
    15: data <= 16'h0400;
    // clr f, cr
    16: data <= 16'h01f6;
    // lda 0x006
    17: data <= 16'h8006;
    // ads 0x005
    18: data <= 16'h5005;
    // lda 0x101
    19: data <= 16'h8101;
    // rtn
    20: data <= 16'h3000;
    default: data <= 0;
  endcase
end

endmodule

