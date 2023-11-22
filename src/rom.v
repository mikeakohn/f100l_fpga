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
    // lda #0x0000
    0: data <= 16'h8000;
    1: data <= 16'h0000;
    // sto 0x00a
    2: data <= 16'h400a;
    // neq #0x0001
    3: data <= 16'hd000;
    4: data <= 16'h0001;
    // sto 0x4008
    5: data <= 16'h4800;
    6: data <= 16'h4008;
    // nop
    7: data <= 16'hf000;
    // icz 0x00a, 0x2007
    8: data <= 16'h700a;
    9: data <= 16'h2007;
    // neq #0x0001
    10: data <= 16'hd000;
    11: data <= 16'h0001;
    // sto 0x4008
    12: data <= 16'h4800;
    13: data <= 16'h4008;
    // icz 0x00a, 0x200e
    14: data <= 16'h700a;
    15: data <= 16'h200e;
    // jmp 0x2003
    16: data <= 16'hf800;
    17: data <= 16'h2003;
    default: data <= 0;
  endcase
end

endmodule

