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
    // sto 0x0000
    2: data <= 16'h4800;
    3: data <= 16'h0000;
    // lda #0x0000
    4: data <= 16'h8000;
    5: data <= 16'h0000;
    // sto 0x00b
    6: data <= 16'h400b;
    // cal 0x200d
    7: data <= 16'h2800;
    8: data <= 16'h200d;
    // cal 0x2014
    9: data <= 16'h2800;
    10: data <= 16'h2014;
    // jmp 0x2007
    11: data <= 16'hf800;
    12: data <= 16'h2007;
    // lda 0x00b
    13: data <= 16'h800b;
    // neq #0x0001
    14: data <= 16'hd000;
    15: data <= 16'h0001;
    // sto 0x00b
    16: data <= 16'h400b;
    // sto 0x4008
    17: data <= 16'h4800;
    18: data <= 16'h4008;
    // rtn
    19: data <= 16'h3000;
    // lda #0x0000
    20: data <= 16'h8000;
    21: data <= 16'h0000;
    // sto 0x00a
    22: data <= 16'h400a;
    // nop
    23: data <= 16'hf000;
    // icz 0x00a, 0x2017
    24: data <= 16'h700a;
    25: data <= 16'h2017;
    // rtn
    26: data <= 16'h3000;
    default: data <= 0;
  endcase
end

endmodule

